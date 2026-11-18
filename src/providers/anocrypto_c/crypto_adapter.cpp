// SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary
#include "random_adapter.hpp"
#include "provider_gate.hpp"
#include "status_mapping.hpp"

#include "backend/crypto_backend.hpp"
#include "internal/secure_wipe.hpp"

#include "anosecurekit/error.hpp"

#include <anocrypto/ac_aead.h>
#include <anocrypto/ac_hash.h>
#include <anocrypto/ac_hmac.h>
#include <anocrypto/ac_kdf.h>
#include <anocrypto/ac_key.h>
#include <anocrypto/ac_module.h>

#include <array>
#include <cstdint>
#include <cstdlib>
#include <memory>
#include <span>
#include <string>
#include <string_view>
#include <utility>

static_assert(ANO_CRYPTO_HASH_ALG_SHA256 == 1);
static_assert(ANO_CRYPTO_HASH_SHA256_DIGEST_SIZE == 32u);
static_assert(ANO_CRYPTO_RANDOM_MAX_REQUEST_SIZE == 65536u);
static_assert(ANO_CRYPTO_HKDF_SHA256_HASH_SIZE == 32u);
static_assert(ANO_CRYPTO_HKDF_SHA256_MAX_OUTPUT_SIZE == 8160u);
static_assert(ANO_CRYPTO_AES256_GCM_KEY_SIZE == 32u);
static_assert(ANO_CRYPTO_AES256_GCM_NONCE_SIZE == 12u);
static_assert(ANO_CRYPTO_AES256_GCM_TAG_SIZE == 16u);
static_assert(ANO_CRYPTO_SCRYPT_N == 32768u);
static_assert(ANO_CRYPTO_SCRYPT_R == 8u);
static_assert(ANO_CRYPTO_SCRYPT_P == 1u);
static_assert(ANO_CRYPTO_SCRYPT_DERIVED_KEY_SIZE == 32u);
static_assert(ANO_CRYPTO_SCRYPT_WORKSPACE_SIZE <= ANO_CRYPTO_SCRYPT_MAX_MEMORY_SIZE);
static_assert(ANO_CRYPTO_SCRYPT_MAX_MEMORY_SIZE == 64u * 1024u * 1024u);

namespace anosecurekit::detail::crypto_backend
{
namespace
{
using anosecurekit_enterprise::backend_operation_status;
using anosecurekit_enterprise::providers::anocrypto_c::map_native_operation_status;
using anosecurekit_enterprise::providers::anocrypto_c::native_operation_output_valid;

constexpr anosecurekit_enterprise::providers::anocrypto_c::public_random_api random_api{
    ano_crypto_random_is_available, ano_crypto_random_context_size, ano_crypto_random_init,
    ano_crypto_random_generate,     ano_crypto_random_uninit,
};

const std::uint8_t* native_data(std::span<const std::byte> input) noexcept
{
    return input.empty() ? nullptr : reinterpret_cast<const std::uint8_t*>(input.data());
}

std::uint8_t* native_data(std::span<std::byte> output) noexcept
{
    return output.empty() ? nullptr : reinterpret_cast<std::uint8_t*>(output.data());
}

[[noreturn]] void throw_native_failure(ano_crypto_status_t status, std::string_view operation)
{
    const auto mapped = map_native_operation_status(status);
    if (mapped == backend_operation_status::authentication_failed)
    {
        throw error(error_code::authentication_failed, "File authentication failed");
    }
    if (mapped == backend_operation_status::invalid_argument || mapped == backend_operation_status::buffer_too_small ||
        mapped == backend_operation_status::unsupported)
    {
        throw error(error_code::invalid_input, std::string{operation} + " rejected the supplied input");
    }
    const auto* native_name = ano_crypto_status_name(status);
    throw error(error_code::backend_failure,
                std::string{operation} + " failed: " + (native_name == nullptr ? "unknown" : native_name));
}

void require_operational(std::string_view operation)
{
    const auto status = anosecurekit_enterprise::providers::anocrypto_c::require_validated_provider();
    if (map_native_operation_status(status) != backend_operation_status::success)
    {
        throw_native_failure(status, operation);
    }
}

class native_key_handle
{
  public:
    explicit native_key_handle(const key256& key)
    {
        const auto status = ano_crypto_key_import_secret(ANO_CRYPTO_KEY_TYPE_BLOCK_CIPHER,
                                                         reinterpret_cast<const std::uint8_t*>(key.data()), key.size(),
                                                         ANO_CRYPTO_KEY_FLAG_NONE, &handle_);
        if (map_native_operation_status(status) != backend_operation_status::success)
        {
            handle_ = ANO_CRYPTO_CSP_INVALID_HANDLE;
            throw_native_failure(status, "AnoCrypto-C AES-256 key import");
        }
    }

