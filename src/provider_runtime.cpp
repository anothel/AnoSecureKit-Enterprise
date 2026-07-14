// SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary
#include "anosecurekit_enterprise/provider_runtime.hpp"

#include "anosecurekit_enterprise/detail/provider_runtime_contract.hpp"

namespace anosecurekit_enterprise
{
namespace
{
const detail::provider_runtime_api& runtime_api() noexcept
{
    return detail::selected_provider_runtime();
}

bool runtime_contract_valid(const detail::provider_runtime_api& api) noexcept
{
    return api.contract_version == detail::provider_runtime_contract_version && api.initialize != nullptr
        && api.shutdown != nullptr && api.snapshot != nullptr;
}
} // namespace

backend_runtime_status initialize_backend() noexcept
{
    const auto& api = runtime_api();
    if (!runtime_contract_valid(api))
    {
        return backend_runtime_status::internal_error;
    }
    return api.initialize();
}

void shutdown_backend() noexcept
{
    const auto& api = runtime_api();
    if (runtime_contract_valid(api))
    {
        api.shutdown();
    }
}

backend_runtime_info current_backend_runtime() noexcept
{
    const auto& api = runtime_api();
    if (!runtime_contract_valid(api))
    {
        return {
            "invalid-provider-contract",
            "unknown",
            "unknown",
            backend_runtime_status::internal_error,
            backend_module_state::error,
            backend_self_test_status::failed,
            0,
        };
    }
    return api.snapshot();
}

std::string_view backend_runtime_status_name(backend_runtime_status status) noexcept
{
    switch (status)
    {
    case backend_runtime_status::unavailable:
        return "unavailable";
    case backend_runtime_status::ready:
        return "ready";
    case backend_runtime_status::initialization_failed:
        return "initialization-failed";
    case backend_runtime_status::self_test_failed:
        return "self-test-failed";
    case backend_runtime_status::not_operational:
        return "not-operational";
    case backend_runtime_status::internal_error:
        return "internal-error";
    }
    return "unknown";
}

std::string_view backend_module_state_name(backend_module_state state) noexcept
{
    switch (state)
    {
    case backend_module_state::unavailable:
        return "unavailable";
    case backend_module_state::uninitialized:
        return "uninitialized";
    case backend_module_state::self_test_running:
        return "self-test-running";
    case backend_module_state::operational:
        return "operational";
    case backend_module_state::error:
        return "error";
    case backend_module_state::shutdown:
        return "shutdown";
    }
    return "unknown";
}

std::string_view backend_self_test_status_name(backend_self_test_status status) noexcept
{
    switch (status)
    {
    case backend_self_test_status::unavailable:
        return "unavailable";
    case backend_self_test_status::not_applicable:
        return "not-applicable";
    case backend_self_test_status::not_run:
        return "not-run";
    case backend_self_test_status::running:
        return "running";
    case backend_self_test_status::passed:
        return "passed";
    case backend_self_test_status::failed:
        return "failed";
    }
    return "unknown";
}

std::string_view backend_operation_status_name(backend_operation_status status) noexcept
{
    switch (status)
    {
    case backend_operation_status::success:
        return "success";
    case backend_operation_status::invalid_argument:
        return "invalid-argument";
    case backend_operation_status::buffer_too_small:
        return "buffer-too-small";
    case backend_operation_status::unsupported:
        return "unsupported";
    case backend_operation_status::not_approved:
        return "not-approved";
    case backend_operation_status::not_operational:
        return "not-operational";
    case backend_operation_status::entropy_failure:
        return "entropy-failure";
    case backend_operation_status::reseed_required:
        return "reseed-required";
    case backend_operation_status::authentication_failed:
        return "authentication-failed";
    case backend_operation_status::integrity_failure:
        return "integrity-failure";
    case backend_operation_status::resource_exhausted:
        return "resource-exhausted";
    case backend_operation_status::internal_error:
        return "internal-error";
    }
    return "unknown";
}

} // namespace anosecurekit_enterprise
