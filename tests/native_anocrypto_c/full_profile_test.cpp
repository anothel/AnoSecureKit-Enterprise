// SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary
#include "anosecurekit/anosecurekit.hpp"
#include "anosecurekit_enterprise/enterprise.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <iterator>
#include <sstream>
#include <string>
#include <string_view>

#ifndef ANOSECUREKIT_ENTERPRISE_FIXTURE_DIR
#error "ANOSECUREKIT_ENTERPRISE_FIXTURE_DIR is required"
#endif

namespace
{

anosecurekit::bytes bytes_from_text(std::string_view text)
{
    anosecurekit::bytes output;
    output.reserve(text.size());
    for (const char value : text)
    {
        output.push_back(static_cast<std::byte>(static_cast<unsigned char>(value)));
    }
    return output;
}

anosecurekit::key256 key_from_seed(unsigned int seed)
{
    anosecurekit::key256 key{};
    for (std::size_t index = 0; index < key.size(); ++index)
    {
        key[index] = static_cast<std::byte>((seed + index) & 0xffu);
    }
    return key;
}

int hex_value(char value)
{
    if (value >= '0' && value <= '9')
    {
        return value - '0';
    }
    if (value >= 'a' && value <= 'f')
    {
        return 10 + value - 'a';
    }
    return -1;
}

anosecurekit::bytes read_hex_fixture(std::string_view name)
{
    const auto path = std::filesystem::path{ANOSECUREKIT_ENTERPRISE_FIXTURE_DIR} / std::filesystem::path{name};
    std::ifstream input(path, std::ios::binary);
    const std::string encoded{std::istreambuf_iterator<char>{input}, std::istreambuf_iterator<char>{}};
    if (!input.good() && !input.eof())
    {
        throw std::runtime_error("fixture read failed: " + path.string());
    }

    std::string compact;
    for (const char value : encoded)
    {
        if (value != '\n' && value != '\r' && value != ' ' && value != '\t')
        {
            compact.push_back(value);
        }
    }
    if (compact.empty() || compact.size() % 2 != 0)
    {
        throw std::runtime_error("fixture is not canonical hex: " + path.string());
    }

    anosecurekit::bytes output(compact.size() / 2);
    for (std::size_t index = 0; index < output.size(); ++index)
    {
        const int high = hex_value(compact[index * 2]);
        const int low = hex_value(compact[index * 2 + 1]);
        if (high < 0 || low < 0)
        {
            throw std::runtime_error("fixture contains invalid hex: " + path.string());
        }
        output[index] = static_cast<std::byte>((high << 4) | low);
    }
    return output;
}

bool write_file(const std::filesystem::path& path, std::span<const std::byte> input)
{
    std::ofstream output(path, std::ios::binary);
    output.write(reinterpret_cast<const char*>(input.data()), static_cast<std::streamsize>(input.size()));
    return output.good();
}

anosecurekit::bytes read_file(const std::filesystem::path& path)
{
    std::ifstream input(path, std::ios::binary);
    const std::string contents{std::istreambuf_iterator<char>{input}, std::istreambuf_iterator<char>{}};
    anosecurekit::bytes output(contents.size());
    std::transform(contents.begin(), contents.end(), output.begin(),
                   [](char value) { return static_cast<std::byte>(static_cast<unsigned char>(value)); });
    return output;
}

bool no_output_or_temp(const std::filesystem::path& output)
{
    if (std::filesystem::exists(output))
    {
        return false;
    }
    const auto prefix = output.filename().string() + ".anosecurekit.";
    for (const auto& entry : std::filesystem::directory_iterator(output.parent_path()))
    {
        if (entry.path().filename().string().starts_with(prefix))
        {
            return false;
        }
    }
    return true;
}

bool throws_code(const auto& function, anosecurekit::error_code expected)
{
    try
    {
        function();
    }
    catch (const anosecurekit::error& exception)
    {
        return exception.code() == expected;
    }
    catch (...)
    {
        return false;
    }
    return false;
}

void append(anosecurekit::bytes& output, std::span<const std::byte> input)
{
    output.insert(output.end(), input.begin(), input.end());
}

struct cleanup_directory
{
    std::filesystem::path path;
    ~cleanup_directory()
    {
        std::error_code ignored;
        std::filesystem::remove_all(path, ignored);
    }
};

} // namespace

