// SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary
#pragma once
#include "anosecurekit_enterprise/provider_runtime.hpp"
#include <anocrypto/ac_build.h>
#include <string_view>
namespace anosecurekit_enterprise::providers::anocrypto_c
{
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

inline bool identity_matches_expected(const native_identity_info& identity, std::string_view expected_runtime,
                                      std::string_view expected_commit, bool allow_unknown) noexcept
{
    if (identity.query_status != backend_runtime_status::ready || identity.runtime_version != expected_runtime ||
        expected_runtime.empty() || identity.abi_version != ANO_CRYPTO_BUILD_IDENTITY_ABI_VERSION ||
        identity.product_name.empty() || identity.identity_version.empty() || identity.git_commit.empty() ||
        identity.build_type.empty() || identity.compiler.empty() || identity.target.empty() || identity.notes.empty() ||
        identity.fingerprint.empty() || expected_commit.empty())
    {
        return false;
    }
    if (identity.git_commit == "unknown")
    {
        return allow_unknown;
    }
    return identity.git_commit == expected_commit;
}

}
