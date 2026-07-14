// SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary
#include "anosecurekit_enterprise/detail/provider_runtime_contract.hpp"

namespace anosecurekit_enterprise::detail
{
namespace
{
backend_runtime_status initialize() noexcept { return backend_runtime_status::ready; }
void shutdown() noexcept {}

backend_runtime_info snapshot() noexcept
{
    return {
        "openssl",
        "Community v0.4.0 provider",
        "anosecurekit-community-v0.4.0",
        backend_runtime_status::ready,
        backend_module_state::operational,
        backend_self_test_status::not_applicable,
        backend_capability_bit(crypto_backend_capability::sha256)
            | backend_capability_bit(crypto_backend_capability::hmac_sha256)
            | backend_capability_bit(crypto_backend_capability::hkdf_sha256)
            | backend_capability_bit(crypto_backend_capability::random)
            | backend_capability_bit(crypto_backend_capability::scrypt)
            | backend_capability_bit(crypto_backend_capability::aes256_gcm)
            | backend_capability_bit(crypto_backend_capability::aes256_gcm_stream),
    };
}

constexpr provider_runtime_api api{
    provider_runtime_contract_version,
    initialize,
    shutdown,
    snapshot,
};
} // namespace

const provider_runtime_api& selected_provider_runtime() noexcept { return api; }

} // namespace anosecurekit_enterprise::detail
