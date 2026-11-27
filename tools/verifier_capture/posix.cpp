// SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary
#include "capture.hpp"

#include <algorithm>
#include <array>
#include <cerrno>
#include <climits>
#include <cstdlib>
#include <dirent.h>
#include <fcntl.h>
#include <poll.h>
#include <signal.h>
#include <spawn.h>
#include <sys/wait.h>
#include <unistd.h>

extern char** environ;

namespace verifier_capture {
namespace {

using Clock = std::chrono::steady_clock;
using namespace std::chrono_literals;

class Descriptor {
public:
    Descriptor() = default;
    ~Descriptor() { reset(); }
    Descriptor(const Descriptor&) = delete;
    Descriptor& operator=(const Descriptor&) = delete;

    int get() const { return value_; }
    explicit operator bool() const { return value_ >= 0; }
    void reset(int value = -1) {
        if (*this) {
            close(value_);
        }
        value_ = value;
    }

private:
    int value_ = -1;
};

bool open_pipe(Descriptor& reader, Descriptor& writer) {
    int pipe_fds[2];
    if (pipe(pipe_fds) != 0) {
        return false;
    }
    reader.reset(pipe_fds[0]);
    writer.reset(pipe_fds[1]);
    for (const auto descriptor : {&reader, &writer}) {
        if (descriptor->get() <= STDERR_FILENO) {
            const int moved = fcntl(descriptor->get(), F_DUPFD_CLOEXEC, STDERR_FILENO + 1);
            if (moved < 0) {
                return false;
            }
            descriptor->reset(moved);
        } else if (fcntl(descriptor->get(), F_SETFD, FD_CLOEXEC) != 0) {
            return false;
        }
    }
    return fcntl(reader.get(), F_SETFL, O_NONBLOCK) == 0;
}

class SpawnSettings {
public:
    ~SpawnSettings() {
        if (has_actions_) {
            posix_spawn_file_actions_destroy(&actions);
        }
        if (has_attributes_) {
            posix_spawnattr_destroy(&attributes);
        }
    }

    bool initialize(int out, int err) {
        has_actions_ = posix_spawn_file_actions_init(&actions) == 0;
        has_attributes_ = posix_spawnattr_init(&attributes) == 0;
        if (!has_actions_ || !has_attributes_) {
            return false;
        }

        short flags = POSIX_SPAWN_SETPGROUP;
#ifdef __APPLE__
        flags |= POSIX_SPAWN_CLOEXEC_DEFAULT;
#endif
        if (posix_spawnattr_setflags(&attributes, flags) != 0 ||
            posix_spawnattr_setpgroup(&attributes, 0) != 0 ||
            posix_spawn_file_actions_addopen(&actions, STDIN_FILENO, "/dev/null", O_RDONLY, 0) != 0 ||
            posix_spawn_file_actions_adddup2(&actions, out, STDOUT_FILENO) != 0 ||
            posix_spawn_file_actions_adddup2(&actions, err, STDERR_FILENO) != 0) {
            return false;
        }
#ifdef __APPLE__
        return true;
#else
        return close_inherited_descriptors();
#endif
    }

    posix_spawn_file_actions_t actions{};
    posix_spawnattr_t attributes{};

private:
#ifndef __APPLE__
    bool close_inherited_descriptors() {
#if defined(__GLIBC_PREREQ)
#if __GLIBC_PREREQ(2, 34)
        return posix_spawn_file_actions_addclosefrom_np(&actions, STDERR_FILENO + 1) == 0;
#endif
#endif
        // Older Linux libc: the helper is single-threaded, so its open FD
        // inventory stays fixed between enumeration and spawn.
        DIR* directory = opendir("/proc/self/fd");
        if (!directory) {
            return false;
        }
        bool success = true;
        while (success) {
            errno = 0;
            const dirent* entry = readdir(directory);
            if (!entry) {
                success = errno == 0;
                break;
            }
            char* end = nullptr;
            const long fd = std::strtol(entry->d_name, &end, 10);
            if (end != entry->d_name && !*end && fd > STDERR_FILENO && fd <= INT_MAX &&
                fd != dirfd(directory)) {
                success = posix_spawn_file_actions_addclose(&actions, static_cast<int>(fd)) == 0;
            }
        }
        return closedir(directory) == 0 && success;
    }
#endif
    bool has_actions_ = false;
    bool has_attributes_ = false;
};

class ProcessGroup {
public:
    explicit ProcessGroup(pid_t leader) : leader_(leader) {}
    ~ProcessGroup() {
        if (leader_ > 0) {
            stop();
        }
    }

