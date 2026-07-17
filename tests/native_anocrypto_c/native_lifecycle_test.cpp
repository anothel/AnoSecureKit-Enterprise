// SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary
#include "runtime_adapter.hpp"

#include "anosecurekit_enterprise/enterprise.hpp"
#include "anosecurekit_enterprise/provider_runtime.hpp"

#include <anocrypto/ac_build.h>

#include <iostream>
#include <string_view>

#ifndef ANOSECUREKIT_ENTERPRISE_EXPECTED_ANOCRYPTO_C_RUNTIME_ID_VALUE
#error "Expected AnoCrypto-C runtime identity is required"
#endif

#ifndef ANOSECUREKIT_ENTERPRISE_EXPECTED_ANOCRYPTO_C_COMMIT_VALUE
#error "Expected AnoCrypto-C commit is required"
#endif

#ifndef ANOSECUREKIT_ENTERPRISE_ALLOW_UNKNOWN_ANOCRYPTO_C_COMMIT_VALUE
#define ANOSECUREKIT_ENTERPRISE_ALLOW_UNKNOWN_ANOCRYPTO_C_COMMIT_VALUE 0
#endif

namespace anosecurekit
{
std::string_view version() noexcept { return "0.4.0"; }
} // namespace anosecurekit

namespace
{
int fail(int code, std::string_view message)
{
    (void)anosecurekit_enterprise::providers::anocrypto_c::shutdown_native_runtime();
    std::cerr << "native AnoCrypto-C lifecycle failure: " << message << '\n';
    return code;
}
} // namespace

