// SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary
#ifndef ANOSECUREKIT_ENTERPRISE_ENTERPRISE_HPP_
#define ANOSECUREKIT_ENTERPRISE_ENTERPRISE_HPP_

#include "anosecurekit_enterprise/provider_runtime.hpp"

#include <span>
#include <string_view>

namespace anosecurekit_enterprise
{

enum class crypto_backend_profile
{
    openssl,
    anocrypto_c,
};

std::string_view product_family() noexcept;
std::string_view edition() noexcept;
std::string_view enterprise_version() noexcept;
std::string_view community_version() noexcept;
crypto_backend_profile backend_profile() noexcept;
std::string_view backend_profile_name() noexcept;
bool backend_profile_ready() noexcept;
bool anocrypto_backend_available() noexcept;
std::span<const crypto_backend_capability> required_backend_capabilities() noexcept;
crypto_backend_capability_mask required_backend_capability_mask() noexcept;
bool backend_supports(crypto_backend_capability capability) noexcept;
std::string_view backend_capability_name(crypto_backend_capability capability) noexcept;
std::string_view backend_boundary() noexcept;

} // namespace anosecurekit_enterprise

#endif