    bool stop() {
        // Keep the leader waitable until after signalling its group. This
        // prevents a recycled PID from referring to an unrelated group.
        const pid_t leader = leader_;
        leader_ = -1;
        const bool group_signalled = kill(-leader, SIGKILL) == 0 || errno == ESRCH;
        if (!group_signalled) {
            kill(leader, SIGKILL);
        }
        const auto until = Clock::now() + 1s;
        do {
            const pid_t waited = waitpid(leader, nullptr, WNOHANG);
            if (waited == leader) {
                return group_signalled;
            }
            if (waited < 0 && errno != EINTR) {
                return false;
            }
            poll(nullptr, 0, 5);
        } while (Clock::now() < until);
        return false;
    }

private:
    pid_t leader_;
};

Status read_stream(Descriptor& descriptor, std::string& bytes, std::size_t limit) {
    std::array<char, 8192> chunk;
    const std::size_t room = limit - bytes.size();
    const auto count = read(descriptor.get(), chunk.data(), std::min(chunk.size(), room + 1));
    if (count < 0) {
        return errno == EINTR || errno == EAGAIN || errno == EWOULDBLOCK ? Status::ok
                                                                      : Status::process_error;
    }
    if (count == 0) {
        descriptor.reset();
    } else if (static_cast<std::size_t>(count) > room) {
        return Status::output_limit;
    } else {
        bytes.append(chunk.data(), static_cast<std::size_t>(count));
    }
    return Status::ok;
}

Status collect(pid_t leader, Descriptor& out, Descriptor& err, Clock::time_point deadline,
               std::size_t limit, Result& result) {
    for (;;) {
        const auto remaining = deadline - Clock::now();
        if (remaining <= Clock::duration::zero()) {
            return Status::timeout;
        }
        if (!out && !err) {
            siginfo_t state{};
            if (waitid(P_PID, static_cast<id_t>(leader), &state, WEXITED | WNOHANG | WNOWAIT) != 0) {
                if (errno != EINTR) {
                    return Status::process_error;
                }
            } else if (state.si_pid == leader) {
                if (state.si_code != CLD_EXITED) {
                    return Status::terminated;
                }
                result.exit_code = static_cast<unsigned long>(state.si_status);
                return Status::ok;
            }
        }

        pollfd streams[] = {{out.get(), POLLIN, 0}, {err.get(), POLLIN, 0}};
        const auto pause = std::min(std::chrono::ceil<std::chrono::milliseconds>(remaining), 15ms);
        if (poll(streams, 2, static_cast<int>(pause.count())) < 0) {
            if (errno == EINTR) {
                continue;
            }
            return Status::process_error;
        }
        if ((streams[0].revents | streams[1].revents) & POLLNVAL) {
            return Status::process_error;
        }
        if (streams[0].revents != 0) {
            const auto status = read_stream(out, result.output, limit);
            if (status != Status::ok) {
                return status;
            }
        }
        if (streams[1].revents != 0) {
            const auto status = read_stream(err, result.error, limit);
            if (status != Status::ok) {
                return status;
            }
        }
    }
}

}  // namespace

Result run(const std::vector<std::string>& argv, Clock::time_point deadline, std::size_t limit) {
    Result result;
    // An inherited SIGCHLD ignore disposition could reap the leader before
    // the helper can observe its exit and safely target the process group.
    struct sigaction child_signal {};
    child_signal.sa_handler = SIG_DFL;
    if (sigemptyset(&child_signal.sa_mask) != 0 || sigaction(SIGCHLD, &child_signal, nullptr) != 0) {
        return result;
    }
    result.output.reserve(limit);
    result.error.reserve(limit);
    Descriptor out;
    Descriptor out_writer;
    Descriptor err;
    Descriptor err_writer;
    if (!open_pipe(out, out_writer) || !open_pipe(err, err_writer)) {
        return result;
    }
    SpawnSettings settings;
    if (!settings.initialize(out_writer.get(), err_writer.get())) {
        return result;
    }
    std::vector<char*> arguments;
    arguments.reserve(argv.size() + 1);
    for (const auto& arg : argv) {
        arguments.push_back(const_cast<char*>(arg.c_str()));
    }
    arguments.push_back(nullptr);
    if (Clock::now() >= deadline) {
        result.status = Status::timeout;
        return result;
    }

    pid_t leader;
    if (posix_spawn(&leader, arguments.front(), &settings.actions, &settings.attributes,
                    arguments.data(), environ) != 0) {
        return result;
    }

    ProcessGroup group(leader);
    out_writer.reset();
    err_writer.reset();
    result.status = collect(leader, out, err, deadline, limit, result);
    out.reset();
    err.reset();
    if (!group.stop()) {
        result.status = Status::process_error;
    }
    return result;
}

}  // namespace verifier_capture