int main()
{
    using namespace anosecurekit_enterprise;
    using namespace anosecurekit_enterprise::providers::anocrypto_c;
    constexpr auto capability_mask =
        backend_capability_bit(crypto_backend_capability::sha256)
        | backend_capability_bit(crypto_backend_capability::hmac_sha256)
        | backend_capability_bit(crypto_backend_capability::random);

    if (map_native_module_state(ANO_CRYPTO_MODULE_STATE_UNINITIALIZED)
            != backend_module_state::uninitialized
        || map_native_module_state(ANO_CRYPTO_MODULE_STATE_SELF_TEST_RUNNING)
            != backend_module_state::self_test_running
        || map_native_module_state(ANO_CRYPTO_MODULE_STATE_OPERATIONAL)
            != backend_module_state::operational
        || map_native_module_state(ANO_CRYPTO_MODULE_STATE_ERROR_STATE)
            != backend_module_state::error
        || map_native_module_state(ANO_CRYPTO_MODULE_STATE_SHUTDOWN)
            != backend_module_state::shutdown
        || map_native_module_state(-1) != backend_module_state::error)
    {
        return fail(1, "module state mapping");
    }

    if (map_native_lifecycle_status(ANO_CRYPTO_OK) != backend_runtime_status::ready
        || map_native_lifecycle_status(ANO_CRYPTO_ERR_NOT_INITIALIZED)
            != backend_runtime_status::not_operational
        || map_native_lifecycle_status(ANO_CRYPTO_ERR_SELF_TEST_FAILED)
            != backend_runtime_status::self_test_failed
        || map_native_lifecycle_status(ANO_CRYPTO_ERR_FATAL_STATE)
            != backend_runtime_status::not_operational
        || map_native_lifecycle_status(ANO_CRYPTO_ERR_INTEGRITY_CHECK_FAILED)
            != backend_runtime_status::initialization_failed
        || map_native_lifecycle_status(ANO_CRYPTO_ERR_INTERNAL_ERROR)
            != backend_runtime_status::internal_error
        || map_native_lifecycle_status(-1) != backend_runtime_status::internal_error)
    {
        return fail(2, "lifecycle status mapping");
    }

    const auto initial_state = query_native_state();
    if (initial_state.query_status != backend_runtime_status::ready
        || (initial_state.state != backend_module_state::uninitialized
            && initial_state.state != backend_module_state::shutdown))
    {
        return fail(3, "clean starting state");
    }
    if (require_native_operational() != backend_runtime_status::not_operational)
    {
        return fail(4, "pre-init operational gate");
    }
    auto runtime = current_backend_runtime();
    if (native_lifecycle_ready(runtime) || backend_profile_ready()
        || anocrypto_backend_available() || runtime.capability_mask != capability_mask)
    {
        return fail(5, "pre-init Enterprise snapshot");
    }

    if (initialize_backend() != backend_runtime_status::ready)
    {
        return fail(6, "initialization");
    }
    runtime = current_backend_runtime();
    if (runtime.status != backend_runtime_status::ready
        || runtime.module_state != backend_module_state::operational
        || runtime.self_test_status != backend_self_test_status::passed
        || !native_lifecycle_ready(runtime) || runtime.capability_mask != capability_mask
        || backend_profile_ready() || anocrypto_backend_available()
        || required_backend_capability_mask() == 0)
    {
        return fail(7, "operational Enterprise snapshot");
    }
    if (require_native_operational() != backend_runtime_status::ready)
    {
        return fail(8, "operational gate after init");
    }

    const auto identity = query_native_identity();
    constexpr bool allow_unknown_commit =
        ANOSECUREKIT_ENTERPRISE_ALLOW_UNKNOWN_ANOCRYPTO_C_COMMIT_VALUE != 0;
    if (!native_identity_matches_expected(
            identity,
            ANOSECUREKIT_ENTERPRISE_EXPECTED_ANOCRYPTO_C_RUNTIME_ID_VALUE,
            ANOSECUREKIT_ENTERPRISE_EXPECTED_ANOCRYPTO_C_COMMIT_VALUE,
            allow_unknown_commit)
        || identity.abi_version != ANO_CRYPTO_BUILD_IDENTITY_ABI_VERSION
        || identity.abi_version != 1
        || identity.product_name.empty()
        || identity.identity_version.empty()
        || identity.git_commit.empty()
        || identity.build_type.empty()
        || identity.compiler.empty()
        || identity.target.empty()
        || identity.notes.empty() || identity.fingerprint.empty()
        || runtime.module_version != identity.runtime_version
        || runtime.build_identity != identity.fingerprint)
    {
        return fail(9, "runtime/build identity");
    }

    auto mismatched_identity = identity;
    mismatched_identity.runtime_version = "mismatch";
    if (native_identity_matches_expected(
            mismatched_identity,
            ANOSECUREKIT_ENTERPRISE_EXPECTED_ANOCRYPTO_C_RUNTIME_ID_VALUE,
            ANOSECUREKIT_ENTERPRISE_EXPECTED_ANOCRYPTO_C_COMMIT_VALUE,
            true))
    {
        return fail(10, "runtime identity mismatch accepted");
    }

    auto missing_identity = identity;
    missing_identity.git_commit = {};
    if (native_identity_matches_expected(
            missing_identity,
            ANOSECUREKIT_ENTERPRISE_EXPECTED_ANOCRYPTO_C_RUNTIME_ID_VALUE,
            ANOSECUREKIT_ENTERPRISE_EXPECTED_ANOCRYPTO_C_COMMIT_VALUE,
            true))
    {
        return fail(11, "missing build identity accepted");
    }

    auto unknown_identity = identity;
    unknown_identity.git_commit = "unknown";
    if (native_identity_matches_expected(
            unknown_identity,
            ANOSECUREKIT_ENTERPRISE_EXPECTED_ANOCRYPTO_C_RUNTIME_ID_VALUE,
            ANOSECUREKIT_ENTERPRISE_EXPECTED_ANOCRYPTO_C_COMMIT_VALUE,
            false)
        || native_identity_matches_expected(
            unknown_identity,
            ANOSECUREKIT_ENTERPRISE_EXPECTED_ANOCRYPTO_C_RUNTIME_ID_VALUE,
            "unknown",
            false)
        || !native_identity_matches_expected(
            unknown_identity,
            ANOSECUREKIT_ENTERPRISE_EXPECTED_ANOCRYPTO_C_RUNTIME_ID_VALUE,
            ANOSECUREKIT_ENTERPRISE_EXPECTED_ANOCRYPTO_C_COMMIT_VALUE,
            true))
    {
        return fail(12, "unknown build identity override policy");
    }

    if (initialize_backend() != backend_runtime_status::ready
        || current_backend_runtime().module_state != backend_module_state::operational)
    {
        return fail(13, "repeated initialization");
    }

    if (shutdown_native_runtime() != backend_runtime_status::ready)
    {
        return fail(14, "shutdown");
    }
    runtime = current_backend_runtime();
    if (runtime.module_state != backend_module_state::shutdown
        || native_lifecycle_ready(runtime) || backend_profile_ready()
        || require_native_operational() != backend_runtime_status::not_operational)
    {
        return fail(15, "shutdown state");
    }

    if (initialize_backend() != backend_runtime_status::ready
        || current_backend_runtime().module_state != backend_module_state::operational)
    {
        return fail(16, "reinitialization after shutdown");
    }

    if (shutdown_native_runtime() != backend_runtime_status::ready
        || shutdown_native_runtime() != backend_runtime_status::ready
        || current_backend_runtime().module_state != backend_module_state::shutdown)
    {
        return fail(17, "repeated shutdown");
    }

    std::cout << "AnoCrypto-C native lifecycle: PASS\n"
              << "runtime_identity=" << identity.runtime_version << '\n'
              << "build_commit=" << identity.git_commit << '\n'
              << "build_fingerprint=" << identity.fingerprint << '\n'
              << "lifecycle_ready=yes\n"
              << "complete_profile_ready=no\n"
              << "capability_mask=sha256,hmac-sha256\n";
    return 0;
}
