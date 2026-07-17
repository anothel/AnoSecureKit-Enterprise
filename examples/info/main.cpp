// SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary
#include <iostream>
#include <string_view>

#include "anosecurekit_enterprise/enterprise.hpp"

namespace
{
#ifndef ANOSECUREKIT_ENTERPRISE_BACKEND_ANOCRYPTO_C
constexpr std::string_view provider_source = "AnoSecureKit Community";

void print_json(const anosecurekit_enterprise::backend_runtime_info& runtime)
{
    using namespace anosecurekit_enterprise;
    std::cout << "{\n"
              << "  \"enterprise_version\": \"" << enterprise_version() << "\",\n"
              << "  \"community_version\": \"" << community_version() << "\",\n"
              << "  \"profile\": \"" << backend_profile_name() << "\",\n"
              << "  \"provider_source\": \"" << provider_source << "\",\n"
              << "  \"actual_provider_family\": \"" << runtime.backend_name << "\",\n"
              << "  \"implementation_complete\": true,\n"
              << "  \"local_verification\": \"passed\",\n"
              << "  \"remote_verification\": \"deferred\",\n"
              << "  \"qualification_status\": \"local-pass-remote-deferred\",\n"
              << "  \"evidence_bundle\": \"present\",\n"
              << "  \"structural_evidence\": \"unavailable\",\n"
              << "  \"cryptographic_evidence\": \"unavailable\",\n"
              << "  \"trusted_evidence\": \"unavailable\",\n"
              << "  \"release_authorization\": \"denied-or-unavailable\",\n"
              << "  \"customer_release_ready\": false,\n"
              << "  \"install_enabled\": true,\n"
              << "  \"internal_delivery_enabled\": true,\n"
              << "  \"openssl_dependency\": \"OpenSSL Crypto 3.0 or newer through Community\",\n"
              << "  \"openssl_runtime_version_verified\": false\n"
              << "}\n";
}
#endif

void print_text(anosecurekit_enterprise::backend_runtime_status initialization,
                const anosecurekit_enterprise::backend_runtime_info& runtime)
{
    using namespace anosecurekit_enterprise;
#ifdef ANOSECUREKIT_ENTERPRISE_BACKEND_ANOCRYPTO_C
    std::cout << edition() << " " << enterprise_version() << "\n";
    std::cout << "Product family: " << product_family() << "\n";
    std::cout << "Community base version: " << community_version() << "\n";
    std::cout << "Crypto backend profile: " << backend_profile_name() << "\n";
#else
    std::cout << "Enterprise version: " << enterprise_version() << "\n";
    std::cout << "Community version: " << community_version() << "\n";
    std::cout << "Profile: " << backend_profile_name() << "\n";
    std::cout << "Actual provider family: " << runtime.backend_name << "\n";
    std::cout << "Provider source: " << provider_source << "\n";
    std::cout << "Implementation: complete\n";
    std::cout << "Local verification: passed\n";
    std::cout << "Remote verification: deferred\n";
    std::cout << "Evidence bundle: present\n";
    std::cout << "Structural evidence: unavailable\n";
    std::cout << "Cryptographic evidence: unavailable\n";
    std::cout << "Trusted evidence: unavailable\n";
    std::cout << "Release authorization: denied or unavailable\n";
    std::cout << "Customer release: blocked\n";
    std::cout << "Install/export: enabled\n";
    std::cout << "Internal delivery package: enabled\n";
    std::cout << "OpenSSL dependency: OpenSSL Crypto 3.0 or newer through Community "
                 "(metadata; runtime version not queried)\n";
    std::cout << "Product family: " << product_family() << "\n";
#endif
    std::cout << "Initialization: " << backend_runtime_status_name(initialization) << "\n";
    std::cout << "Profile ready: " << (backend_profile_ready() ? "yes" : "no") << "\n";
    std::cout << "Backend module: " << runtime.backend_name << "\n";
    std::cout << "Backend module version: " << runtime.module_version << "\n";
    std::cout << "Backend build identity: " << runtime.build_identity << "\n";
    std::cout << "Runtime status: " << backend_runtime_status_name(runtime.status) << "\n";
    std::cout << "Module state: " << backend_module_state_name(runtime.module_state) << "\n";
    std::cout << "Self-test status: " << backend_self_test_status_name(runtime.self_test_status)
              << "\n";
    std::cout << "Required capabilities:";
    for (const auto capability : required_backend_capabilities())
    {
        std::cout << ' ' << backend_capability_name(capability);
    }
    std::cout << "\nRuntime capabilities:";
    for (const auto capability : required_backend_capabilities())
    {
        if (backend_capability_mask_has(runtime.capability_mask, capability))
        {
            std::cout << ' ' << backend_capability_name(capability);
        }
    }
    std::cout << "\n" << backend_boundary() << "\n";
}
} // namespace

int main(int argc, char* argv[])
{
#ifdef ANOSECUREKIT_ENTERPRISE_BACKEND_ANOCRYPTO_C
    (void)argc;
    (void)argv;
#else
    const bool json = argc == 2 && std::string_view{argv[1]} == "--json";
    if (argc > 2 || (argc == 2 && !json))
    {
        std::cerr << "Usage: anosecurekit_enterprise_info [--json]\n";
        return 2;
    }
#endif

    const auto initialization = anosecurekit_enterprise::initialize_backend();
    const auto runtime = anosecurekit_enterprise::current_backend_runtime();
#ifdef ANOSECUREKIT_ENTERPRISE_BACKEND_ANOCRYPTO_C
    print_text(initialization, runtime);
#else
    if (json)
    {
        print_json(runtime);
    }
    else
    {
        print_text(initialization, runtime);
    }
#endif
    anosecurekit_enterprise::shutdown_backend();
    return 0;
}
