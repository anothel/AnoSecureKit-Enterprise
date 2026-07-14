// SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary
#ifndef ANOSECUREKIT_ENTERPRISE_DETAIL_PROVIDER_RUNTIME_CONTRACT_HPP_
#define ANOSECUREKIT_ENTERPRISE_DETAIL_PROVIDER_RUNTIME_CONTRACT_HPP_

#include "anosecurekit_enterprise/provider_runtime.hpp"

#include <cstdint>

namespace anosecurekit_enterprise::detail
{

inline constexpr std::uint32_t provider_runtime_contract_version = 1;

struct provider_runtime_api
{
    std::uint32_t contract_version;
    backend_runtime_status (*initialize)() noexcept;
    void (*shutdown)() noexcept;
    backend_runtime_info (*snapshot)() noexcept;
};

// Exactly one compile-time-selected provider implementation must define this
// symbol. Runtime plugin discovery is intentionally not supported.
const provider_runtime_api& selected_provider_runtime() noexcept;

} // namespace anosecurekit_enterprise::detail

#endif
