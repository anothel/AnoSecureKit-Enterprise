// SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary

#include <chrono>
#include <csignal>
#include <cstdio>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <string>
#include <string_view>
#include <thread>

#ifdef _WIN32
#define WIN32_LEAN_AND_MEAN
#include <fcntl.h>
#include <io.h>
#include <windows.h>
#else
#include <unistd.h>
#endif

namespace {

using namespace std::chrono_literals;

#ifdef _WIN32
using argument_char = wchar_t;
#else
using argument_char = char;
#endif
using argument_view = std::basic_string_view<argument_char>;
using argument_string = std::basic_string<argument_char>;

constexpr int fixture_error = 2;
constexpr std::size_t pipe_test_size = 131072;

std::string utf8(argument_view argument)
{
#ifdef _WIN32
    const auto size = static_cast<int>(argument.size());
    const int byte_count =
        WideCharToMultiByte(CP_UTF8, WC_ERR_INVALID_CHARS, argument.data(), size, nullptr, 0, nullptr, nullptr);
    std::string bytes(static_cast<std::size_t>(byte_count), '\0');
    if (byte_count > 0) {
        WideCharToMultiByte(CP_UTF8, WC_ERR_INVALID_CHARS, argument.data(), size, bytes.data(), byte_count,
                            nullptr, nullptr);
    }
    return bytes;
#else
    return std::string(argument);
#endif
}

int mark(argument_view path)
{
    std::ofstream marker{std::filesystem::path(path)};
    marker.put('1');
    marker.close();
    return marker ? 0 : fixture_error;
}

int mark_later(argument_view path)
{
    std::this_thread::sleep_for(1800ms);
    return mark(path);
}

bool spawn_marker(argument_view executable, const argument_string& path)
{
#ifdef _WIN32
    const argument_string application(executable);
    // Windows paths cannot contain quotes, and the marker path has a filename.
    auto command = L"\"" + application + L"\" mark-later \"" + path + L"\"";
    STARTUPINFOW startup{};
    startup.cb = sizeof(startup);
    startup.dwFlags = STARTF_USESTDHANDLES;
    startup.hStdInput = GetStdHandle(STD_INPUT_HANDLE);
    startup.hStdOutput = GetStdHandle(STD_OUTPUT_HANDLE);
    startup.hStdError = GetStdHandle(STD_ERROR_HANDLE);
    PROCESS_INFORMATION child{};
    if (!CreateProcessW(application.c_str(), command.data(), nullptr, nullptr, TRUE, 0, nullptr, nullptr,
                        &startup, &child)) {
        return false;
    }
    CloseHandle(child.hThread);
    CloseHandle(child.hProcess);
    return true;
#else
    (void)executable;
    const auto child = fork();
    if (child == 0) {
        _exit(mark_later(path));
    }
    return child > 0;
#endif
}

void report_limit_bytes()
{
    const std::string stdout_chunk(4096, 'o');
    const std::string stderr_chunk(4096, 'e');
    for (std::size_t emitted = 0; emitted < pipe_test_size; emitted += stdout_chunk.size()) {
        std::cout << stdout_chunk;
        std::cerr << stderr_chunk;
    }
}

int emit_rejected_output(std::string_view mode)
{
    if (mode == "malformed-stdout" || mode == "malformed-stderr") {
        auto& stream = mode == "malformed-stdout" ? std::cout : std::cerr;
        stream.write("\xc3(", 2);
    } else if (mode == "nul-stdout" || mode == "nul-stderr") {
        auto& stream = mode == "nul-stdout" ? std::cout : std::cerr;
        stream.write("a\0b", 3);
    } else if (mode == "lone-surrogate") {
        std::cout << R"({"name":"\uD800"})" << '\n';
    } else if (mode == "lone-low-surrogate") {
        std::cout << R"({"name":"\uDC00"})" << '\n';
    } else if (mode == "raw-control") {
        std::cout << "[]\x04";
    } else if (mode == "escaped-nul-duplicate") {
        std::cout << R"({"sample\u0000":1,"sample\u0000":2})" << '\n';
    } else if (mode == "array-ancestry") {
        std::cout << R"({"sample":[{"runnerEnvironment":null}]})" << '\n';
    } else if (mode == "nested-document") {
        constexpr std::size_t depth = 1100;
        std::cout << std::string(depth, '[') << "null" << std::string(depth, ']') << '\n';
    } else {
        return fixture_error;
    }
    return 0;
}

int run_adapter_fixture(std::string_view mode, int argc, argument_char** argv)
{
    int index = 2;
    while (index < argc && utf8(argv[index]) != "--") {
        ++index;
    }
    ++index;
    if (index + 1 == argc && utf8(argv[index]) == "--version") {
        std::cout << "gh version 2.95.0\n";
    } else if (index + 2 == argc && utf8(argv[index]) == "attestation" &&
               utf8(argv[index + 1]) == "--help") {
        std::cout << "gh attestation\n";
    } else if (index + 3 == argc && utf8(argv[index]) == "attestation" &&
               utf8(argv[index + 1]) == "verify" && utf8(argv[index + 2]) == "--help") {
        std::cout << "gh attestation verify --format json\n";
    } else if (index + 2 < argc && utf8(argv[index]) == "attestation" &&
               utf8(argv[index + 1]) == "verify") {
        return emit_rejected_output(mode);
    } else {
        return fixture_error;
    }
    return 0;
}

int run_fixture(int argc, argument_char** argv)
{
    if (argc < 2) {
        return fixture_error;
    }
    const auto mode = utf8(argv[1]);
    constexpr std::string_view adapter_prefix = "-DFAKE_MODE=";
    if (mode.compare(0, adapter_prefix.size(), adapter_prefix) == 0) {
        return run_adapter_fixture(std::string_view(mode).substr(adapter_prefix.size()), argc, argv);
    }
    if (mode == "text") {
        std::cout << "sample: \"quoted\" \\ text\r\nnext\tline\n";
        std::cerr << "note\x1b\n";
        return 23;
    }
    if (mode == "argv") {
        for (int index = 2; index < argc; ++index) {
            std::cout << '<' << utf8(argv[index]) << ">\n";
        }
        return 0;
    }
    if (mode == "exact-cap" || mode == "stdout-over-cap" || mode == "stderr-over-cap") {
        report_limit_bytes();
        if (mode == "stdout-over-cap") {
            std::cout.put('o').flush();
        }
        if (mode == "stderr-over-cap") {
            std::cerr.put('e');
        }
        if (mode != "exact-cap") {
            // Keep both pipes open after the extra byte reaches the reader.
            std::this_thread::sleep_for(4s);
        }
        return 0;
    }
    if (mode == "json") {
        std::cout << R"({"name":"\u0000","surrogate pair":"\uD83C\uDF40","literal":"\\u0000"})" << '\n';
        std::cerr << "literal \\uD800\n";
        return 0;
    }
    if (mode == "signal") {
#ifdef _WIN32
        // Windows represents Ctrl-C termination with this native exit status.
        ExitProcess(0xC000013AUL);
#else
        std::raise(SIGTERM);
        return fixture_error;
#endif
    }
    if (mode == "mark-later" && argc == 3) {
        return mark_later(argv[2]);
    }
    if (mode == "tree" && argc == 3) {
        const argument_string marker(argv[2]);
#ifdef _WIN32
        if (!spawn_marker(argv[0], marker + L".child") || mark(marker + L".started") != 0) {
            return fixture_error;
        }
        return mark_later(marker + L".parent");
#else
        if (!spawn_marker(argv[0], marker + ".child") || mark(marker + ".started") != 0) {
            return fixture_error;
        }
        return mark_later(marker + ".parent");
#endif
    }
    return emit_rejected_output(mode);
}

}  // namespace

#ifdef _WIN32
int wmain(int argc, wchar_t** argv)
{
    if (_setmode(_fileno(stdout), _O_BINARY) == -1 || _setmode(_fileno(stderr), _O_BINARY) == -1) {
        return fixture_error;
    }
    return run_fixture(argc, argv);
}
#else
int main(int argc, char** argv)
{
    return run_fixture(argc, argv);
}
#endif
