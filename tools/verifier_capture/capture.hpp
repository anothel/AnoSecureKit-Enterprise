// SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary
#pragma once

#include <chrono>
#include <cstddef>
#include <string>
#include <vector>

namespace verifier_capture {

enum class Status {
    ok = 0,
    invalid_arguments = 64,
    process_error = 65,
    output_limit = 66,
    timeout = 67,
    invalid_encoding = 68,
    terminated = 69,
    invalid_json_strings = 70
};

struct Result {
    Status status = Status::process_error;
    unsigned long exit_code = 0;
    std::string output;
    std::string error;
};

Result run(const std::vector<std::string>& argv, std::chrono::steady_clock::time_point deadline,
           std::size_t limit);

}  // namespace verifier_capture
