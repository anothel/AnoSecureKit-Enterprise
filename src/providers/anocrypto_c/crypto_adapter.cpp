// SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary
#include "runtime_adapter.hpp"
#include "random_adapter.hpp"
#include "status_mapping.hpp"

#include "backend/crypto_backend.hpp"
#include "internal/secure_wipe.hpp"

#include "anosecurekit/error.hpp"

#include <anocrypto/ac_hash.h>
#include <anocrypto/ac_hmac.h>

#include <algorithm>
#include <cstdint>
#include <string>

static_assert(ANO_CRYPTO_HASH_ALG_SHA256 == 1);
static_assert(ANO_CRYPTO_HASH_SHA256_DIGEST_SIZE == 32u);
static_assert(ANO_CRYPTO_RANDOM_MAX_REQUEST_SIZE == 65536u);

namespace anosecurekit_enterprise::providers::anocrypto_c
{

ano_crypto_status_t fill_random_output(std::span<std::byte> output,
                                       const public_random_api& api)
{
    if (output.empty())
    {
        return ANO_CRYPTO_OK;
    }

    const auto fail = [output](ano_crypto_status_t status) {
        anosecurekit::internal::secure_wipe(output);
        return status;
    };
    if (api.is_available() == 0)
    {
        return fail(ANO_CRYPTO_ERR_NOT_IMPLEMENTED);
    }

    std::size_t context_size = 0;
    auto status = api.context_size(&context_size);
    if (map_native_operation_status(status) != backend_operation_status::success)
    {
        return fail(status);
    }
    if (context_size == 0)
    {
        return fail(ANO_CRYPTO_ERR_INTERNAL_ERROR);
    }

    anosecurekit::bytes context(context_size);
    anosecurekit::internal::wipe_on_exit erase_context(context);
    status = api.init(context.data(),
                      context.size(),
                      nullptr,
                      0,
                      ANO_CRYPTO_RANDOM_FLAG_NONE);
    if (map_native_operation_status(status) != backend_operation_status::success)
    {
        (void)map_native_operation_status(api.uninit(context.data(), context.size()));
        return fail(status);
    }

    std::size_t offset = 0;
    while (offset < output.size())
    {
        const auto chunk_size = std::min(
            output.size() - offset,
            static_cast<std::size_t>(ANO_CRYPTO_RANDOM_MAX_REQUEST_SIZE));
        status = api.generate(
            context.data(),
            reinterpret_cast<std::uint8_t*>(output.data() + offset),
            chunk_size,
            nullptr,
            0,
            ANO_CRYPTO_RANDOM_FLAG_NONE);
        if (map_native_operation_status(status) != backend_operation_status::success)
        {
            break;
        }
        offset += chunk_size;
    }

    const auto uninit_status = api.uninit(context.data(), context.size());
    if (map_native_operation_status(status) == backend_operation_status::success)
    {
        status = uninit_status;
    }
    return map_native_operation_status(status) == backend_operation_status::success
        ? status
        : fail(status);
}

} // namespace anosecurekit_enterprise::providers::anocrypto_c

