// SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary
#ifndef ANOSECUREKIT_ENTERPRISE_SRC_PROVIDERS_ANOCRYPTO_C_RUNTIME_ADAPTER_HPP_
#define ANOSECUREKIT_ENTERPRISE_SRC_PROVIDERS_ANOCRYPTO_C_RUNTIME_ADAPTER_HPP_

#include "anosecurekit_enterprise/provider_runtime.hpp"

#include <anocrypto/ac_module.h>
#include <anocrypto/ac_status.h>

#include <cstdint>
#include <string_view>

namespace anosecurekit_enterprise::providers::anocrypto_c
{

struct native_state_query
{
    backend_runtime_status query_status;
    backend_module_state state;
};

struct native_identity_info
{
    backend_runtime_status query_status;
    std::string_view runtime_version;
    std::uint32_t abi_version;
    std::string_view product_name;
    std::string_view identity_version;
    std::string_view git_commit;
    std::string_view build_type;
    std::string_view compiler;
    std::string_view target;
    std::string_view notes;
    std::string_view fingerprint;
};

backend_module_state map_native_module_state(int state) noexcept;
backend_runtime_status map_native_lifecycle_status(int status) noexcept;

backend_runtime_status initialize_native_runtime() noexcept;
backend_runtime_status shutdown_native_runtime() noexcept;
native_state_query query_native_state() noexcept;
backend_runtime_status require_native_operational() noexcept;
native_identity_info query_native_identity() noexcept;
bool native_identity_matches_expected(const native_identity_info& identity,
                                      std::string_view expected_runtime,
                                      std::string_view expected_commit,
                                      bool allow_unknown_commit) noexcept;
backend_runtime_info snapshot_native_runtime() noexcept;
bool native_lifecycle_ready(const backend_runtime_info& runtime) noexcept;

} // namespace anosecurekit_enterprise::providers::anocrypto_c

#endif