    native_key_handle(const native_key_handle&) = delete;
    native_key_handle& operator=(const native_key_handle&) = delete;

    ~native_key_handle()
    {
        if (handle_ != ANO_CRYPTO_CSP_INVALID_HANDLE)
        {
            (void)ano_crypto_key_destroy(handle_);
        }
    }

    ano_crypto_csp_handle_t get() const noexcept
    {
        return handle_;
    }

  private:
    ano_crypto_csp_handle_t handle_ = ANO_CRYPTO_CSP_INVALID_HANDLE;
};

class native_workspace
{
  public:
    explicit native_workspace(std::size_t size) : size_(size), data_(std::malloc(size))
    {
        if (data_ == nullptr)
        {
            throw error(error_code::backend_failure, "AnoCrypto-C scrypt workspace allocation failed");
        }
    }

    native_workspace(const native_workspace&) = delete;
    native_workspace& operator=(const native_workspace&) = delete;

    ~native_workspace()
    {
        if (data_ != nullptr)
        {
            internal::secure_wipe(std::span<std::byte>{static_cast<std::byte*>(data_), size_});
            std::free(data_);
        }
    }

    void* data() noexcept
    {
        return data_;
    }
    std::size_t size() const noexcept
    {
        return size_;
    }

  private:
    std::size_t size_{};
    void* data_{};
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
    const auto* native_name = ano_crypto_status_name(status);
    throw error(error_code::backend_failure, std::string{"AnoCrypto-C random operation failed: "} +
                                                 (native_name == nullptr ? "unknown" : native_name));
}

void fill_native_random(std::span<std::byte> output)
{
    if (output.empty())
    {
        return;
    }
    if (anosecurekit_enterprise::providers::anocrypto_c::require_validated_provider() != ANO_CRYPTO_OK)
    {
        internal::secure_wipe(output);
        throw_random_failure(ANO_CRYPTO_ERR_NOT_INITIALIZED);
    }

    try
    {
        const auto status = anosecurekit_enterprise::providers::anocrypto_c::fill_random_output(output, random_api);
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

} // namespace

digest256 sha256(std::span<const std::byte> input)
{
    require_operational("AnoCrypto-C SHA-256 operation");

    digest256 output{};
    std::size_t written = 0;
    const auto native_status =
        ano_crypto_hash_digest(ANO_CRYPTO_HASH_ALG_SHA256, native_data(input), input.size(),
                               reinterpret_cast<std::uint8_t*>(output.data()), output.size(), &written);
    if (!native_operation_output_valid(native_status, written, output.size()))
    {
        throw_sha256_failure();
    }
    return output;
}

digest256 hmac_sha256(std::span<const std::byte> key, std::span<const std::byte> input)
{
    require_operational("AnoCrypto-C HMAC-SHA-256 operation");

    digest256 output{};
    std::size_t written = 0;
    const auto native_status =
        ano_crypto_hmac_compute(ANO_CRYPTO_HASH_ALG_SHA256, native_data(key), key.size(), native_data(input),
                                input.size(), reinterpret_cast<std::uint8_t*>(output.data()), output.size(), &written);
    if (!native_operation_output_valid(native_status, written, output.size()))
    {
        throw_hmac_sha256_failure();
    }
    return output;
}

bytes hkdf_sha256(std::span<const std::byte> key_material, std::span<const std::byte> salt,
                  std::span<const std::byte> info, std::size_t output_size)
{
    if (output_size > ANO_CRYPTO_HKDF_SHA256_MAX_OUTPUT_SIZE)
    {
        throw error(error_code::invalid_input, "HKDF-SHA-256 output exceeds the RFC 5869 limit");
    }
    require_operational("AnoCrypto-C HKDF-SHA-256 operation");

    bytes output(output_size);
    const auto status = ano_crypto_hkdf_sha256(native_data(key_material), key_material.size(), native_data(salt),
                                               salt.size(), native_data(info), info.size(),
                                               native_data(std::span<std::byte>{output}), output.size());
    if (map_native_operation_status(status) != backend_operation_status::success)
    {
        internal::secure_wipe(output);
        throw_native_failure(status, "AnoCrypto-C HKDF-SHA-256 operation");
    }
    return output;
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

key256 scrypt_key(std::span<const std::byte> password, std::span<const std::byte> salt, const ScryptParams& params)
{
    if (params.n != ANO_CRYPTO_SCRYPT_N || params.r != ANO_CRYPTO_SCRYPT_R || params.p != ANO_CRYPTO_SCRYPT_P ||
        params.max_memory != ANO_CRYPTO_SCRYPT_MAX_MEMORY_SIZE)
    {
        throw error(error_code::invalid_input, "scrypt parameters do not match the supported SKP1 v1 profile");
    }
    require_operational("AnoCrypto-C scrypt operation");

    native_workspace workspace(ANO_CRYPTO_SCRYPT_WORKSPACE_SIZE);
    key256 key{};
    const auto status =
        ano_crypto_scrypt_derive_key(native_data(password), password.size(), native_data(salt), salt.size(),
                                     workspace.data(), workspace.size(), reinterpret_cast<std::uint8_t*>(key.data()));
    if (map_native_operation_status(status) != backend_operation_status::success)
    {
        internal::secure_wipe(key);
        throw_native_failure(status, "AnoCrypto-C scrypt operation");
    }
    return key;
}

Aes256GcmResult aes256_gcm_encrypt(std::span<const std::byte> plaintext, const key256& key,
                                   std::span<const std::byte> nonce, std::span<const std::byte> aad)
{
    if (nonce.size() != ANO_CRYPTO_AES256_GCM_NONCE_SIZE)
    {
        throw error(error_code::invalid_input, "AES-256-GCM nonce must be 12 bytes");
    }
    require_operational("AnoCrypto-C AES-256-GCM encryption");
    native_key_handle key_handle(key);

    Aes256GcmResult output{};
    output.ciphertext.resize(plaintext.size());
    std::size_t written = 0;
    const auto status = ano_crypto_aes256_gcm_encrypt(
        key_handle.get(), native_data(nonce), nonce.size(), native_data(aad), aad.size(), native_data(plaintext),
        plaintext.size(), native_data(std::span<std::byte>{output.ciphertext}), output.ciphertext.size(), &written,
        reinterpret_cast<std::uint8_t*>(output.tag.data()), output.tag.size());
    if (!native_operation_output_valid(status, written, output.ciphertext.size()))
    {
        internal::secure_wipe(output.ciphertext);
        internal::secure_wipe(output.tag);
        throw_native_failure(status, "AnoCrypto-C AES-256-GCM encryption");
    }
    return output;
}

bytes aes256_gcm_decrypt(std::span<const std::byte> ciphertext, std::span<const std::byte> tag, const key256& key,
                         std::span<const std::byte> nonce, std::span<const std::byte> aad)
{
    if (nonce.size() != ANO_CRYPTO_AES256_GCM_NONCE_SIZE)
    {
        throw error(error_code::invalid_input, "AES-256-GCM nonce must be 12 bytes");
    }
    if (tag.size() != ANO_CRYPTO_AES256_GCM_TAG_SIZE)
    {
        throw error(error_code::invalid_input, "AES-256-GCM tag must be 16 bytes");
    }
    require_operational("AnoCrypto-C AES-256-GCM decryption");
    native_key_handle key_handle(key);

    bytes plaintext(ciphertext.size());
    std::size_t written = 0;
    const auto status =
        ano_crypto_aes256_gcm_decrypt(key_handle.get(), native_data(nonce), nonce.size(), native_data(aad), aad.size(),
                                      native_data(ciphertext), ciphertext.size(), native_data(tag), tag.size(),
                                      native_data(std::span<std::byte>{plaintext}), plaintext.size(), &written);
    if (!native_operation_output_valid(status, written, plaintext.size()))
    {
        internal::secure_wipe(plaintext);
        throw_native_failure(status, "AnoCrypto-C AES-256-GCM decryption");
    }
    return plaintext;
}

struct Aes256GcmEncryptContext::Impl
{
    explicit Impl(const key256& key, std::span<const std::byte> nonce)
    {
        if (nonce.size() != ANO_CRYPTO_AES256_GCM_NONCE_SIZE)
        {
            throw error(error_code::invalid_input, "AES-256-GCM nonce must be 12 bytes");
        }
        require_operational("AnoCrypto-C streaming AES-256-GCM initialization");

        auto status = ano_crypto_aes256_gcm_stream_context_size(&context_size);
        if (map_native_operation_status(status) != backend_operation_status::success || context_size == 0)
        {
            throw_native_failure(status == ANO_CRYPTO_OK ? ANO_CRYPTO_ERR_INTERNAL_ERROR : status,
                                 "AnoCrypto-C streaming AES-256-GCM context sizing");
        }
        context = std::malloc(context_size);
        if (context == nullptr)
        {
            throw error(error_code::backend_failure, "AnoCrypto-C streaming AES-256-GCM context allocation failed");
        }

        try
        {
            native_key_handle key_handle(key);
            status = ano_crypto_aes256_gcm_stream_init(context, context_size, ANO_CRYPTO_AEAD_DIRECTION_ENCRYPT,
                                                       key_handle.get(), native_data(nonce), nonce.size(),
                                                       ANO_CRYPTO_AES256_GCM_STREAM_FLAG_NONE);
            if (map_native_operation_status(status) != backend_operation_status::success)
            {
                throw_native_failure(status, "AnoCrypto-C streaming AES-256-GCM initialization");
            }
            active = true;
        }
        catch (...)
        {
            clear();
            throw;
        }
    }

    ~Impl()
    {
        clear();
    }

    void clear() noexcept
    {
        if (context != nullptr)
        {
            (void)ano_crypto_aes256_gcm_stream_uninit(context, context_size);
            internal::secure_wipe(std::span<std::byte>{static_cast<std::byte*>(context), context_size});
            std::free(context);
            context = nullptr;
            context_size = 0;
            active = false;
        }
    }

    void* context{};
    std::size_t context_size{};
    bool active{};
};

struct Aes256GcmDecryptContext::Impl
{
    explicit Impl(const key256& key, std::span<const std::byte> nonce)
    {
        if (nonce.size() != ANO_CRYPTO_AES256_GCM_NONCE_SIZE)
        {
            throw error(error_code::invalid_input, "AES-256-GCM nonce must be 12 bytes");
        }
        require_operational("AnoCrypto-C streaming AES-256-GCM initialization");

        auto status = ano_crypto_aes256_gcm_stream_context_size(&context_size);
        if (map_native_operation_status(status) != backend_operation_status::success || context_size == 0)
        {
            throw_native_failure(status == ANO_CRYPTO_OK ? ANO_CRYPTO_ERR_INTERNAL_ERROR : status,
                                 "AnoCrypto-C streaming AES-256-GCM context sizing");
        }
        context = std::malloc(context_size);
        if (context == nullptr)
        {
            throw error(error_code::backend_failure, "AnoCrypto-C streaming AES-256-GCM context allocation failed");
        }

        try
        {
            native_key_handle key_handle(key);
            status = ano_crypto_aes256_gcm_stream_init(context, context_size, ANO_CRYPTO_AEAD_DIRECTION_DECRYPT,
                                                       key_handle.get(), native_data(nonce), nonce.size(),
                                                       ANO_CRYPTO_AES256_GCM_STREAM_FLAG_NONE);
            if (map_native_operation_status(status) != backend_operation_status::success)
            {
                throw_native_failure(status, "AnoCrypto-C streaming AES-256-GCM initialization");
            }
            active = true;
        }
        catch (...)
        {
            clear();
            throw;
        }
    }

    ~Impl()
    {
        clear();
    }

    void clear() noexcept
    {
        if (context != nullptr)
        {
            (void)ano_crypto_aes256_gcm_stream_uninit(context, context_size);
            internal::secure_wipe(std::span<std::byte>{static_cast<std::byte*>(context), context_size});
            std::free(context);
            context = nullptr;
            context_size = 0;
            active = false;
        }
    }

    void* context{};
    std::size_t context_size{};
    bool active{};
};

Aes256GcmEncryptContext::Aes256GcmEncryptContext(const key256& key, std::span<const std::byte> nonce)
    : impl_(std::make_unique<Impl>(key, nonce))
{
}
Aes256GcmEncryptContext::~Aes256GcmEncryptContext() = default;
Aes256GcmEncryptContext::Aes256GcmEncryptContext(Aes256GcmEncryptContext&&) noexcept = default;
Aes256GcmEncryptContext& Aes256GcmEncryptContext::operator=(Aes256GcmEncryptContext&&) noexcept = default;
void Aes256GcmEncryptContext::update_aad(std::span<const std::byte> aad)
{
    if (impl_ == nullptr || !impl_->active)
    {
        throw error(error_code::invalid_input, "AES-256-GCM encrypt context has no active state");
    }
    require_operational("AnoCrypto-C streaming AES-256-GCM operation");
    const auto status = ano_crypto_aes256_gcm_stream_aad_update(impl_->context, native_data(aad), aad.size());
    if (map_native_operation_status(status) != backend_operation_status::success)
    {
        throw_native_failure(status, "AnoCrypto-C streaming AES-256-GCM AAD update");
    }
}
bytes Aes256GcmEncryptContext::update(std::span<const std::byte> plaintext)
{
    if (impl_ == nullptr || !impl_->active)
    {
        throw error(error_code::invalid_input, "AES-256-GCM encrypt context has no active state");
    }
    bytes ciphertext(plaintext.size());
    std::size_t written = 0;
    require_operational("AnoCrypto-C streaming AES-256-GCM operation");
    const auto status =
        ano_crypto_aes256_gcm_stream_update(impl_->context, native_data(plaintext), plaintext.size(),
                                            native_data(std::span<std::byte>{ciphertext}), ciphertext.size(), &written);
    if (!native_operation_output_valid(status, written, ciphertext.size()))
    {
        internal::secure_wipe(ciphertext);
        throw_native_failure(status, "AnoCrypto-C streaming AES-256-GCM encrypt update");
    }
    return ciphertext;
}
std::array<std::byte, 16> Aes256GcmEncryptContext::finalize()
{
    if (impl_ == nullptr || !impl_->active)
    {
        throw error(error_code::invalid_input, "AES-256-GCM encrypt context has no active state");
    }
    std::array<std::byte, ANO_CRYPTO_AES256_GCM_TAG_SIZE> tag{};
    require_operational("AnoCrypto-C streaming AES-256-GCM operation");
    const auto status = ano_crypto_aes256_gcm_stream_encrypt_final(
        impl_->context, reinterpret_cast<std::uint8_t*>(tag.data()), tag.size());
    impl_.reset();
    if (map_native_operation_status(status) != backend_operation_status::success)
    {
        internal::secure_wipe(tag);
        throw_native_failure(status, "AnoCrypto-C streaming AES-256-GCM encrypt final");
    }
    return tag;
}

Aes256GcmDecryptContext::Aes256GcmDecryptContext(const key256& key, std::span<const std::byte> nonce)
    : impl_(std::make_unique<Impl>(key, nonce))
{
}
Aes256GcmDecryptContext::~Aes256GcmDecryptContext() = default;
Aes256GcmDecryptContext::Aes256GcmDecryptContext(Aes256GcmDecryptContext&&) noexcept = default;
Aes256GcmDecryptContext& Aes256GcmDecryptContext::operator=(Aes256GcmDecryptContext&&) noexcept = default;
void Aes256GcmDecryptContext::update_aad(std::span<const std::byte> aad)
{
    if (impl_ == nullptr || !impl_->active)
    {
        throw error(error_code::invalid_input, "AES-256-GCM decrypt context has no active state");
    }
    require_operational("AnoCrypto-C streaming AES-256-GCM operation");
    const auto status = ano_crypto_aes256_gcm_stream_aad_update(impl_->context, native_data(aad), aad.size());
    if (map_native_operation_status(status) != backend_operation_status::success)
    {
        throw_native_failure(status, "AnoCrypto-C streaming AES-256-GCM AAD update");
    }
}
bytes Aes256GcmDecryptContext::update(std::span<const std::byte> ciphertext)
{
    if (impl_ == nullptr || !impl_->active)
    {
        throw error(error_code::invalid_input, "AES-256-GCM decrypt context has no active state");
    }
    bytes plaintext(ciphertext.size());
    std::size_t written = 0;
    require_operational("AnoCrypto-C streaming AES-256-GCM operation");
    const auto status =
        ano_crypto_aes256_gcm_stream_update(impl_->context, native_data(ciphertext), ciphertext.size(),
                                            native_data(std::span<std::byte>{plaintext}), plaintext.size(), &written);
    if (!native_operation_output_valid(status, written, plaintext.size()))
    {
        internal::secure_wipe(plaintext);
        throw_native_failure(status, "AnoCrypto-C streaming AES-256-GCM decrypt update");
    }
    return plaintext;
}
bytes Aes256GcmDecryptContext::finalize(std::span<const std::byte> tag)
{
    if (impl_ == nullptr || !impl_->active)
    {
        throw error(error_code::invalid_input, "AES-256-GCM decrypt context has no active state");
    }
    if (tag.size() != ANO_CRYPTO_AES256_GCM_TAG_SIZE)
    {
        throw error(error_code::invalid_input, "AES-256-GCM tag must be 16 bytes");
    }
    require_operational("AnoCrypto-C streaming AES-256-GCM operation");
    const auto status = ano_crypto_aes256_gcm_stream_decrypt_final(impl_->context, native_data(tag), tag.size());
    impl_.reset();
    if (map_native_operation_status(status) != backend_operation_status::success)
    {
        throw_native_failure(status, "AnoCrypto-C streaming AES-256-GCM decrypt final");
    }
    return {};
}

} // namespace anosecurekit::detail::crypto_backend
