// SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary
#include "status_mapping.hpp"

static_assert(ANO_CRYPTO_OK == 0);
static_assert(ANO_CRYPTO_ERR_INVALID_ARGUMENT == 1);
static_assert(ANO_CRYPTO_ERR_BUFFER_TOO_SMALL == 2);
static_assert(ANO_CRYPTO_ERR_UNSUPPORTED_ALGORITHM == 3);
static_assert(ANO_CRYPTO_ERR_UNSUPPORTED_PARAMETER == 4);
static_assert(ANO_CRYPTO_ERR_SELF_TEST_FAILED == 5);
static_assert(ANO_CRYPTO_ERR_FATAL_STATE == 6);
static_assert(ANO_CRYPTO_ERR_NOT_INITIALIZED == 7);
static_assert(ANO_CRYPTO_ERR_NOT_APPROVED_IN_MODE == 8);
static_assert(ANO_CRYPTO_ERR_ENTROPY_SOURCE_FAILED == 9);
static_assert(ANO_CRYPTO_ERR_DRBG_RESEED_REQUIRED == 10);
static_assert(ANO_CRYPTO_ERR_AUTHENTICATION_FAILED == 11);
static_assert(ANO_CRYPTO_ERR_INTEGRITY_CHECK_FAILED == 12);
static_assert(ANO_CRYPTO_ERR_NOT_IMPLEMENTED == 13);
static_assert(ANO_CRYPTO_ERR_RESOURCE_EXHAUSTED == 14);
static_assert(ANO_CRYPTO_ERR_INTERNAL_ERROR == 255);

namespace anosecurekit_enterprise::providers::anocrypto_c
{

backend_operation_status map_native_operation_status(ano_crypto_status_t status) noexcept
{
    switch (status)
    {
    case ANO_CRYPTO_OK:
        return backend_operation_status::success;
    case ANO_CRYPTO_ERR_INVALID_ARGUMENT:
        return backend_operation_status::invalid_argument;
    case ANO_CRYPTO_ERR_BUFFER_TOO_SMALL:
        return backend_operation_status::buffer_too_small;
    case ANO_CRYPTO_ERR_UNSUPPORTED_ALGORITHM:
    case ANO_CRYPTO_ERR_UNSUPPORTED_PARAMETER:
    case ANO_CRYPTO_ERR_NOT_IMPLEMENTED:
        return backend_operation_status::unsupported;
    case ANO_CRYPTO_ERR_NOT_APPROVED_IN_MODE:
        return backend_operation_status::not_approved;
    case ANO_CRYPTO_ERR_SELF_TEST_FAILED:
    case ANO_CRYPTO_ERR_FATAL_STATE:
    case ANO_CRYPTO_ERR_NOT_INITIALIZED:
        return backend_operation_status::not_operational;
    case ANO_CRYPTO_ERR_ENTROPY_SOURCE_FAILED:
        return backend_operation_status::entropy_failure;
    case ANO_CRYPTO_ERR_DRBG_RESEED_REQUIRED:
        return backend_operation_status::reseed_required;
    case ANO_CRYPTO_ERR_AUTHENTICATION_FAILED:
        return backend_operation_status::authentication_failed;
    case ANO_CRYPTO_ERR_INTEGRITY_CHECK_FAILED:
        return backend_operation_status::integrity_failure;
    case ANO_CRYPTO_ERR_RESOURCE_EXHAUSTED:
        return backend_operation_status::resource_exhausted;
    case ANO_CRYPTO_ERR_INTERNAL_ERROR:
    default:
        return backend_operation_status::internal_error;
    }
}

bool native_operation_output_valid(ano_crypto_status_t status,
                                   std::size_t written,
                                   std::size_t expected) noexcept
{
    return map_native_operation_status(status) == backend_operation_status::success
        && written == expected;
}

} // namespace anosecurekit_enterprise::providers::anocrypto_c
