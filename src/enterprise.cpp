// SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary
#include "anosecurekit_enterprise/enterprise.hpp"

#include "anosecurekit/version.hpp"

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

bool backend_profile_ready() noexcept
{
#ifdef ANOSECUREKIT_ENTERPRISE_BACKEND_ANOCRYPTO_C
    return true;
#else
    return true;
#endif
}

bool anocrypto_backend_available() noexcept
{
    return backend_profile() == crypto_backend_profile::anocrypto_c;
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