int main(int argc, char** argv)
{
    using namespace anosecurekit_enterprise;
    int failures = 0;
    const auto check = [&failures](bool condition, std::string_view name) {
        if (!condition)
        {
            std::cerr << "AnoCrypto-C full-profile failure: " << name << '\n';
            ++failures;
        }
    };

    check(initialize_backend() == backend_runtime_status::ready, "initialization");
    const auto runtime = current_backend_runtime();
    const auto expected_mask = required_backend_capability_mask();
    check(runtime.status == backend_runtime_status::ready, "runtime ready");
    check(runtime.module_state == backend_module_state::operational, "module operational");
    check(runtime.self_test_status == backend_self_test_status::passed, "self-test passed");
    check(runtime.capability_mask == expected_mask, "complete capability mask");
    check(backend_profile_ready() && anocrypto_backend_available(), "complete profile ready");
    for (const auto capability : required_backend_capabilities())
    {
        check(backend_supports(capability), backend_capability_name(capability));
    }

    const anosecurekit::bytes ikm(22, std::byte{0x0b});
    anosecurekit::bytes salt;
    anosecurekit::bytes info;
    for (unsigned int value = 0; value <= 0x0c; ++value)
    {
        salt.push_back(static_cast<std::byte>(value));
    }
    for (unsigned int value = 0xf0; value <= 0xf9; ++value)
    {
        info.push_back(static_cast<std::byte>(value));
    }
    const auto hkdf_expected = anosecurekit::hex_decode("3cb25f25faacd57a90434f64d0362f2a"
                                                        "2d2d0a90cf1a5a4c5db02d56ecc4c5bf"
                                                        "34007208d5b887185865");
    check(anosecurekit::hkdf_sha256(ikm, salt, info, 42) == hkdf_expected, "RFC 5869 HKDF parity");
    check(anosecurekit::hkdf_sha256({}, {}, {}, 0).empty(), "zero-length HKDF");

    const anosecurekit::key256 zero_key{};
    const auto skt1_aad = bytes_from_text("record:v1");
    const auto skt1_plaintext = bytes_from_text("hello anosecurekit");
    const auto skt1_fixture = read_hex_fixture("skt1-aes256-gcm-aad.hex");
    check(anosecurekit::decrypt(skt1_fixture, zero_key, skt1_aad) == skt1_plaintext, "SKT1 exact fixture");
    const auto generated_packet = anosecurekit::encrypt(skt1_plaintext, zero_key, skt1_aad);
    check(anosecurekit::decrypt(generated_packet, zero_key, skt1_aad) == skt1_plaintext, "SKT1 one-shot roundtrip");
    auto wrong_key = zero_key;
    wrong_key[0] = std::byte{0x01};
    check(throws_code([&] { (void)anosecurekit::decrypt(skt1_fixture, wrong_key, skt1_aad); },
                      anosecurekit::error_code::authentication_failed),
          "SKT1 wrong-key authentication failure");

    constexpr std::size_t packet_prefix_size = 17;
    constexpr std::size_t tag_size = 16;
    const auto prefix = std::span<const std::byte>{skt1_fixture}.first(packet_prefix_size);
    const auto ciphertext = std::span<const std::byte>{skt1_fixture}.subspan(
        packet_prefix_size, skt1_fixture.size() - packet_prefix_size - tag_size);
    const auto tag = std::span<const std::byte>{skt1_fixture}.last(tag_size);
    anosecurekit::packet_decryptor decryptor(zero_key, skt1_aad);
    decryptor.begin(prefix);
    anosecurekit::bytes streamed_plaintext;
    const auto split = std::min<std::size_t>(3, ciphertext.size());
    append(streamed_plaintext, decryptor.update(ciphertext.first(split)));
    append(streamed_plaintext, decryptor.update(ciphertext.subspan(split)));
    append(streamed_plaintext, decryptor.finalize(tag));
    check(streamed_plaintext == skt1_plaintext, "SKT1 streaming fixture and chunk split");

    // Streaming plaintext is not authenticated until finalize succeeds.
    // Keep the update output private and wipe it if tag validation fails.
    std::array<std::byte, tag_size> corrupted_tag{};
    std::copy(tag.begin(), tag.end(), corrupted_tag.begin());
    corrupted_tag[0] ^= std::byte{0x01};
    anosecurekit::packet_decryptor rejected_decryptor(zero_key, skt1_aad);
    rejected_decryptor.begin(prefix);
    auto pending_plaintext = rejected_decryptor.update(ciphertext);
    const bool wrong_tag_rejected = throws_code(
        [&] { (void)rejected_decryptor.finalize(std::span<const std::byte>{corrupted_tag}); },
        anosecurekit::error_code::authentication_failed);
    std::fill(pending_plaintext.begin(), pending_plaintext.end(), std::byte{0});
    check(wrong_tag_rejected, "SKT1 streaming wrong-tag authentication failure");

    anosecurekit::packet_encryptor encryptor(zero_key, skt1_aad);
    anosecurekit::bytes streamed_packet = encryptor.begin();
    append(streamed_packet, encryptor.update(std::span<const std::byte>{skt1_plaintext}.first(5)));
    append(streamed_packet, encryptor.update(std::span<const std::byte>{skt1_plaintext}.subspan(5)));
    append(streamed_packet, encryptor.finalize());
    check(anosecurekit::decrypt(streamed_packet, zero_key, skt1_aad) == skt1_plaintext,
          "SKT1 streaming-to-one-shot compatibility");

    const auto key_to_wrap = key_from_seed(0x10);
    const auto wrapping_key = key_from_seed(0x40);
    const auto wrap_aad = bytes_from_text("key-id:primary");
    check(anosecurekit::unwrap_key(read_hex_fixture("skt1-key-wrap.hex"), wrapping_key, wrap_aad) == key_to_wrap,
          "SKT1 key-wrap fixture");
    check(anosecurekit::unwrap_key(anosecurekit::wrap_key(key_to_wrap, wrapping_key, wrap_aad), wrapping_key,
                                   wrap_aad) == key_to_wrap,
          "SKT1 key-wrap roundtrip");

    const auto base = argc > 1 ? std::filesystem::path{argv[1]} : std::filesystem::current_path();
    const auto root = base / "enterprise-native-full-profile-test";
    cleanup_directory cleanup{root};
    std::error_code filesystem_error;
    std::filesystem::remove_all(root, filesystem_error);
    std::filesystem::create_directories(root, filesystem_error);
    check(!filesystem_error, "test directory setup");

    const auto skf_input = root / "known.skf";
    const auto skf_output = root / "known-skf.bin";
    check(write_file(skf_input, read_hex_fixture("skf1-known-file.hex")), "SKF1 fixture write");
    anosecurekit::open_file(skf_input, skf_output, zero_key, bytes_from_text("fixture:aad"));
    check(read_file(skf_output) == bytes_from_text("known SKF1 vector"), "SKF1 exact fixture");

    const auto skp_input = root / "known.skp";
    const auto skp_output = root / "known-skp.bin";
    check(write_file(skp_input, read_hex_fixture("skp1-known-password-file.hex")), "SKP1 fixture write");
    const auto password = bytes_from_text("known SKP1 password");
    anosecurekit::open_file_with_password(skp_input, skp_output, password, bytes_from_text("fixture:aad"));
    check(read_file(skp_output) == bytes_from_text("known SKP1 vector"), "SKP1 exact fixture");
    const auto wrong_password_output = root / "wrong-password-output.bin";
    check(throws_code(
              [&] {
                  anosecurekit::open_file_with_password(skp_input, wrong_password_output,
                                                        bytes_from_text("wrong password"),
                                                        bytes_from_text("fixture:aad"));
              },
              anosecurekit::error_code::authentication_failed) &&
              no_output_or_temp(wrong_password_output),
          "failed SKP1 path commits no plaintext");

    const auto plain_path = root / "roundtrip.bin";
    const auto sealed_path = root / "roundtrip.skf";
    const auto opened_path = root / "roundtrip-opened.bin";
    const auto file_plaintext = bytes_from_text("AnoCrypto-C Enterprise parity checkpoint");
    check(write_file(plain_path, file_plaintext), "roundtrip plaintext write");
    anosecurekit::seal_file(plain_path, sealed_path, zero_key, bytes_from_text("p3-06"));
    anosecurekit::open_file(sealed_path, opened_path, zero_key, bytes_from_text("p3-06"));
    check(read_file(opened_path) == file_plaintext, "SKF1 path roundtrip");

    const auto failed_output = root / "wrong-key-output.bin";
    check(throws_code(
              [&] { anosecurekit::open_file(skf_input, failed_output, wrong_key, bytes_from_text("fixture:aad")); },
              anosecurekit::error_code::authentication_failed) &&
              no_output_or_temp(failed_output),
          "failed SKF1 path commits no plaintext");

    const auto password_sealed = root / "roundtrip.skp";
    const auto password_opened = root / "roundtrip-password-opened.bin";
    anosecurekit::seal_file_with_password(plain_path, password_sealed, password, bytes_from_text("p3-06-password"));
    anosecurekit::open_file_with_password(password_sealed, password_opened, password,
                                          bytes_from_text("p3-06-password"));
    check(read_file(password_opened) == file_plaintext, "SKP1 path roundtrip");

    shutdown_backend();
    if (failures != 0)
    {
        return 1;
    }
    std::cout << "native capabilities: sha256 hmac-sha256 hkdf-sha256 random "
                 "scrypt aes256-gcm aes256-gcm-stream\n"
              << "native lifecycle ready: yes\n"
              << "native complete profile ready: yes\n"
              << "SKT1/SKF1/SKP1 parity: yes\n"
              << "OpenSSL fallback: absent\n"
              << "customer release authorization: no\n";
    return 0;
}
