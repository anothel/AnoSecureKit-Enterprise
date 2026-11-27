// SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary
#include "capture.hpp"

#ifndef _WIN32_WINNT
#define _WIN32_WINNT 0x0600
#endif
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>

#include <algorithm>
#include <filesystem>
#include <memory>

namespace verifier_capture {
namespace {

using Clock = std::chrono::steady_clock;
constexpr std::size_t command_line_limit = 32766;
constexpr DWORD pipe_buffer_bytes = 64 * 1024;
constexpr DWORD poll_interval_ms = 5;
constexpr DWORD cleanup_timeout_ms = 1000;

class Handle {
public:
    explicit Handle(HANDLE value = nullptr) : value_(value) {}
    ~Handle() { reset(); }

    Handle(const Handle&) = delete;
    Handle& operator=(const Handle&) = delete;

    HANDLE get() const { return value_; }
    explicit operator bool() const { return value_ && value_ != INVALID_HANDLE_VALUE; }

    void reset(HANDLE value = nullptr) {
        if (*this) {
            CloseHandle(value_);
        }
        value_ = value;
    }

private:
    HANDLE value_;
};

class InheritedHandles {
public:
    ~InheritedHandles() {
        if (list_) {
            DeleteProcThreadAttributeList(list_);
        }
    }

    bool initialize(HANDLE (&handles)[3]) {
        SIZE_T bytes = 0;
        InitializeProcThreadAttributeList(nullptr, 1, 0, &bytes);
        if (bytes == 0) {
            return false;
        }
        storage_ = std::make_unique<unsigned char[]>(bytes);
        const auto list = reinterpret_cast<LPPROC_THREAD_ATTRIBUTE_LIST>(storage_.get());
        if (!InitializeProcThreadAttributeList(list, 1, 0, &bytes)) {
            return false;
        }
        list_ = list;
        return UpdateProcThreadAttribute(list_, 0, PROC_THREAD_ATTRIBUTE_HANDLE_LIST,
                                         handles, sizeof(handles), nullptr, nullptr) != FALSE;
    }

    LPPROC_THREAD_ATTRIBUTE_LIST get() const { return list_; }

private:
    std::unique_ptr<unsigned char[]> storage_;
    LPPROC_THREAD_ATTRIBUTE_LIST list_ = nullptr;
};

Result failure(Status status) {
    Result result;
    result.status = status;
    return result;
}

bool from_utf8(const std::string& value, std::wstring& wide) {
    if (value.empty()) {
        wide.clear();
        return true;
    }
    if (value.size() > 4 * command_line_limit || value.find('\0') != std::string::npos) {
        return false;
    }

    const auto bytes = static_cast<int>(value.size());
    const int characters = MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, value.data(), bytes, nullptr, 0);
    if (characters <= 0 || static_cast<std::size_t>(characters) > command_line_limit) {
        return false;
    }
    wide.resize(static_cast<std::size_t>(characters));
    return MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, value.data(), bytes,
                               wide.data(), characters) == characters;
}

void append_argument(std::wstring& line, const std::wstring& argument) {
    line.append(L" \"");
    std::size_t backslashes = 0;
    for (const wchar_t character : argument) {
        if (character == L'\\') {
            ++backslashes;
            continue;
        }
        // Backslashes escape only a following quote in the Windows C runtime.
        line.append(character == L'"' ? 2 * backslashes + 1 : backslashes, L'\\');
        line.push_back(character);
        backslashes = 0;
    }
    line.append(2 * backslashes, L'\\');
    line.push_back(L'"');
}

bool make_command(const std::vector<std::string>& argv, std::wstring& application, std::wstring& line) {
    if (argv.empty() || !from_utf8(argv.front(), application) ||
        application.find(L'"') != std::wstring::npos || !std::filesystem::path(application).is_absolute()) {
        return false;
    }
    // argv[0] has special C runtime parsing rules and a Windows path cannot contain a quote.
    line = L'"' + application + L'"';
    std::wstring argument;
    for (std::size_t i = 1; i < argv.size(); ++i) {
        if (!from_utf8(argv[i], argument)) {
            return false;
        }
        append_argument(line, argument);
        if (line.size() > command_line_limit) {
            return false;
        }
    }
    return line.size() <= command_line_limit;
}

