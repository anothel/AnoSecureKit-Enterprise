// SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary
#include "anosecurekit_enterprise/enterprise.hpp"

#include "anosecurekit/error.hpp"
#include "anosecurekit/hash.hpp"
#include "anosecurekit/hex.hpp"

#ifdef ANOSECUREKIT_ENTERPRISE_BACKEND_ANOCRYPTO_C
#include "status_mapping.hpp"

#include <anocrypto/ac_hmac.h>
#endif

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <iostream>
#include <span>
#include <string_view>
#include <utility>

namespace
{
anosecurekit::bytes ascii_bytes(std::string_view text)
{
    anosecurekit::bytes output;
    output.reserve(text.size());
    for (const char value : text)
    {
        output.push_back(static_cast<std::byte>(static_cast<unsigned char>(value)));
    }
    return output;
}

anosecurekit::bytes repeated_bytes(std::size_t size, std::byte value)
{
    return anosecurekit::bytes(size, value);
}

anosecurekit::bytes sequence_bytes(std::size_t size,
                                   std::size_t multiplier,
                                   std::size_t offset)
{
    anosecurekit::bytes output(size);
    for (std::size_t index = 0; index < output.size(); ++index)
    {
        output[index] = static_cast<std::byte>((index * multiplier + offset) & 0xffu);
    }
    return output;
}

int fail(int code, std::string_view message)
{
    anosecurekit_enterprise::shutdown_backend();
    std::cerr << "HMAC-SHA-256 test failure: " << message << '\n';
    return code;
}

template <typename Function>
bool fails_as_backend_error(Function&& function)
{
    try
    {
        std::forward<Function>(function)();
    }
    catch (const anosecurekit::error& error)
    {
        return error.code() == anosecurekit::error_code::backend_failure;
    }
    catch (...)
    {
    }
    return false;
}

bool check_mac(std::string_view name,
               std::span<const std::byte> key,
               std::span<const std::byte> input,
               std::string_view expected)
{
    const anosecurekit::bytes key_before(key.begin(), key.end());
    const anosecurekit::bytes input_before(input.begin(), input.end());
    const auto first = anosecurekit::hmac_sha256(key, input);
    const auto second = anosecurekit::hmac_sha256(key, input);
    const auto actual = anosecurekit::hex_encode(std::span<const std::byte>{first});
    std::cout << name << '=' << actual << '\n';
    return actual == expected && first == second
        && std::equal(key.begin(), key.end(), key_before.begin(), key_before.end())
        && std::equal(input.begin(), input.end(), input_before.begin(), input_before.end());
}
} // namespace

