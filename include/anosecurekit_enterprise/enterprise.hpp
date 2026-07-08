// SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary
#ifndef ANOSECUREKIT_ENTERPRISE_ENTERPRISE_HPP_
#define ANOSECUREKIT_ENTERPRISE_ENTERPRISE_HPP_

#include <string_view>

namespace anosecurekit_enterprise
{

std::string_view product_family() noexcept;
std::string_view edition() noexcept;
std::string_view community_version() noexcept;
bool anocrypto_backend_available() noexcept;
std::string_view backend_boundary() noexcept;

} // namespace anosecurekit_enterprise

#endif // ANOSECUREKIT_ENTERPRISE_ENTERPRISE_HPP_
