// SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary
#include <iostream>

#include "anosecurekit_enterprise/enterprise.hpp"

int main()
{
    std::cout << anosecurekit_enterprise::edition() << "\n";
    std::cout << "Product family: " << anosecurekit_enterprise::product_family() << "\n";
    std::cout << "Community base version: " << anosecurekit_enterprise::community_version() << "\n";
    std::cout << "AnoCrypto backend available: "
              << (anosecurekit_enterprise::anocrypto_backend_available() ? "yes" : "no") << "\n";
    std::cout << anosecurekit_enterprise::backend_boundary() << "\n";
    return 0;
}