int main()
{
    using namespace anosecurekit_enterprise;

#ifdef ANOSECUREKIT_ENTERPRISE_BACKEND_ANOCRYPTO_C
    constexpr auto capability_mask =
        backend_capability_bit(crypto_backend_capability::sha256)
        | backend_capability_bit(crypto_backend_capability::hmac_sha256);
    const auto initial = current_backend_runtime();
    if ((initial.module_state != backend_module_state::uninitialized
         && initial.module_state != backend_module_state::shutdown)
        || initial.capability_mask != capability_mask || backend_profile_ready()
        || !fails_as_backend_error([] { (void)anosecurekit::hmac_sha256({}, {}); }))
    {
        return fail(1, "pre-initialization gate");
    }
#endif

    if (initialize_backend() != backend_runtime_status::ready)
    {
        return fail(2, "runtime initialization");
    }

#ifdef ANOSECUREKIT_ENTERPRISE_BACKEND_ANOCRYPTO_C
    const auto runtime = current_backend_runtime();
    if (runtime.status != backend_runtime_status::ready
        || runtime.module_state != backend_module_state::operational
        || runtime.capability_mask != capability_mask || backend_profile_ready()
        || anocrypto_backend_available())
    {
        return fail(3, "partial runtime capability");
    }
#endif

    const auto rfc1_key = repeated_bytes(20, std::byte{0x0b});
    const auto rfc3_key = repeated_bytes(20, std::byte{0xaa});
    const auto rfc3_input = repeated_bytes(50, std::byte{0xdd});
    const auto rfc4_key = sequence_bytes(25, 1, 1);
    const auto rfc4_input = repeated_bytes(50, std::byte{0xcd});
    const auto long_key = repeated_bytes(131, std::byte{0xaa});
    const auto binary_key = anosecurekit::bytes{
        std::byte{0x00}, std::byte{0x01}, std::byte{0x00},
        std::byte{0xff}, std::byte{0x02}, std::byte{0x00}};
    const auto binary_input = anosecurekit::bytes{
        std::byte{0x00}, std::byte{0xff}, std::byte{0x00}, std::byte{0x03},
        std::byte{0x04}, std::byte{0x00}, std::byte{0x80}};
    const auto block_key = sequence_bytes(64, 1, 0);
    const auto multi_block_key = sequence_bytes(65, 7, 3);
    const auto multi_block_input = sequence_bytes(257, 31, 7);
    const auto large_key = sequence_bytes(37, 13, 5);
    const auto large_input = sequence_bytes(1024 * 1024, 131, 17);

    bool vectors_ok = true;
    vectors_ok &= check_mac(
        "rfc4231-1", rfc1_key, ascii_bytes("Hi There"),
        "b0344c61d8db38535ca8afceaf0bf12b881dc200c9833da726e9376c2e32cff7");
    vectors_ok &= check_mac(
        "rfc4231-2", ascii_bytes("Jefe"), ascii_bytes("what do ya want for nothing?"),
        "5bdcc146bf60754e6a042426089575c75a003f089d2739839dec58b964ec3843");
    vectors_ok &= check_mac(
        "rfc4231-3", rfc3_key, rfc3_input,
        "773ea91e36800e46854db8ebd09181a72959098b3ef8c122d9635514ced565fe");
    vectors_ok &= check_mac(
        "rfc4231-4", rfc4_key, rfc4_input,
        "82558a389a443c0ea4cc819899f2083a85f0faa3e578f8077a2e3ff46729665b");
    vectors_ok &= check_mac(
        "rfc4231-6", long_key,
        ascii_bytes("Test Using Larger Than Block-Size Key - Hash Key First"),
        "60e431591ee0b67f0d8a26aacbf5b77f8e0bc6213728c5140546040f0ee37f54");
    vectors_ok &= check_mac(
        "rfc4231-7", long_key,
        ascii_bytes("This is a test using a larger than block-size key and a larger than "
                    "block-size data. The key needs to be hashed before being used by the "
                    "HMAC algorithm."),
        "9b09ffa71b942fcb27635fbcd5b0e944bfdc63644f0713938a7f51535c3a35e2");
    vectors_ok &= check_mac(
        "empty", {}, {},
        "b613679a0814d9ec772f95d778c35fc5ff1697c493715653c6c712144292c5ad");
    vectors_ok &= check_mac(
        "empty-message", ascii_bytes("key"), {},
        "5d5d139563c95b5967b9bd9a8c9b233a9dedb45072794cd232dc1b74832607d0");
    vectors_ok &= check_mac(
        "empty-key", {}, ascii_bytes("abc"),
        "fd7adb152c05ef80dccf50a1fa4c05d5a3ec6da95575fc312ae7c5d091836351");
    vectors_ok &= check_mac(
        "binary-zero", binary_key, binary_input,
        "f63392538ac9e3618c2f7ca0a4ad202dadea7a4a5537a2c5d9b51bf45219cbc9");
    vectors_ok &= check_mac(
        "short-key", ascii_bytes("key"),
        ascii_bytes("The quick brown fox jumps over the lazy dog"),
        "f7bc83f430538424b13298e6aa6fb143ef4d59a14946175997479dbc2d1a3cd8");
    vectors_ok &= check_mac(
        "block-key", block_key, ascii_bytes("block-sized key"),
        "c778b31e07b7ed445b7518ca555e0479e655ab70c89afbd255a28579056fbd0c");
    vectors_ok &= check_mac(
        "multi-block", multi_block_key, multi_block_input,
        "c5f290493a667c64fb5174d813dac47d98cb29061ba69952121857b473356afa");
    vectors_ok &= check_mac(
        "large", large_key, large_input,
        "0e79f3ff791e4c8fe6c2eb4126ebe1c71fad54d08f79fd7e5396b12a1f905d86");
    if (!vectors_ok)
    {
        return fail(4, "parity vector or input mutation");
    }

#ifdef ANOSECUREKIT_ENTERPRISE_BACKEND_ANOCRYPTO_C
    using anosecurekit_enterprise::providers::anocrypto_c::map_native_operation_status;
    using anosecurekit_enterprise::providers::anocrypto_c::native_operation_output_valid;

    std::array<std::uint8_t, ANO_CRYPTO_HASH_SHA256_DIGEST_SIZE> native_output{};
    native_output.fill(0xa5u);
    const std::array<std::uint8_t, 1> one{1};
    std::size_t written = 77;
    const auto invalid_status = ano_crypto_hmac_compute(
        ANO_CRYPTO_HASH_ALG_SHA256,
        nullptr,
        1,
        one.data(),
        one.size(),
        native_output.data(),
        native_output.size(),
        &written);
    if (map_native_operation_status(invalid_status)
            != backend_operation_status::invalid_argument
        || !std::all_of(native_output.begin(), native_output.end(),
                        [](std::uint8_t value) { return value == 0xa5u; }))
    {
        return fail(5, "invalid native argument mapping");
    }

    written = 77;
    const auto small_buffer_status = ano_crypto_hmac_compute(
        ANO_CRYPTO_HASH_ALG_SHA256,
        one.data(),
        one.size(),
        one.data(),
        one.size(),
        native_output.data(),
        native_output.size() - 1,
        &written);
    if (map_native_operation_status(small_buffer_status)
            != backend_operation_status::buffer_too_small
        || written != 0
        || !std::all_of(native_output.begin(), native_output.end(),
                        [](std::uint8_t value) { return value == 0xa5u; })
        || native_operation_output_valid(small_buffer_status, written,
                                         native_output.size())
        || native_operation_output_valid(ANO_CRYPTO_OK, native_output.size() - 1,
                                         native_output.size())
        || native_operation_output_valid(static_cast<ano_crypto_status_t>(254),
                                         native_output.size(), native_output.size())
        || !native_operation_output_valid(ANO_CRYPTO_OK, native_output.size(),
                                          native_output.size()))
    {
        return fail(6, "native failure and exact-length handling");
    }

    shutdown_backend();
    const auto stopped = current_backend_runtime();
    if (stopped.module_state != backend_module_state::shutdown
        || stopped.capability_mask != capability_mask || backend_profile_ready()
        || !fails_as_backend_error([] { (void)anosecurekit::hmac_sha256({}, {}); }))
    {
        return fail(7, "post-shutdown gate");
    }
#else
    shutdown_backend();
#endif

    std::cout << "HMAC-SHA-256: PASS\n";
    return 0;
}
