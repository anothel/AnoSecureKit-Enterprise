// SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary
#include <anosecurekit/hash.hpp>
#include <anosecurekit/version.hpp>
#include <anosecurekit_enterprise/enterprise.hpp>
#include <anosecurekit_enterprise/provider_runtime.hpp>

#include <array>
#include <cstddef>
#include <string_view>

int main()
{
    if (anosecurekit::version() != std::string_view{"0.4.0"})
    {
        return 1;
    }
    if (anosecurekit_enterprise::enterprise_version() != std::string_view{"0.1.0"})
    {
        return 2;
    }
    if (anosecurekit_enterprise::backend_profile_name() != std::string_view{"openssl"})
    {
        return 3;
    }
    if (anosecurekit_enterprise::initialize_backend()
        != anosecurekit_enterprise::backend_runtime_status::ready)
    {
        return 4;
    }
    if (!anosecurekit_enterprise::backend_profile_ready())
    {
        return 5;
    }

    constexpr std::array<std::byte, 3> input{std::byte{'a'}, std::byte{'b'}, std::byte{'c'}};
    const auto digest = anosecurekit::sha256(input);
    if (digest.size() != 32)
    {
        return 6;
    }

    anosecurekit_enterprise::shutdown_backend();
    return 0;
}