namespace anosecurekit::detail::crypto_backend
{
namespace
{
constexpr anosecurekit_enterprise::providers::anocrypto_c::public_random_api random_api{
    ano_crypto_random_is_available,
    ano_crypto_random_context_size,
    ano_crypto_random_init,
    ano_crypto_random_generate,
    ano_crypto_random_uninit,
};

[[noreturn]] void throw_sha256_failure()
{
    throw error(error_code::backend_failure, "AnoCrypto-C SHA-256 operation failed");
}

[[noreturn]] void throw_hmac_sha256_failure()
{
    throw error(error_code::backend_failure, "AnoCrypto-C HMAC-SHA-256 operation failed");
}

[[noreturn]] void throw_random_failure(ano_crypto_status_t status)
{
    using namespace anosecurekit_enterprise;
    using namespace anosecurekit_enterprise::providers::anocrypto_c;

    throw error(
        error_code::backend_failure,
        std::string{"AnoCrypto-C random operation failed: "}
            + std::string{backend_operation_status_name(map_native_operation_status(status))});
}

void fill_native_random(std::span<std::byte> output)
{
    using namespace anosecurekit_enterprise;
    using namespace anosecurekit_enterprise::providers::anocrypto_c;

    if (output.empty())
    {
        return;
    }
    if (require_native_operational() != backend_runtime_status::ready)
    {
        internal::secure_wipe(output);
        throw_random_failure(ANO_CRYPTO_ERR_NOT_INITIALIZED);
    }

    try
    {
        const auto status = fill_random_output(output, random_api);
        if (map_native_operation_status(status) != backend_operation_status::success)
        {
            throw_random_failure(status);
        }
    }
    catch (...)
    {
        internal::secure_wipe(output);
        throw;
    }
}

[[noreturn]] void throw_unconnected_service()
{
    throw error(error_code::backend_failure, "AnoCrypto-C service is not connected");
}
} // namespace

digest256 sha256(std::span<const std::byte> input)
{
    using namespace anosecurekit_enterprise;
    using namespace anosecurekit_enterprise::providers::anocrypto_c;

    if (require_native_operational() != backend_runtime_status::ready)
    {
        throw_sha256_failure();
    }

    digest256 output{};
    std::size_t written = 0;
    const auto* input_data = input.empty()
        ? nullptr
        : reinterpret_cast<const std::uint8_t*>(input.data());
    const auto native_status = ano_crypto_hash_digest(
        ANO_CRYPTO_HASH_ALG_SHA256,
        input_data,
        input.size(),
        reinterpret_cast<std::uint8_t*>(output.data()),
        output.size(),
        &written);
    if (!native_operation_output_valid(native_status, written, output.size()))
    {
        throw_sha256_failure();
    }
    return output;
}

digest256 hmac_sha256(std::span<const std::byte> key, std::span<const std::byte> input)
{
    using namespace anosecurekit_enterprise;
    using namespace anosecurekit_enterprise::providers::anocrypto_c;

    if (require_native_operational() != backend_runtime_status::ready)
    {
        throw_hmac_sha256_failure();
    }

    digest256 output{};
    std::size_t written = 0;
    const auto* key_data = key.empty()
        ? nullptr
        : reinterpret_cast<const std::uint8_t*>(key.data());
    const auto* input_data = input.empty()
        ? nullptr
        : reinterpret_cast<const std::uint8_t*>(input.data());
    const auto native_status = ano_crypto_hmac_compute(
        ANO_CRYPTO_HASH_ALG_SHA256,
        key_data,
        key.size(),
        input_data,
        input.size(),
        reinterpret_cast<std::uint8_t*>(output.data()),
        output.size(),
        &written);
    if (!native_operation_output_valid(native_status, written, output.size()))
    {
        throw_hmac_sha256_failure();
    }
    return output;
}

bytes hkdf_sha256(std::span<const std::byte>,
                  std::span<const std::byte>,
                  std::span<const std::byte>,
                  std::size_t)
{
    throw_unconnected_service();
}

bytes random_bytes(std::size_t size)
{
    bytes output(size);
    fill_native_random(output);
    return output;
}

key256 generate_key()
{
    key256 key{};
    fill_native_random(key);
    return key;
}

key256 scrypt_key(std::span<const std::byte>,
                  std::span<const std::byte>,
                  const ScryptParams&)
{
    throw_unconnected_service();
}

Aes256GcmResult aes256_gcm_encrypt(std::span<const std::byte>,
                                   const key256&,
                                   std::span<const std::byte>,
                                   std::span<const std::byte>)
{
    throw_unconnected_service();
}

bytes aes256_gcm_decrypt(std::span<const std::byte>,
                         std::span<const std::byte>,
                         const key256&,
                         std::span<const std::byte>,
                         std::span<const std::byte>)
{
    throw_unconnected_service();
}

struct Aes256GcmEncryptContext::Impl
{
};

Aes256GcmEncryptContext::Aes256GcmEncryptContext(const key256&,
                                                 std::span<const std::byte>)
{
    throw_unconnected_service();
}
Aes256GcmEncryptContext::~Aes256GcmEncryptContext() = default;
Aes256GcmEncryptContext::Aes256GcmEncryptContext(Aes256GcmEncryptContext&&) noexcept = default;
Aes256GcmEncryptContext& Aes256GcmEncryptContext::operator=(
    Aes256GcmEncryptContext&&) noexcept = default;
void Aes256GcmEncryptContext::update_aad(std::span<const std::byte>)
{
    throw_unconnected_service();
}
bytes Aes256GcmEncryptContext::update(std::span<const std::byte>)
{
    throw_unconnected_service();
}
std::array<std::byte, 16> Aes256GcmEncryptContext::finalize()
{
    throw_unconnected_service();
}

struct Aes256GcmDecryptContext::Impl
{
};

Aes256GcmDecryptContext::Aes256GcmDecryptContext(const key256&,
                                                 std::span<const std::byte>)
{
    throw_unconnected_service();
}
Aes256GcmDecryptContext::~Aes256GcmDecryptContext() = default;
Aes256GcmDecryptContext::Aes256GcmDecryptContext(Aes256GcmDecryptContext&&) noexcept = default;
Aes256GcmDecryptContext& Aes256GcmDecryptContext::operator=(
    Aes256GcmDecryptContext&&) noexcept = default;
void Aes256GcmDecryptContext::update_aad(std::span<const std::byte>)
{
    throw_unconnected_service();
}
bytes Aes256GcmDecryptContext::update(std::span<const std::byte>)
{
    throw_unconnected_service();
}
bytes Aes256GcmDecryptContext::finalize(std::span<const std::byte>)
{
    throw_unconnected_service();
}

} // namespace anosecurekit::detail::crypto_backend
