// SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary
#include "native_runtime_adapter.hpp"

#include "anosecurekit_enterprise/detail/provider_runtime_contract.hpp"

#include <anocrypto/ac_build.h>
#include <anocrypto/ac_selftest.h>
#include <anocrypto/ac_version.h>

namespace anosecurekit_enterprise::native_anocrypto_c
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
        return {map_native_lifecycle_status(query_status), backend_self_test_status::failed};
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
        return {map_native_lifecycle_status(status), backend_module_state::error};
    }
    return {backend_runtime_status::ready, map_native_module_state(state)};
}

backend_runtime_status require_native_operational() noexcept
{
    return map_native_lifecycle_status(ano_crypto_module_require_operational());
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
        result.query_status = map_native_lifecycle_status(status);
        return result;
    }

    ano_crypto_build_identity_t identity{};
    status = ano_crypto_build_identity(&identity);
    if (status != ANO_CRYPTO_OK)
    {
        result.query_status = map_native_lifecycle_status(status);
        return result;
    }

    const char* fingerprint = nullptr;
    status = ano_crypto_build_fingerprint(&fingerprint);
    if (status != ANO_CRYPTO_OK)
    {
        result.query_status = map_native_lifecycle_status(status);
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

backend_runtime_info snapshot_native_runtime() noexcept
{
    const auto state = query_native_state();
    const auto last_error = query_native_last_error();
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
            runtime_status = self_test.query_status != backend_runtime_status::ready
                ? self_test.query_status
                : require_native_operational();
            if (runtime_status == backend_runtime_status::ready
                && self_test.status != backend_self_test_status::passed)
            {
                runtime_status = backend_runtime_status::self_test_failed;
            }
            break;
        case backend_module_state::error:
            runtime_status = last_error.query_status != backend_runtime_status::ready
                ? last_error.query_status
                : map_native_lifecycle_status(last_error.status);
            if (runtime_status == backend_runtime_status::ready)
            {
                runtime_status = backend_runtime_status::internal_error;
            }
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
        "anocrypto-c-native-lifecycle-test",
        identity.runtime_version.empty() ? std::string_view{"unknown"} : identity.runtime_version,
        identity.fingerprint.empty() ? std::string_view{"unknown"} : identity.fingerprint,
        runtime_status,
        state.state,
        self_test.status,
        0,
    };
}

backend_runtime_status initialize_native_runtime() noexcept
{
    const auto status = ano_crypto_module_init(nullptr);
    if (status != ANO_CRYPTO_OK)
    {
        const auto state = query_native_state();
        if (state.query_status == backend_runtime_status::ready
            && state.state == backend_module_state::error)
        {
            const auto last_error = query_native_last_error();
            if (last_error.query_status == backend_runtime_status::ready
                && last_error.status != ANO_CRYPTO_OK)
            {
                return map_native_lifecycle_status(last_error.status);
            }
        }
        return map_native_lifecycle_status(status);
    }
    return snapshot_native_runtime().status;
}

backend_runtime_status shutdown_native_runtime() noexcept
{
    return map_native_lifecycle_status(ano_crypto_module_shutdown());
}

bool native_lifecycle_profile_ready(const backend_runtime_info& runtime) noexcept
{
    return runtime.status == backend_runtime_status::ready
        && runtime.module_state == backend_module_state::operational
        && runtime.self_test_status == backend_self_test_status::passed;
}

} // namespace anosecurekit_enterprise::native_anocrypto_c

namespace anosecurekit_enterprise::detail
{
namespace
{
backend_runtime_status initialize() noexcept
{
    return native_anocrypto_c::initialize_native_runtime();
}

void shutdown() noexcept
{
    (void)native_anocrypto_c::shutdown_native_runtime();
}

backend_runtime_info snapshot() noexcept
{
    return native_anocrypto_c::snapshot_native_runtime();
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
