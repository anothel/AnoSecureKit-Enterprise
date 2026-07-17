// SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary
#include "anosecurekit_enterprise/enterprise.hpp"

#include "anosecurekit/error.hpp"
#include "anosecurekit/hash.hpp"
#include "anosecurekit/hex.hpp"

#ifdef ANOSECUREKIT_ENTERPRISE_BACKEND_ANOCRYPTO_C
#include "status_mapping.hpp"

#include <anocrypto/ac_hash.h>
#endif

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <iostream>
#include <span>
#include <string_view>
#include <utility>
#include <vector>

namespace
{
int fail(int code, std::string_view message)
{
    anosecurekit_enterprise::shutdown_backend();
    std::cerr << "SHA-256 test failure: " << message << '\n';
    return code;
}

bool check_digest(std::string_view name,
                  std::span<const std::byte> input,
                  std::string_view expected)
{
    const auto digest = anosecurekit::sha256(input);
    const auto actual = anosecurekit::hex_encode(std::span<const std::byte>{digest});
    std::cout << name << '=' << actual << '\n';
    return actual == expected;
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
} // namespace

int main()
{
    using namespace anosecurekit_enterprise;

#ifdef ANOSECUREKIT_ENTERPRISE_BACKEND_ANOCRYPTO_C
    constexpr auto capability_mask =
        backend_capability_bit(crypto_backend_capability::sha256)
        | backend_capability_bit(crypto_backend_capability::hmac_sha256)
        | backend_capability_bit(crypto_backend_capability::random);
    const auto initial = current_backend_runtime();
    if ((initial.module_state != backend_module_state::uninitialized
         && initial.module_state != backend_module_state::shutdown)
        || initial.capability_mask != capability_mask || backend_profile_ready()
        || !fails_as_backend_error(
            [] { (void)anosecurekit::sha256(std::span<const std::byte>{}); }))
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

    const std::array abc{std::byte{'a'}, std::byte{'b'}, std::byte{'c'}};
    const std::array binary{
        std::byte{0x00}, std::byte{0x01}, std::byte{0x00}, std::byte{0xff}};
    std::vector<std::byte> multi_block(257);
    for (std::size_t index = 0; index < multi_block.size(); ++index)
    {
        multi_block[index] = static_cast<std::byte>((index * 31 + 7) & 0xffu);
    }
    std::vector<std::byte> large(1024 * 1024);
    for (std::size_t index = 0; index < large.size(); ++index)
    {
        large[index] = static_cast<std::byte>((index * 131 + 17) & 0xffu);
    }

    if (!check_digest("empty", {},
                      "e3b0c44298fc1c149afbf4c8996fb924"
                      "27ae41e4649b934ca495991b7852b855")
        || !check_digest("abc", abc,
                         "ba7816bf8f01cfea414140de5dae2223"
                         "b00361a396177a9cb410ff61f20015ad")
        || !check_digest("binary", binary,
                         "35405bce5dc7cacedd9c4373e68d01b3"
                         "69da4b5da34ecf90d0db265416797f71")
        || !check_digest("multi-block", multi_block,
                         "442d170f22f13ae4fc17edbd88c498df"
                         "9072b962790944f588ffaeee2a9ec0eb")
        || !check_digest("large", large,
                         "ea53eb498f9b7dc054aae73924bf25c5"
                         "69604d2c20aa9016f0b8714a1c180c7b"))
    {
        return fail(4, "digest vector");
    }

#ifdef ANOSECUREKIT_ENTERPRISE_BACKEND_ANOCRYPTO_C
    using anosecurekit_enterprise::providers::anocrypto_c::map_native_operation_status;

    std::array<std::uint8_t, ANO_CRYPTO_HASH_SHA256_DIGEST_SIZE> native_output{};
    native_output.fill(0xa5u);
    std::size_t written = 77;
    const auto invalid_status = ano_crypto_hash_digest(
        ANO_CRYPTO_HASH_ALG_SHA256,
        nullptr,
        1,
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

    const std::array<std::uint8_t, 1> one{1};
    written = 77;
    const auto small_buffer_status = ano_crypto_hash_digest(
        ANO_CRYPTO_HASH_ALG_SHA256,
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
        || map_native_operation_status(static_cast<ano_crypto_status_t>(254))
            != backend_operation_status::internal_error)
    {
        return fail(6, "native failure output safety");
    }

    const std::array<std::byte, 1> one_byte{std::byte{1}};
    if (!fails_as_backend_error([&] {
               (void)anosecurekit::hkdf_sha256(one_byte, one_byte, one_byte, 32);
           }))
    {
        return fail(7, "unconnected hash services");
    }

    shutdown_backend();
    const auto stopped = current_backend_runtime();
    if (stopped.module_state != backend_module_state::shutdown
        || stopped.capability_mask != capability_mask || backend_profile_ready()
        || !fails_as_backend_error(
            [] { (void)anosecurekit::sha256(std::span<const std::byte>{}); }))
    {
        return fail(8, "post-shutdown gate");
    }
#else
    shutdown_backend();
#endif

    return 0;
}
