// SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary
#include "runtime_adapter.hpp"

#include "anosecurekit_enterprise/detail/provider_runtime_contract.hpp"

#include <anocrypto/ac_build.h>
#include <anocrypto/ac_selftest.h>
#include <anocrypto/ac_version.h>

#ifndef ANOSECUREKIT_ENTERPRISE_EXPECTED_ANOCRYPTO_C_RUNTIME_ID_VALUE
#error "Expected AnoCrypto-C runtime identity is required"
#endif

#ifndef ANOSECUREKIT_ENTERPRISE_EXPECTED_ANOCRYPTO_C_COMMIT_VALUE
#error "Expected AnoCrypto-C commit is required"
#endif

#ifndef ANOSECUREKIT_ENTERPRISE_ALLOW_UNKNOWN_ANOCRYPTO_C_COMMIT_VALUE
#define ANOSECUREKIT_ENTERPRISE_ALLOW_UNKNOWN_ANOCRYPTO_C_COMMIT_VALUE 0
#endif

static_assert(ANO_CRYPTO_BUILD_IDENTITY_ABI_VERSION == 1u);

namespace anosecurekit_enterprise::providers::anocrypto_c
{
namespace
{
std::string_view view_or_empty(const char* value) noexcept
{
    return value == nullptr ? std::string_view{} : std::string_view{value};
}

struct native_last_error_query
{
    backend_runtime_status query_status;
    ano_crypto_status_t status;
};

native_last_error_query query_native_last_error() noexcept
{
    ano_crypto_status_t status = ANO_CRYPTO_ERR_INTERNAL_ERROR;
    const auto query_status = ano_crypto_module_get_last_error(&status);
    return {map_native_lifecycle_status(query_status), status};
}

backend_runtime_status map_native_status_with_last_error(int status) noexcept
{
    const auto mapped = map_native_lifecycle_status(status);
    if (status != ANO_CRYPTO_ERR_FATAL_STATE)
    {
        return mapped;
    }

    const auto last_error = query_native_last_error();
    if (last_error.query_status != backend_runtime_status::ready)
    {
        return last_error.query_status;
    }
    if (last_error.status != ANO_CRYPTO_OK)
    {
        return map_native_lifecycle_status(last_error.status);
    }
    return mapped;
}

backend_runtime_status native_error_state_status() noexcept
{
    const auto last_error = query_native_last_error();
    if (last_error.query_status != backend_runtime_status::ready)
    {
        return last_error.query_status;
    }
    const auto mapped = map_native_lifecycle_status(last_error.status);
    return mapped == backend_runtime_status::ready ? backend_runtime_status::internal_error : mapped;
}

struct native_self_test_query
{
    backend_runtime_status query_status;
    backend_self_test_status status;
};

native_self_test_query query_native_self_test() noexcept
{
    ano_crypto_status_t status = ANO_CRYPTO_ERR_INTERNAL_ERROR;
    const auto query_status = ano_crypto_selftest_get_last_status(&status);
    if (query_status != ANO_CRYPTO_OK)
    {
        return {map_native_status_with_last_error(query_status),
                backend_self_test_status::failed};
    }

    switch (status)
    {
    case ANO_CRYPTO_OK:
        return {backend_runtime_status::ready, backend_self_test_status::passed};
    case ANO_CRYPTO_ERR_NOT_INITIALIZED:
        return {backend_runtime_status::ready, backend_self_test_status::not_run};
    case ANO_CRYPTO_ERR_SELF_TEST_FAILED:
    case ANO_CRYPTO_ERR_INTEGRITY_CHECK_FAILED:
    case ANO_CRYPTO_ERR_FATAL_STATE:
        return {backend_runtime_status::ready, backend_self_test_status::failed};
    default:
        return {backend_runtime_status::ready, backend_self_test_status::failed};
    }
}

constexpr bool allow_unknown_commit() noexcept
{
    return ANOSECUREKIT_ENTERPRISE_ALLOW_UNKNOWN_ANOCRYPTO_C_COMMIT_VALUE != 0;
}
} // namespace

backend_module_state map_native_module_state(int state) noexcept
{
    switch (state)
    {
    case ANO_CRYPTO_MODULE_STATE_UNINITIALIZED:
        return backend_module_state::uninitialized;
    case ANO_CRYPTO_MODULE_STATE_SELF_TEST_RUNNING:
        return backend_module_state::self_test_running;
    case ANO_CRYPTO_MODULE_STATE_OPERATIONAL:
        return backend_module_state::operational;
    case ANO_CRYPTO_MODULE_STATE_ERROR_STATE:
        return backend_module_state::error;
    case ANO_CRYPTO_MODULE_STATE_SHUTDOWN:
        return backend_module_state::shutdown;
    default:
        return backend_module_state::error;
    }
}

backend_runtime_status map_native_lifecycle_status(int status) noexcept
{
    switch (status)
    {
    case ANO_CRYPTO_OK:
        return backend_runtime_status::ready;
    case ANO_CRYPTO_ERR_SELF_TEST_FAILED:
        return backend_runtime_status::self_test_failed;
    case ANO_CRYPTO_ERR_INTEGRITY_CHECK_FAILED:
        return backend_runtime_status::initialization_failed;
    case ANO_CRYPTO_ERR_FATAL_STATE:
    case ANO_CRYPTO_ERR_NOT_INITIALIZED:
        return backend_runtime_status::not_operational;
    case ANO_CRYPTO_ERR_INTERNAL_ERROR:
        return backend_runtime_status::internal_error;
    case ANO_CRYPTO_ERR_INVALID_ARGUMENT:
    case ANO_CRYPTO_ERR_BUFFER_TOO_SMALL:
    case ANO_CRYPTO_ERR_UNSUPPORTED_ALGORITHM:
    case ANO_CRYPTO_ERR_UNSUPPORTED_PARAMETER:
    case ANO_CRYPTO_ERR_NOT_APPROVED_IN_MODE:
    case ANO_CRYPTO_ERR_ENTROPY_SOURCE_FAILED:
    case ANO_CRYPTO_ERR_DRBG_RESEED_REQUIRED:
    case ANO_CRYPTO_ERR_AUTHENTICATION_FAILED:
    case ANO_CRYPTO_ERR_NOT_IMPLEMENTED:
    case ANO_CRYPTO_ERR_RESOURCE_EXHAUSTED:
        return backend_runtime_status::initialization_failed;
    default:
        return backend_runtime_status::internal_error;
    }
}

native_state_query query_native_state() noexcept
{
    ano_crypto_module_state_t state = ANO_CRYPTO_MODULE_STATE_UNINITIALIZED;
    const auto status = ano_crypto_module_get_state(&state);
    if (status != ANO_CRYPTO_OK)
    {
        return {map_native_status_with_last_error(status), backend_module_state::error};
    }
    return {backend_runtime_status::ready, map_native_module_state(state)};
}

backend_runtime_status require_native_operational() noexcept
{
    return map_native_status_with_last_error(ano_crypto_module_require_operational());
}

native_identity_info query_native_identity() noexcept
{
    native_identity_info result{
        backend_runtime_status::internal_error,
        {},
        0,
        {},
        {},
        {},
        {},
        {},
        {},
        {},
        {},
    };

    const char* runtime_version = nullptr;
    auto status = ano_crypto_version_string(&runtime_version);
    if (status != ANO_CRYPTO_OK)
    {
        result.query_status = map_native_status_with_last_error(status);
        return result;
    }

    ano_crypto_build_identity_t identity{};
    status = ano_crypto_build_identity(&identity);
    if (status != ANO_CRYPTO_OK)
    {
        result.query_status = map_native_status_with_last_error(status);
        return result;
    }

    const char* fingerprint = nullptr;
    status = ano_crypto_build_fingerprint(&fingerprint);
    if (status != ANO_CRYPTO_OK)
    {
        result.query_status = map_native_status_with_last_error(status);
        return result;
    }

    result.query_status = backend_runtime_status::ready;
    result.runtime_version = view_or_empty(runtime_version);
    result.abi_version = identity.abi_version;
    result.product_name = view_or_empty(identity.product_name);
    result.identity_version = view_or_empty(identity.version);
    result.git_commit = view_or_empty(identity.git_commit);
    result.build_type = view_or_empty(identity.build_type);
    result.compiler = view_or_empty(identity.compiler);
    result.target = view_or_empty(identity.target);
    result.notes = view_or_empty(identity.notes);
    result.fingerprint = view_or_empty(fingerprint);
    return result;
}

bool native_identity_matches_expected(const native_identity_info& identity,
                                      std::string_view expected_runtime,
                                      std::string_view expected_commit,
                                      bool allow_unknown) noexcept
{
    if (identity.query_status != backend_runtime_status::ready
        || identity.runtime_version != expected_runtime || expected_runtime.empty()
        || identity.abi_version != ANO_CRYPTO_BUILD_IDENTITY_ABI_VERSION
        || identity.product_name.empty() || identity.identity_version.empty()
        || identity.git_commit.empty() || identity.build_type.empty() || identity.compiler.empty()
        || identity.target.empty() || identity.notes.empty() || identity.fingerprint.empty()
        || expected_commit.empty())
    {
        return false;
    }
    if (identity.git_commit == "unknown")
    {
        return allow_unknown;
    }
    return identity.git_commit == expected_commit;
}

backend_runtime_info snapshot_native_runtime() noexcept
{
    const auto state = query_native_state();
    auto self_test = query_native_self_test();
    const auto identity = query_native_identity();

    if (state.state == backend_module_state::self_test_running)
    {
        self_test.status = backend_self_test_status::running;
    }

    auto runtime_status = state.query_status;
    if (runtime_status == backend_runtime_status::ready)
    {
        switch (state.state)
        {
        case backend_module_state::operational:
            runtime_status = self_test.query_status;
            if (runtime_status == backend_runtime_status::ready
                && self_test.status != backend_self_test_status::passed)
            {
                runtime_status = backend_runtime_status::self_test_failed;
            }
            if (runtime_status == backend_runtime_status::ready)
            {
                runtime_status = require_native_operational();
            }
            if (runtime_status == backend_runtime_status::ready
                && !native_identity_matches_expected(
                    identity,
                    ANOSECUREKIT_ENTERPRISE_EXPECTED_ANOCRYPTO_C_RUNTIME_ID_VALUE,
                    ANOSECUREKIT_ENTERPRISE_EXPECTED_ANOCRYPTO_C_COMMIT_VALUE,
                    allow_unknown_commit()))
            {
                runtime_status = backend_runtime_status::initialization_failed;
            }
            break;
        case backend_module_state::error:
            runtime_status = native_error_state_status();
            break;
        case backend_module_state::unavailable:
        case backend_module_state::uninitialized:
        case backend_module_state::self_test_running:
        case backend_module_state::shutdown:
            runtime_status = backend_runtime_status::not_operational;
            break;
        }
    }

    return {
        "anocrypto-c",
        identity.runtime_version.empty() ? std::string_view{"unknown"} : identity.runtime_version,
        identity.fingerprint.empty() ? std::string_view{"unknown"} : identity.fingerprint,
        runtime_status,
        state.state,
        self_test.status,
        backend_capability_bit(crypto_backend_capability::sha256)
            | backend_capability_bit(crypto_backend_capability::hmac_sha256),
    };
}

backend_runtime_status initialize_native_runtime() noexcept
{
    const auto init_status = ano_crypto_module_init(nullptr);
    if (init_status != ANO_CRYPTO_OK)
    {
        const auto state = query_native_state();
        if (state.query_status == backend_runtime_status::ready
            && state.state == backend_module_state::error)
        {
            return native_error_state_status();
        }
        return map_native_status_with_last_error(init_status);
    }

    const auto self_test = query_native_self_test();
    if (self_test.query_status != backend_runtime_status::ready)
    {
        return self_test.query_status;
    }
    if (self_test.status != backend_self_test_status::passed)
    {
        return backend_runtime_status::self_test_failed;
    }

    const auto state = query_native_state();
    if (state.query_status != backend_runtime_status::ready)
    {
        return state.query_status;
    }
    if (state.state == backend_module_state::error)
    {
        return native_error_state_status();
    }
    if (state.state != backend_module_state::operational)
    {
        return backend_runtime_status::not_operational;
    }

    const auto gate_status = require_native_operational();
    if (gate_status != backend_runtime_status::ready)
    {
        return gate_status;
    }

    const auto identity = query_native_identity();
    if (!native_identity_matches_expected(
            identity,
            ANOSECUREKIT_ENTERPRISE_EXPECTED_ANOCRYPTO_C_RUNTIME_ID_VALUE,
            ANOSECUREKIT_ENTERPRISE_EXPECTED_ANOCRYPTO_C_COMMIT_VALUE,
            allow_unknown_commit()))
    {
        return identity.query_status == backend_runtime_status::ready
            ? backend_runtime_status::initialization_failed
            : identity.query_status;
    }
    return backend_runtime_status::ready;
}

backend_runtime_status shutdown_native_runtime() noexcept
{
    return map_native_status_with_last_error(ano_crypto_module_shutdown());
}

bool native_lifecycle_ready(const backend_runtime_info& runtime) noexcept
{
    return runtime.status == backend_runtime_status::ready
        && runtime.module_state == backend_module_state::operational
        && runtime.self_test_status == backend_self_test_status::passed;
}

} // namespace anosecurekit_enterprise::providers::anocrypto_c

namespace anosecurekit_enterprise::detail
{
namespace
{
backend_runtime_status initialize() noexcept
{
    return providers::anocrypto_c::initialize_native_runtime();
}

void shutdown() noexcept
{
    (void)providers::anocrypto_c::shutdown_native_runtime();
}

backend_runtime_info snapshot() noexcept
{
    return providers::anocrypto_c::snapshot_native_runtime();
}

constexpr provider_runtime_api api{
    provider_runtime_contract_version,
    initialize,
    shutdown,
    snapshot,
};
} // namespace

const provider_runtime_api& selected_provider_runtime() noexcept { return api; }

} // namespace anosecurekit_enterprise::detail
