// SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary
#include "anosecurekit_enterprise/enterprise.hpp"

#include "anosecurekit/version.hpp"

namespace anosecurekit_enterprise
{

std::string_view product_family() noexcept
{
    return "AnoSecureKit";
}

std::string_view edition() noexcept
{
    return "AnoSecureKit Enterprise";
}

std::string_view community_version() noexcept
{
    return anosecurekit::version();
}

bool anocrypto_backend_available() noexcept
{
#ifdef ANOSECUREKIT_ENTERPRISE_HAS_ANOCRYPTO
    return true;
#else
    return false;
#endif
}

std::string_view backend_boundary() noexcept
{
#ifdef ANOSECUREKIT_ENTERPRISE_HAS_ANOCRYPTO
    return "AnoCrypto integration enabled by private Enterprise build configuration";
#else
    return "AnoCrypto is not included in this scaffold";
#endif
}

} // namespace anosecurekit_enterprise