struct Pipe {
    Handle reader;
    Handle writer;

    bool open() {
        HANDLE read_handle = nullptr;
        HANDLE write_handle = nullptr;
        if (!CreatePipe(&read_handle, &write_handle, nullptr, pipe_buffer_bytes)) {
            return false;
        }
        reader.reset(read_handle);
        writer.reset(write_handle);
        return SetHandleInformation(writer.get(), HANDLE_FLAG_INHERIT, HANDLE_FLAG_INHERIT) != FALSE;
    }
};

Status drain(Pipe& pipe, std::string& captured, std::size_t limit, bool& progress) {
    if (!pipe.reader) {
        return Status::ok;
    }

    DWORD available = 0;
    if (!PeekNamedPipe(pipe.reader.get(), nullptr, 0, nullptr, &available, nullptr)) {
        if (GetLastError() != ERROR_BROKEN_PIPE) {
            return Status::process_error;
        }
        pipe.reader.reset();
        progress = true;
        return Status::ok;
    }
    if (available > limit - captured.size()) {
        return Status::output_limit;
    }
    if (available == 0) {
        return Status::ok;
    }

    // The private pipe has one reader, so these already available bytes can be read synchronously.
    char buffer[8192];
    const DWORD wanted = std::min(available, static_cast<DWORD>(sizeof(buffer)));
    DWORD read = 0;
    if (!ReadFile(pipe.reader.get(), buffer, wanted, &read, nullptr) || read == 0) {
        return Status::process_error;
    }
    captured.append(buffer, read);
    progress = true;
    return Status::ok;
}

bool get_active_processes(HANDLE job, DWORD& active) {
    JOBOBJECT_BASIC_ACCOUNTING_INFORMATION accounting{};
    if (!QueryInformationJobObject(job, JobObjectBasicAccountingInformation, &accounting,
                                   sizeof(accounting), nullptr)) {
        return false;
    }
    active = accounting.ActiveProcesses;
    return true;
}

bool finish_job(HANDLE job) {
    DWORD active = 0;
    if (!get_active_processes(job, active)) {
        return false;
    }
    if (active == 0) {
        return true;
    }
    if (!TerminateJobObject(job, static_cast<UINT>(Status::terminated))) {
        return false;
    }

    const auto deadline = Clock::now() + std::chrono::milliseconds(cleanup_timeout_ms);
    while (get_active_processes(job, active)) {
        if (active == 0) {
            return true;
        }
        if (Clock::now() >= deadline) {
            break;
        }
        Sleep(poll_interval_ms);
    }
    // Closing the last job handle also requests termination if waiting failed.
    return false;
}

Status collect(HANDLE process, Pipe& output, Pipe& error, Clock::time_point deadline,
               std::size_t limit, Result& result) {
    bool exited = false;
    while (!exited || output.reader || error.reader) {
        const auto now = Clock::now();
        if (now >= deadline) {
            return Status::timeout;
        }
        bool progress = false;
        const Status output_status = drain(output, result.output, limit, progress);
        if (output_status != Status::ok) {
            return output_status;
        }
        const Status error_status = drain(error, result.error, limit, progress);
        if (error_status != Status::ok) {
            return error_status;
        }

        DWORD wait_ms = 0;
        if (!progress) {
            const auto remaining = deadline - Clock::now();
            const auto interval = std::chrono::ceil<std::chrono::milliseconds>(remaining);
            wait_ms = static_cast<DWORD>(std::clamp(interval, std::chrono::milliseconds::zero(),
                                                    std::chrono::milliseconds(poll_interval_ms)).count());
        }
        if (exited) {
            if (wait_ms > 0) {
                Sleep(wait_ms);
            }
            continue;
        }
        const DWORD wait = WaitForSingleObject(process, wait_ms);
        if (wait == WAIT_TIMEOUT) {
            continue;
        }
        if (wait != WAIT_OBJECT_0 || !GetExitCodeProcess(process, &result.exit_code)) {
            return Status::process_error;
        }
        // Windows reports common unhandled exceptions and Ctrl-C as NTSTATUS values.
        if (result.exit_code >= 0x80000000UL || result.exit_code == 0x40000015UL) {
            return Status::terminated;
        }
        exited = true;
    }

    return Clock::now() < deadline ? Status::ok : Status::timeout;
}

}  // namespace

