// SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary
#include "runtime_adapter.hpp"
#include "status_mapping.hpp"

#include "backend/crypto_backend.hpp"

#include "anosecurekit/error.hpp"

#include <anocrypto/ac_hash.h>
#include <anocrypto/ac_hmac.h>

#include <cstdint>

static_assert(ANO_CRYPTO_HASH_ALG_SHA256 == 1);
static_assert(ANO_CRYPTO_HASH_SHA256_DIGEST_SIZE == 32u);

namespace anosecurekit::detail::crypto_backend
{
namespace
{
[[noreturn]] void throw_sha256_failure()
{
    throw error(error_code::backend_failure, "AnoCrypto-C SHA-256 operation failed");
}

[[noreturn]] void throw_hmac_sha256_failure()
{
    throw error(error_code::backend_failure, "AnoCrypto-C HMAC-SHA-256 operation failed");
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

bytes random_bytes(std::size_t) { throw_unconnected_service(); }

key256 generate_key() { throw_unconnected_service(); }

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
