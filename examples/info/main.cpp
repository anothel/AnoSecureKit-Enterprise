// SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary
#include <iostream>
#include "anosecurekit_enterprise/enterprise.hpp"

int main()
{
    std::cout << anosecurekit_enterprise::edition() << " "
              << anosecurekit_enterprise::enterprise_version() << "\n";
    std::cout << "Product family: " << anosecurekit_enterprise::product_family() << "\n";
    std::cout << "Community base version: " << anosecurekit_enterprise::community_version() << "\n";
    std::cout << "Crypto backend profile: " << anosecurekit_enterprise::backend_profile_name() << "\n";
    const auto initialization = anosecurekit_enterprise::initialize_backend();
    const auto runtime = anosecurekit_enterprise::current_backend_runtime();
    std::cout << "Initialization: "
              << anosecurekit_enterprise::backend_runtime_status_name(initialization) << "\n";
    std::cout << "Profile ready: " << (anosecurekit_enterprise::backend_profile_ready() ? "yes" : "no") << "\n";
    std::cout << "Backend module: " << runtime.backend_name << "\n";
    std::cout << "Backend module version: " << runtime.module_version << "\n";
    std::cout << "Backend build identity: " << runtime.build_identity << "\n";
    std::cout << "Runtime status: "
              << anosecurekit_enterprise::backend_runtime_status_name(runtime.status) << "\n";
    std::cout << "Module state: "
              << anosecurekit_enterprise::backend_module_state_name(runtime.module_state) << "\n";
    std::cout << "Self-test status: "
              << anosecurekit_enterprise::backend_self_test_status_name(runtime.self_test_status) << "\n";
    std::cout << "Required capabilities:";
    for (const auto capability : anosecurekit_enterprise::required_backend_capabilities())
    {
        std::cout << ' ' << anosecurekit_enterprise::backend_capability_name(capability);
    }
    std::cout << "\n";
    std::cout << "Runtime capabilities:";
    for (const auto capability : anosecurekit_enterprise::required_backend_capabilities())
    {
        if (anosecurekit_enterprise::backend_capability_mask_has(runtime.capability_mask, capability))
        {
            std::cout << ' ' << anosecurekit_enterprise::backend_capability_name(capability);
        }
    }
    std::cout << "\n";
    std::cout << anosecurekit_enterprise::backend_boundary() << "\n";
    anosecurekit_enterprise::shutdown_backend();
    return 0;
}
