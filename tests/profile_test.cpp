// SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary
#include <cassert>

#include "anosecurekit_enterprise/enterprise.hpp"

int main()
{
    using namespace anosecurekit_enterprise;
    assert(enterprise_version() == "0.1.0");
    assert(community_version() == "0.4.0");
    assert(backend_profile() == crypto_backend_profile::openssl);
    assert(backend_profile_name() == "openssl");

    assert(initialize_backend() == backend_runtime_status::ready);
    const auto runtime = current_backend_runtime();
    assert(runtime.backend_name == "openssl");
    assert(runtime.status == backend_runtime_status::ready);
    assert(runtime.module_state == backend_module_state::operational);
    assert(runtime.self_test_status == backend_self_test_status::not_applicable);
    assert(!runtime.module_version.empty());
    assert(!runtime.build_identity.empty());
    assert(runtime.capability_mask == required_backend_capability_mask());

    assert(backend_profile_ready());
    assert(!anocrypto_backend_available());
    assert(required_backend_capabilities().size() == 7);
    for (const auto capability : required_backend_capabilities())
    {
        assert(backend_supports(capability));
        assert(!backend_capability_name(capability).empty());
    }

    assert(backend_runtime_status_name(runtime.status) == "ready");
    assert(backend_module_state_name(runtime.module_state) == "operational");
    assert(backend_self_test_status_name(runtime.self_test_status) == "not-applicable");
    shutdown_backend();
    return 0;
}
