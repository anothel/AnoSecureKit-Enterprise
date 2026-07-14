// SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary
#include "anosecurekit_enterprise/enterprise.hpp"

#include "anosecurekit/version.hpp"

#include <array>

namespace anosecurekit_enterprise
{
std::string_view product_family() noexcept { return "AnoSecureKit"; }
std::string_view edition() noexcept { return "AnoSecureKit Enterprise"; }
std::string_view enterprise_version() noexcept { return "0.1.0"; }
std::string_view community_version() noexcept { return anosecurekit::version(); }

crypto_backend_profile backend_profile() noexcept
{
#ifdef ANOSECUREKIT_ENTERPRISE_BACKEND_ANOCRYPTO_C
    return crypto_backend_profile::anocrypto_c;
#else
    return crypto_backend_profile::openssl;
#endif
}

std::string_view backend_profile_name() noexcept
{
    return backend_profile() == crypto_backend_profile::anocrypto_c ? "anocrypto-c" : "openssl";
}

namespace
{
constexpr std::array<crypto_backend_capability, 7> required_capabilities{
    crypto_backend_capability::sha256,
    crypto_backend_capability::hmac_sha256,
    crypto_backend_capability::hkdf_sha256,
    crypto_backend_capability::random,
    crypto_backend_capability::scrypt,
    crypto_backend_capability::aes256_gcm,
    crypto_backend_capability::aes256_gcm_stream,
};
constexpr crypto_backend_capability_mask required_capability_mask_value() noexcept
{
    crypto_backend_capability_mask mask = 0;
    for (const auto capability : required_capabilities)
    {
        mask |= backend_capability_bit(capability);
    }
    return mask;
}
} // namespace

bool backend_profile_ready() noexcept
{
    const auto runtime = current_backend_runtime();
    if (runtime.status != backend_runtime_status::ready
        || runtime.module_state != backend_module_state::operational
        || (runtime.capability_mask & required_capability_mask_value())
            != required_capability_mask_value())
    {
        return false;
    }
#ifdef ANOSECUREKIT_ENTERPRISE_BACKEND_ANOCRYPTO_C
    return runtime.self_test_status == backend_self_test_status::passed;
#else
    return runtime.self_test_status == backend_self_test_status::not_applicable
        || runtime.self_test_status == backend_self_test_status::passed;
#endif
}

bool anocrypto_backend_available() noexcept
{
    return backend_profile() == crypto_backend_profile::anocrypto_c && backend_profile_ready();
}

std::span<const crypto_backend_capability> required_backend_capabilities() noexcept
{
    return required_capabilities;
}

crypto_backend_capability_mask required_backend_capability_mask() noexcept
{
    return required_capability_mask_value();
}

bool backend_supports(crypto_backend_capability capability) noexcept
{
    if (!backend_profile_ready())
    {
        return false;
    }
    return backend_capability_mask_has(current_backend_runtime().capability_mask, capability);
}

std::string_view backend_capability_name(crypto_backend_capability capability) noexcept
{
    switch (capability)
    {
    case crypto_backend_capability::sha256:
        return "sha256";
    case crypto_backend_capability::hmac_sha256:
        return "hmac-sha256";
    case crypto_backend_capability::hkdf_sha256:
        return "hkdf-sha256";
    case crypto_backend_capability::random:
        return "random";
    case crypto_backend_capability::scrypt:
        return "scrypt";
    case crypto_backend_capability::aes256_gcm:
        return "aes256-gcm";
    case crypto_backend_capability::aes256_gcm_stream:
        return "aes256-gcm-stream";
    }
    return "unknown";
}

std::string_view backend_boundary() noexcept
{
#ifdef ANOSECUREKIT_ENTERPRISE_BACKEND_ANOCRYPTO_C
    return "AnoCrypto-C profile: external AnoCryptoC::AnoCryptoC plus Enterprise provider; no OpenSSL fallback";
#else
    return "OpenSSL profile: Community v0.4.0 OpenSSL provider plus Enterprise layer";
#endif
}
} // namespace anosecurekit_enterprise
