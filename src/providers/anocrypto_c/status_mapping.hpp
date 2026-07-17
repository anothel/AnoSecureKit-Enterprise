// SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary
#ifndef ANOSECUREKIT_ENTERPRISE_SRC_PROVIDERS_ANOCRYPTO_C_STATUS_MAPPING_HPP_
#define ANOSECUREKIT_ENTERPRISE_SRC_PROVIDERS_ANOCRYPTO_C_STATUS_MAPPING_HPP_

#include "anosecurekit_enterprise/provider_runtime.hpp"

#include <anocrypto/ac_status.h>

namespace anosecurekit_enterprise::providers::anocrypto_c
{

backend_operation_status map_native_operation_status(ano_crypto_status_t status) noexcept;

} // namespace anosecurekit_enterprise::providers::anocrypto_c

#endif
