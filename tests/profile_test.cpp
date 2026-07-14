// SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary
#include "anosecurekit_enterprise/enterprise.hpp"

int main()
{
    using namespace anosecurekit_enterprise;

    if (enterprise_version() != "0.1.0")
    {
        return 1;
    }
    if (community_version() != "0.4.0")
    {
        return 2;
    }
    if (backend_profile() != crypto_backend_profile::openssl || backend_profile_name() != "openssl")
    {
        return 3;
    }
    if (initialize_backend() != backend_runtime_status::ready)
    {
        return 4;
    }

    const auto runtime = current_backend_runtime();
    if (runtime.backend_name != "openssl" || runtime.status != backend_runtime_status::ready)
    {
        shutdown_backend();
        return 5;
    }
    if (runtime.module_state != backend_module_state::operational
        || runtime.self_test_status != backend_self_test_status::not_applicable)
    {
        shutdown_backend();
        return 6;
    }
    if (runtime.module_version.empty() || runtime.build_identity.empty())
    {
        shutdown_backend();
        return 7;
    }
    if (runtime.capability_mask != required_backend_capability_mask())
    {
        shutdown_backend();
        return 8;
    }
    if (!backend_profile_ready() || anocrypto_backend_available())
    {
        shutdown_backend();
        return 9;
    }

    const auto capabilities = required_backend_capabilities();
    if (capabilities.size() != 7)
    {
        shutdown_backend();
        return 10;
    }
    for (const auto capability : capabilities)
    {
        if (!backend_supports(capability) || backend_capability_name(capability).empty())
        {
            shutdown_backend();
            return 11;
        }
    }

    if (backend_runtime_status_name(runtime.status) != "ready"
        || backend_module_state_name(runtime.module_state) != "operational"
        || backend_self_test_status_name(runtime.self_test_status) != "not-applicable")
    {
        shutdown_backend();
        return 12;
    }

    if (backend_module_state_name(backend_module_state::unavailable) != "unavailable"
        || backend_module_state_name(backend_module_state::uninitialized) != "uninitialized"
        || backend_module_state_name(backend_module_state::self_test_running) != "self-test-running"
        || backend_module_state_name(backend_module_state::operational) != "operational"
        || backend_module_state_name(backend_module_state::error) != "error"
        || backend_module_state_name(backend_module_state::shutdown) != "shutdown")
    {
        shutdown_backend();
        return 13;
    }

    if (backend_operation_status_name(backend_operation_status::success) != "success"
        || backend_operation_status_name(backend_operation_status::invalid_argument) != "invalid-argument"
        || backend_operation_status_name(backend_operation_status::buffer_too_small) != "buffer-too-small"
        || backend_operation_status_name(backend_operation_status::unsupported) != "unsupported"
        || backend_operation_status_name(backend_operation_status::not_approved) != "not-approved"
        || backend_operation_status_name(backend_operation_status::not_operational) != "not-operational"
        || backend_operation_status_name(backend_operation_status::entropy_failure) != "entropy-failure"
        || backend_operation_status_name(backend_operation_status::reseed_required) != "reseed-required"
        || backend_operation_status_name(backend_operation_status::authentication_failed) != "authentication-failed"
        || backend_operation_status_name(backend_operation_status::integrity_failure) != "integrity-failure"
        || backend_operation_status_name(backend_operation_status::resource_exhausted) != "resource-exhausted"
        || backend_operation_status_name(backend_operation_status::internal_error) != "internal-error"
        || backend_operation_status_name(static_cast<backend_operation_status>(-1)) != "unknown")
    {
        shutdown_backend();
        return 14;
    }

    shutdown_backend();
    return 0;
}
