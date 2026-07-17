// SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary
#include "anosecurekit/anosecurekit.hpp"
#include "anosecurekit_enterprise/enterprise.hpp"

#include <cstdint>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <sstream>
#include <string>
#include <string_view>

namespace
{

constexpr std::string_view unconnected_message = "AnoCrypto-C service is not connected";

template <typename Function>
bool fails_unconnected(std::string_view name, Function&& function)
{
    try
    {
        function();
    }
    catch (const anosecurekit::error& exception)
    {
        if (exception.code() == anosecurekit::error_code::backend_failure
            && std::string_view{exception.what()} == unconnected_message)
        {
            return true;
        }
        std::cerr << name << ": wrong error: " << exception.what() << '\n';
        return false;
    }
    catch (const std::exception& exception)
    {
        std::cerr << name << ": wrong exception: " << exception.what() << '\n';
        return false;
    }
    std::cerr << name << ": unsupported service returned successfully\n";
    return false;
}

void store_u32_be(anosecurekit::bytes& output, std::size_t offset, std::uint32_t value)
{
    output[offset] = static_cast<std::byte>((value >> 24) & 0xffu);
    output[offset + 1] = static_cast<std::byte>((value >> 16) & 0xffu);
    output[offset + 2] = static_cast<std::byte>((value >> 8) & 0xffu);
    output[offset + 3] = static_cast<std::byte>(value & 0xffu);
}

anosecurekit::bytes skt1_packet()
{
    anosecurekit::bytes packet(33);
    packet[0] = std::byte{'S'};
    packet[1] = std::byte{'K'};
    packet[2] = std::byte{'T'};
    packet[3] = std::byte{'1'};
    packet[4] = std::byte{0x01};
    return packet;
}

anosecurekit::bytes skf1_header()
{
    anosecurekit::bytes header(50);
    header[0] = std::byte{'S'};
    header[1] = std::byte{'K'};
    header[2] = std::byte{'F'};
    header[3] = std::byte{'1'};
    header[4] = std::byte{0x01};
    header[5] = std::byte{0x01};
    store_u32_be(header, 6, 1024u * 1024u);
    return header;
}

anosecurekit::bytes skp1_header()
{
    anosecurekit::bytes header(64);
    header[0] = std::byte{'S'};
    header[1] = std::byte{'K'};
    header[2] = std::byte{'P'};
    header[3] = std::byte{'1'};
    header[4] = std::byte{0x01};
    header[5] = std::byte{0x01};
    header[6] = std::byte{0x01};
    store_u32_be(header, 8, 1024u * 1024u);
    store_u32_be(header, 52, 32768u);
    store_u32_be(header, 56, 8u);
    store_u32_be(header, 60, 1u);
    return header;
}

std::string as_string(const anosecurekit::bytes& input)
{
    return {reinterpret_cast<const char*>(input.data()), input.size()};
}

bool write_file(const std::filesystem::path& path, const anosecurekit::bytes& input)
{
    std::ofstream output(path, std::ios::binary);
    output.write(reinterpret_cast<const char*>(input.data()),
                 static_cast<std::streamsize>(input.size()));
    return output.good();
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
            std::cerr << "partial profile failure: " << name << '\n';
            ++failures;
        }
    };

    check(initialize_backend() == backend_runtime_status::ready, "initialization");
    const auto runtime = current_backend_runtime();
    constexpr auto expected_mask =
        backend_capability_bit(crypto_backend_capability::sha256)
        | backend_capability_bit(crypto_backend_capability::hmac_sha256)
        | backend_capability_bit(crypto_backend_capability::random);
    constexpr auto unknown_capability = static_cast<crypto_backend_capability>(63);
    check(runtime.status == backend_runtime_status::ready, "runtime ready");
    check(runtime.module_state == backend_module_state::operational, "module operational");
    check(runtime.self_test_status == backend_self_test_status::passed, "self-test passed");
    check(runtime.capability_mask == expected_mask, "exact capability mask");
    check(backend_capability_mask_has(runtime.capability_mask, crypto_backend_capability::sha256),
          "SHA-256 capability");
    check(backend_capability_mask_has(runtime.capability_mask, crypto_backend_capability::hmac_sha256),
          "HMAC-SHA-256 capability");
    check(backend_capability_mask_has(runtime.capability_mask, crypto_backend_capability::random),
          "random capability");
    check(!backend_capability_mask_has(runtime.capability_mask, crypto_backend_capability::hkdf_sha256),
          "HKDF-SHA-256 absent");
    check(!backend_capability_mask_has(runtime.capability_mask, crypto_backend_capability::scrypt),
          "scrypt absent");
    check(!backend_capability_mask_has(runtime.capability_mask, crypto_backend_capability::aes256_gcm),
          "AES-256-GCM absent");
    check(!backend_capability_mask_has(runtime.capability_mask, crypto_backend_capability::aes256_gcm_stream),
          "streaming AES-256-GCM absent");
    check(!backend_capability_mask_has(runtime.capability_mask, unknown_capability)
              && backend_capability_name(unknown_capability) == "unknown",
          "unknown capability absent");
    check(expected_mask != required_backend_capability_mask() && !backend_profile_ready()
              && !anocrypto_backend_available(),
          "complete profile blocked");

    const anosecurekit::key256 key{};
    const anosecurekit::bytes data{std::byte{0x01}};
    anosecurekit::bytes result{std::byte{0x7f}};
    check(fails_unconnected("HKDF-SHA-256", [&] {
              result = anosecurekit::hkdf_sha256(data, data, data, 32);
          }) && result == anosecurekit::bytes{std::byte{0x7f}},
          "HKDF-SHA-256 fail-closed");
    check(fails_unconnected("zero-length HKDF-SHA-256", [&] {
              result = anosecurekit::hkdf_sha256(data, {}, {}, 0);
          }) && result == anosecurekit::bytes{std::byte{0x7f}},
          "unsupported empty HKDF is not successful empty output");
    check(fails_unconnected("AEAD encrypt", [&] { result = anosecurekit::encrypt({}, key); })
              && result == anosecurekit::bytes{std::byte{0x7f}},
          "AEAD encrypt fail-closed");
    const auto packet = skt1_packet();
    check(fails_unconnected("AEAD decrypt", [&] { result = anosecurekit::decrypt(packet, key); })
              && result == anosecurekit::bytes{std::byte{0x7f}},
          "AEAD decrypt exposes no plaintext");

    anosecurekit::packet_encryptor encryptor(key);
    check(fails_unconnected("packet encryptor", [&] { result = encryptor.begin(); })
              && result == anosecurekit::bytes{std::byte{0x7f}},
          "packet encryption fail-closed");
    anosecurekit::packet_decryptor decryptor(key);
    check(fails_unconnected("packet decryptor", [&] {
              decryptor.begin(std::span<const std::byte>{packet}.first(17));
          }) && result == anosecurekit::bytes{std::byte{0x7f}},
          "packet decryption exposes no plaintext");
    check(fails_unconnected("key wrap", [&] { result = anosecurekit::wrap_key(key, key); })
              && result == anosecurekit::bytes{std::byte{0x7f}},
          "key wrap fail-closed");
    check(fails_unconnected("key unwrap", [&] { (void)anosecurekit::unwrap_key(packet, key); }),
          "key unwrap fail-closed");

    const auto base = argc > 1 ? std::filesystem::path{argv[1]} : std::filesystem::current_path();
    const auto root = base / "enterprise-native-partial-profile-test";
    cleanup_directory cleanup{root};
    std::error_code filesystem_error;
    std::filesystem::remove_all(root, filesystem_error);
    std::filesystem::create_directories(root, filesystem_error);
    check(!filesystem_error, "test directory setup");
    const auto plain = root / "plain.bin";
    const auto raw_packet = root / "input.skf";
    const auto password_packet = root / "input.skp";
    check(write_file(plain, data) && write_file(raw_packet, skf1_header())
              && write_file(password_packet, skp1_header()),
          "test input setup");

    const auto raw_sealed = root / "raw-sealed.skf";
    check(fails_unconnected("raw-key file sealing", [&] {
              anosecurekit::seal_file(plain, raw_sealed, key);
          }) && no_output_or_temp(raw_sealed),
          "raw-key seal commits no output");
    const auto raw_opened = root / "raw-opened.bin";
    check(fails_unconnected("raw-key file verification", [&] {
              anosecurekit::open_file(raw_packet, raw_opened, key);
          }) && no_output_or_temp(raw_opened),
          "raw-key verification commits no plaintext");

    const anosecurekit::bytes password{std::byte{'p'}};
    const auto password_sealed = root / "password-sealed.skp";
    check(fails_unconnected("password file sealing", [&] {
              anosecurekit::seal_file_with_password(plain, password_sealed, password);
          }) && no_output_or_temp(password_sealed),
          "password seal commits no output");
    const auto password_opened = root / "password-opened.bin";
    check(fails_unconnected("password file verification", [&] {
              anosecurekit::open_file_with_password(password_packet, password_opened, password);
          }) && no_output_or_temp(password_opened),
          "password verification commits no plaintext");

    std::istringstream raw_stream(as_string(skf1_header()), std::ios::in | std::ios::binary);
    std::ostringstream raw_output(std::ios::out | std::ios::binary);
    raw_output << "sentinel";
    check(fails_unconnected("raw-key stream verification", [&] {
              anosecurekit::open_file(raw_stream, raw_output, key);
          }) && raw_output.str() == "sentinel",
          "raw-key stream exposes no plaintext");
    std::istringstream password_stream(as_string(skp1_header()), std::ios::in | std::ios::binary);
    std::ostringstream password_output(std::ios::out | std::ios::binary);
    password_output << "sentinel";
    check(fails_unconnected("password stream verification", [&] {
              anosecurekit::open_file_with_password(password_stream, password_output, password);
          }) && password_output.str() == "sentinel",
          "password stream exposes no plaintext");

    shutdown_backend();
    if (failures != 0)
    {
        return 1;
    }
    std::cout << "native capabilities: sha256 hmac-sha256 random\n"
              << "native lifecycle ready: yes\n"
              << "native complete profile ready: no\n"
              << "OpenSSL fallback: absent\n"
              << "native installation/package: blocked\n";
    return 0;
}