Result run(const std::vector<std::string>& argv, Clock::time_point deadline, std::size_t limit) {
    std::wstring application;
    std::wstring line;
    if (!make_command(argv, application, line)) {
        return failure(Status::invalid_arguments);
    }

    Pipe output;
    Pipe error;
    SECURITY_ATTRIBUTES inheritable{sizeof(SECURITY_ATTRIBUTES), nullptr, TRUE};
    const Handle input(CreateFileW(L"NUL", GENERIC_READ, FILE_SHARE_READ | FILE_SHARE_WRITE,
                                   &inheritable, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, nullptr));
    const Handle job(CreateJobObjectW(nullptr, nullptr));
    JOBOBJECT_EXTENDED_LIMIT_INFORMATION job_limits{};
    job_limits.BasicLimitInformation.LimitFlags = JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE;
    if (!input || !job || !output.open() || !error.open() ||
        !SetInformationJobObject(job.get(), JobObjectExtendedLimitInformation, &job_limits, sizeof(job_limits))) {
        return failure(Status::process_error);
    }

    HANDLE handles[]{input.get(), output.writer.get(), error.writer.get()};
    InheritedHandles inherited;
    if (!inherited.initialize(handles)) {
        return failure(Status::process_error);
    }
    STARTUPINFOEXW startup{};
    startup.StartupInfo.cb = sizeof(startup);
    startup.StartupInfo.dwFlags = STARTF_USESTDHANDLES;
    startup.StartupInfo.hStdInput = input.get();
    startup.StartupInfo.hStdOutput = output.writer.get();
    startup.StartupInfo.hStdError = error.writer.get();
    startup.lpAttributeList = inherited.get();

    if (Clock::now() >= deadline) {
        return failure(Status::timeout);
    }
    PROCESS_INFORMATION process_info{};
    constexpr DWORD creation_flags = CREATE_SUSPENDED | CREATE_NO_WINDOW | EXTENDED_STARTUPINFO_PRESENT;
    if (!CreateProcessW(application.c_str(), line.data(), nullptr, nullptr, TRUE, creation_flags,
                        nullptr, nullptr, &startup.StartupInfo, &process_info)) {
        return failure(Status::process_error);
    }
    const Handle process(process_info.hProcess);
    const Handle thread(process_info.hThread);
    // The initial thread remains suspended until the kill-on-close job owns it.
    if (!AssignProcessToJobObject(job.get(), process.get())) {
        // The verifier has never run and cannot have started descendants.
        if (TerminateProcess(process.get(), static_cast<UINT>(Status::process_error))) {
            WaitForSingleObject(process.get(), cleanup_timeout_ms);
        }
        return failure(Status::process_error);
    }
    output.writer.reset();
    error.writer.reset();

    Result result;
    result.output.reserve(limit);
    result.error.reserve(limit);
    if (Clock::now() >= deadline) {
        result.status = Status::timeout;
    } else if (ResumeThread(thread.get()) == 1) {
        result.status = collect(process.get(), output, error, deadline, limit, result);
    }
    if (!finish_job(job.get())) {
        return failure(Status::process_error);
    }
    if (result.status != Status::ok) {
        return failure(result.status);
    }
    return result;
}

}  // namespace verifier_capture
