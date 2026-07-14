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
    assert(backend_profile_ready());
    assert(!anocrypto_backend_available());
    assert(required_backend_capabilities().size() == 7);
    for (const auto capability : required_backend_capabilities())
    {
        assert(backend_supports(capability));
        assert(!backend_capability_name(capability).empty());
    }
    return 0;
}
