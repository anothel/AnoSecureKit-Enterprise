// SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary
#ifndef ANOSECUREKIT_ENTERPRISE_SRC_PROVIDERS_ANOCRYPTO_C_STATUS_MAPPING_HPP_
#define ANOSECUREKIT_ENTERPRISE_SRC_PROVIDERS_ANOCRYPTO_C_STATUS_MAPPING_HPP_

#include "anosecurekit_enterprise/provider_runtime.hpp"

#include <anocrypto/ac_status.h>

#include <cstddef>

namespace anosecurekit_enterprise::providers::anocrypto_c
{

backend_operation_status map_native_operation_status(ano_crypto_status_t status) noexcept;
bool native_operation_output_valid(ano_crypto_status_t status,
                                   std::size_t written,
                                   std::size_t expected) noexcept;

} // namespace anosecurekit_enterprise::providers::anocrypto_c

#endif
