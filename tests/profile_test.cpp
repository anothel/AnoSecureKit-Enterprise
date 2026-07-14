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

    shutdown_backend();
    return 0;
}
