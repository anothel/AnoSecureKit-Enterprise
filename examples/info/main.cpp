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
    std::cout << "Profile ready: " << (anosecurekit_enterprise::backend_profile_ready() ? "yes" : "no") << "\n";
    std::cout << anosecurekit_enterprise::backend_boundary() << "\n";
    return 0;
}
