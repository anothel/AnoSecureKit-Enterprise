// SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary
#ifndef ANOSECUREKIT_ENTERPRISE_PROVIDER_RUNTIME_HPP_
#define ANOSECUREKIT_ENTERPRISE_PROVIDER_RUNTIME_HPP_

#include <cstdint>
#include <string_view>

namespace anosecurekit_enterprise
{

enum class crypto_backend_capability : std::uint8_t
{
    sha256,
    hmac_sha256,
    hkdf_sha256,
    random,
    scrypt,
    aes256_gcm,
    aes256_gcm_stream,
};

using crypto_backend_capability_mask = std::uint64_t;

constexpr crypto_backend_capability_mask backend_capability_bit(
    crypto_backend_capability capability) noexcept
{
    return crypto_backend_capability_mask{1}
        << static_cast<unsigned int>(capability);
}

constexpr bool backend_capability_mask_has(crypto_backend_capability_mask mask,
                                           crypto_backend_capability capability) noexcept
{
    return (mask & backend_capability_bit(capability)) != 0;
}

enum class backend_runtime_status
{
    unavailable,
    ready,
    initialization_failed,
    self_test_failed,
    not_operational,
    internal_error,
};

enum class backend_module_state
{
    unavailable,
    uninitialized,
    self_test_running,
    operational,
    error,
    shutdown,
};

enum class backend_operation_status
{
    success,
    invalid_argument,
    buffer_too_small,
    unsupported,
    not_approved,
    not_operational,
    entropy_failure,
    reseed_required,
    authentication_failed,
    integrity_failure,
    resource_exhausted,
    internal_error,
};

enum class backend_self_test_status
{
    unavailable,
    not_applicable,
    not_run,
    running,
    passed,
    failed,
};

struct backend_runtime_info
{
    std::string_view backend_name;
    std::string_view module_version;
    std::string_view build_identity;
    backend_runtime_status status;
    backend_module_state module_state;
    backend_self_test_status self_test_status;
    crypto_backend_capability_mask capability_mask;
};

backend_runtime_status initialize_backend() noexcept;
void shutdown_backend() noexcept;
backend_runtime_info current_backend_runtime() noexcept;

std::string_view backend_runtime_status_name(backend_runtime_status status) noexcept;
std::string_view backend_module_state_name(backend_module_state state) noexcept;
std::string_view backend_self_test_status_name(backend_self_test_status status) noexcept;
std::string_view backend_operation_status_name(backend_operation_status status) noexcept;

} // namespace anosecurekit_enterprise

#endif
