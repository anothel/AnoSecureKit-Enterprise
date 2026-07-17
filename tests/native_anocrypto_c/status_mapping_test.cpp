// SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary
#include "status_mapping.hpp"

#include "anosecurekit_enterprise/provider_runtime.hpp"

#include <array>
#include <string_view>

namespace
{
using anosecurekit_enterprise::backend_operation_status;

struct mapping_case
{
    ano_crypto_status_t native_status;
    backend_operation_status enterprise_status;
};

constexpr std::array mappings{
    mapping_case{ANO_CRYPTO_OK, backend_operation_status::success},
    mapping_case{ANO_CRYPTO_ERR_INVALID_ARGUMENT, backend_operation_status::invalid_argument},
    mapping_case{ANO_CRYPTO_ERR_BUFFER_TOO_SMALL, backend_operation_status::buffer_too_small},
    mapping_case{ANO_CRYPTO_ERR_UNSUPPORTED_ALGORITHM, backend_operation_status::unsupported},
    mapping_case{ANO_CRYPTO_ERR_UNSUPPORTED_PARAMETER, backend_operation_status::unsupported},
    mapping_case{ANO_CRYPTO_ERR_SELF_TEST_FAILED, backend_operation_status::not_operational},
    mapping_case{ANO_CRYPTO_ERR_FATAL_STATE, backend_operation_status::not_operational},
    mapping_case{ANO_CRYPTO_ERR_NOT_INITIALIZED, backend_operation_status::not_operational},
    mapping_case{ANO_CRYPTO_ERR_NOT_APPROVED_IN_MODE, backend_operation_status::not_approved},
    mapping_case{ANO_CRYPTO_ERR_ENTROPY_SOURCE_FAILED, backend_operation_status::entropy_failure},
    mapping_case{ANO_CRYPTO_ERR_DRBG_RESEED_REQUIRED, backend_operation_status::reseed_required},
    mapping_case{ANO_CRYPTO_ERR_AUTHENTICATION_FAILED,
                 backend_operation_status::authentication_failed},
    mapping_case{ANO_CRYPTO_ERR_INTEGRITY_CHECK_FAILED,
                 backend_operation_status::integrity_failure},
    mapping_case{ANO_CRYPTO_ERR_NOT_IMPLEMENTED, backend_operation_status::unsupported},
    mapping_case{ANO_CRYPTO_ERR_RESOURCE_EXHAUSTED,
                 backend_operation_status::resource_exhausted},
    mapping_case{ANO_CRYPTO_ERR_INTERNAL_ERROR, backend_operation_status::internal_error},
};

struct name_case
{
    backend_operation_status status;
    std::string_view name;
};

constexpr std::array names{
    name_case{backend_operation_status::success, "success"},
    name_case{backend_operation_status::invalid_argument, "invalid-argument"},
    name_case{backend_operation_status::buffer_too_small, "buffer-too-small"},
    name_case{backend_operation_status::unsupported, "unsupported"},
    name_case{backend_operation_status::not_approved, "not-approved"},
    name_case{backend_operation_status::not_operational, "not-operational"},
    name_case{backend_operation_status::entropy_failure, "entropy-failure"},
    name_case{backend_operation_status::reseed_required, "reseed-required"},
    name_case{backend_operation_status::authentication_failed, "authentication-failed"},
    name_case{backend_operation_status::integrity_failure, "integrity-failure"},
    name_case{backend_operation_status::resource_exhausted, "resource-exhausted"},
    name_case{backend_operation_status::internal_error, "internal-error"},
};
} // namespace

int main()
{
    using anosecurekit_enterprise::backend_operation_status_name;
    using anosecurekit_enterprise::providers::anocrypto_c::map_native_operation_status;

    for (const auto& test : mappings)
    {
        if (map_native_operation_status(test.native_status) != test.enterprise_status)
        {
            return 1;
        }
        if (test.native_status != ANO_CRYPTO_OK
            && map_native_operation_status(test.native_status) == backend_operation_status::success)
        {
            return 2;
        }
    }

    constexpr auto unknown_positive = static_cast<ano_crypto_status_t>(16);
    constexpr auto unknown_cast = static_cast<ano_crypto_status_t>(254);
    if (map_native_operation_status(unknown_positive) != backend_operation_status::internal_error
        || map_native_operation_status(unknown_cast) != backend_operation_status::internal_error)
    {
        return 3;
    }

    for (const auto& test : names)
    {
        if (backend_operation_status_name(test.status) != test.name)
        {
            return 4;
        }
    }
    if (backend_operation_status_name(static_cast<backend_operation_status>(-1)) != "unknown")
    {
        return 5;
    }
    return 0;
}
