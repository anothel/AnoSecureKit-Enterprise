// SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary
#pragma once
#include "identity_policy.hpp"
#include <anocrypto/ac_module.h>
#include <anocrypto/ac_selftest.h>
#include <anocrypto/ac_version.h>

#ifndef ANOSECUREKIT_ENTERPRISE_EXPECTED_ANOCRYPTO_C_RUNTIME_ID_VALUE
#error "Expected AnoCrypto-C runtime identity is required for primitive enforcement"
#endif
#ifndef ANOSECUREKIT_ENTERPRISE_EXPECTED_ANOCRYPTO_C_COMMIT_VALUE
#error "Expected AnoCrypto-C commit is required for primitive enforcement"
#endif
#ifndef ANOSECUREKIT_ENTERPRISE_ALLOW_UNKNOWN_ANOCRYPTO_C_COMMIT_VALUE
#define ANOSECUREKIT_ENTERPRISE_ALLOW_UNKNOWN_ANOCRYPTO_C_COMMIT_VALUE 0
#endif
namespace anosecurekit_enterprise::providers::anocrypto_c
{
// Stateless and provider-local: no reverse dependency on the Enterprise archive.
// Cleanup is deliberately ungated; zero-byte random remains a no-op.
inline ano_crypto_status_t require_validated_provider() noexcept
{
    const auto operational = ano_crypto_module_require_operational();
    if (operational != ANO_CRYPTO_OK) return operational;
    ano_crypto_status_t self_test = ANO_CRYPTO_ERR_INTERNAL_ERROR;
    if (ano_crypto_selftest_get_last_status(&self_test) != ANO_CRYPTO_OK || self_test != ANO_CRYPTO_OK)
        return ANO_CRYPTO_ERR_SELF_TEST_FAILED;
    const char* version = nullptr;
    const char* fingerprint = nullptr;
    ano_crypto_build_identity_t build{};
    if (ano_crypto_version_string(&version) != ANO_CRYPTO_OK ||
        ano_crypto_build_identity(&build) != ANO_CRYPTO_OK ||
        ano_crypto_build_fingerprint(&fingerprint) != ANO_CRYPTO_OK)
        return ANO_CRYPTO_ERR_INTERNAL_ERROR;
    const auto view = [](const char* value) { return value == nullptr ? std::string_view{} : std::string_view{value}; };
    const native_identity_info identity{
        backend_runtime_status::ready, view(version), build.abi_version,
        view(build.product_name), view(build.version), view(build.git_commit),
        view(build.build_type), view(build.compiler), view(build.target), view(build.notes), view(fingerprint)};
    return identity_matches_expected(identity,
        ANOSECUREKIT_ENTERPRISE_EXPECTED_ANOCRYPTO_C_RUNTIME_ID_VALUE,
        ANOSECUREKIT_ENTERPRISE_EXPECTED_ANOCRYPTO_C_COMMIT_VALUE,
        ANOSECUREKIT_ENTERPRISE_ALLOW_UNKNOWN_ANOCRYPTO_C_COMMIT_VALUE != 0)
        ? ANO_CRYPTO_OK : ANO_CRYPTO_ERR_NOT_INITIALIZED;
}
}
