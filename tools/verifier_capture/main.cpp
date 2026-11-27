// SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary
#include "capture.hpp"

#include <charconv>
#include <cstdint>
#include <filesystem>
#include <iostream>
#include <optional>
#include <string_view>

namespace verifier_capture {
namespace {

using Scalar = std::uint32_t;
constexpr unsigned max_timeout_ms = 60000;
constexpr unsigned max_stream_bytes = 1024 * 1024;
constexpr char hex_digits[] = "0123456789abcdef";

int hex_digit(char value) {
    if (value >= '0' && value <= '9') {
        return value - '0';
    }
    if (value >= 'a' && value <= 'f') {
        return value - 'a' + 10;
    }
    if (value >= 'A' && value <= 'F') {
        return value - 'A' + 10;
    }
    return -1;
}

std::optional<Scalar> next_scalar(std::string_view& text) {
    const auto first = static_cast<unsigned char>(text.front());
    text.remove_prefix(1);
    if (first > 0 && first < 0x80) {
        return first;
    }

    unsigned remaining;
    Scalar scalar;
    Scalar minimum;
    if (first >= 0xc2 && first <= 0xdf) {
        remaining = 1;
        scalar = first & 0x1f;
        minimum = 0x80;
    } else if (first >= 0xe0 && first <= 0xef) {
        remaining = 2;
        scalar = first & 0x0f;
        minimum = 0x800;
    } else if (first >= 0xf0 && first <= 0xf4) {
        remaining = 3;
        scalar = first & 0x07;
        minimum = 0x10000;
    } else {
        return std::nullopt;
    }
    if (text.size() < remaining) {
        return std::nullopt;
    }
    for (unsigned i = 0; i < remaining; ++i) {
        const auto byte = static_cast<unsigned char>(text[i]);
        if ((byte & 0xc0) != 0x80) {
            return std::nullopt;
        }
        scalar = (scalar << 6) | (byte & 0x3f);
    }
    text.remove_prefix(remaining);
    if (scalar < minimum || scalar > 0x10ffff || (scalar >= 0xd800 && scalar <= 0xdfff)) {
        return std::nullopt;
    }
    return scalar;
}

bool valid_text(std::string_view text) {
    while (!text.empty()) {
        if (!next_scalar(text)) {
            return false;
        }
    }
    return true;
}

std::optional<Scalar> take_escape(std::string_view& text) {
    if (text.size() < 4) {
        return std::nullopt;
    }
    Scalar value = 0;
    for (const char digit : text.substr(0, 4)) {
        const int hex = hex_digit(digit);
        if (hex < 0) {
            return std::nullopt;
        }
        value = (value << 4) | static_cast<Scalar>(hex);
    }
    text.remove_prefix(4);
    return value;
}

// The adapter checks JSON structure and decoded member uniqueness. Check JSON
// Unicode escapes here, before handing any output to a CMake JSON decoder.
bool valid_json_escapes(std::string_view text) {
    bool in_string = false;
    while (!text.empty()) {
        const char token = text.front();
        text.remove_prefix(1);
        if (token == '"') {
            in_string = !in_string;
        } else if (in_string && token == '\\') {
            if (text.empty()) {
                return false;
            }
            const char escape = text.front();
            text.remove_prefix(1);
            if (escape != 'u') {
                continue;
            }
            const auto first = take_escape(text);
            if (!first || (*first >= 0xdc00 && *first <= 0xdfff)) {
                return false;
            }
            if (*first >= 0xd800 && *first <= 0xdbff) {
                if (text.substr(0, 2) != "\\u") {
                    return false;
                }
                text.remove_prefix(2);
                const auto second = take_escape(text);
                if (!second || *second < 0xdc00 || *second > 0xdfff) {
                    return false;
                }
            }
        }
    }
    return true;
}

void append_unicode_escape(std::string& bridge, Scalar unit) {
    bridge += "\\u";
    for (const auto shift : {12, 8, 4, 0}) {
        bridge += hex_digits[(unit >> shift) & 0xf];
    }
}

void append_json_string(std::string& bridge, std::string_view text) {
    bridge += '"';
    while (!text.empty()) {
        const Scalar scalar = next_scalar(text).value();
        if (scalar == '"' || scalar == '\\') {
            bridge += '\\';
            bridge += static_cast<char>(scalar);
        } else if (scalar >= 0x20 && scalar <= 0x7e) {
            bridge += static_cast<char>(scalar);
        } else if (scalar <= 0xffff) {
            append_unicode_escape(bridge, scalar);
        } else {
            const Scalar pair = scalar - 0x10000;
            append_unicode_escape(bridge, 0xd800 | (pair >> 10));
            append_unicode_escape(bridge, 0xdc00 | (pair & 0x3ff));
        }
    }
    bridge += '"';
}

std::optional<unsigned> positive_integer(std::string_view text, unsigned maximum) {
    unsigned value = 0;
    const auto end = text.data() + text.size();
    const auto parsed = std::from_chars(text.data(), end, value);
    if (parsed.ec != std::errc{} || parsed.ptr != end || value == 0 || value > maximum) {
        return std::nullopt;
    }
    return value;
}

std::optional<std::string> decode_argument(std::string_view encoded) {
    if (encoded.empty() || encoded.front() != 'x' || encoded.size() % 2 != 1) {
        return std::nullopt;
    }
    encoded.remove_prefix(1);
    std::string text;
    text.reserve(encoded.size() / 2);
    for (std::size_t i = 0; i < encoded.size(); i += 2) {
        const int high = hex_digit(encoded[i]);
        const int low = hex_digit(encoded[i + 1]);
        if (high < 0 || low < 0) {
            return std::nullopt;
        }
        text += static_cast<char>(high * 16 + low);
    }
    return valid_text(text) ? std::optional<std::string>{std::move(text)} : std::nullopt;
}

Status capture(int argc, char** argv) {
    if (argc < 6 || std::string_view(argv[1]) != "capture") {
        return Status::invalid_arguments;
    }
    const auto timeout = positive_integer(argv[2], max_timeout_ms);
    const auto limit = positive_integer(argv[3], max_stream_bytes);
    const std::string_view mode = argv[4];
    if (!timeout || !limit || (mode != "text" && mode != "json")) {
        return Status::invalid_arguments;
    }
    std::vector<std::string> arguments;
    for (int index = 5; index < argc; ++index) {
        auto argument = decode_argument(argv[index]);
        if (!argument) {
            return Status::invalid_arguments;
        }
        arguments.push_back(std::move(*argument));
    }
    if (!std::filesystem::u8path(arguments.front()).is_absolute()) {
        return Status::invalid_arguments;
    }

    const auto deadline = std::chrono::steady_clock::now() + std::chrono::milliseconds(*timeout);
    const auto result = run(arguments, deadline, *limit);
    if (result.status != Status::ok) {
        return result.status;
    }
    if (!valid_text(result.output) || !valid_text(result.error)) {
        return Status::invalid_encoding;
    }
    if (mode == "json" && result.exit_code == 0 && !valid_json_escapes(result.output)) {
        return Status::invalid_json_strings;
    }

    // ASCII transport protects CR/LF, backslashes, and non-ASCII characters
    // from execute_process text conversion. Each original byte uses at most
    // six bridge bytes. Emit only after successful collection and validation.
    std::string bridge;
    bridge.reserve(128 + 6 * (result.output.size() + result.error.size()));
    bridge = "{\"protocol\":\"ask-verifier-capture-v1\",\"exit\":";
    bridge += std::to_string(result.exit_code);
    bridge += ",\"stdout\":";
    append_json_string(bridge, result.output);
    bridge += ",\"stderr\":";
    append_json_string(bridge, result.error);
    bridge += "}\n";
    std::cout << bridge;
    std::cout.flush();
    return std::cout ? Status::ok : Status::process_error;
}

}  // namespace
}  // namespace verifier_capture

int main(int argc, char** argv) {
    try {
        return static_cast<int>(verifier_capture::capture(argc, argv));
    } catch (...) {
        return static_cast<int>(verifier_capture::Status::process_error);
    }
}
