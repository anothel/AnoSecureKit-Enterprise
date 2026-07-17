// SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary
#ifndef ANOSECUREKIT_ENTERPRISE_SRC_PROVIDERS_ANOCRYPTO_C_RANDOM_ADAPTER_HPP_
#define ANOSECUREKIT_ENTERPRISE_SRC_PROVIDERS_ANOCRYPTO_C_RANDOM_ADAPTER_HPP_

#include <anocrypto/ac_random.h>

#include <cstddef>
#include <cstdint>
#include <span>

namespace anosecurekit_enterprise::providers::anocrypto_c
{

struct public_random_api
{
    int (*is_available)(void);
    ano_crypto_status_t (*context_size)(std::size_t* out_size);
    ano_crypto_status_t (*init)(void* ctx,
                                std::size_t ctx_len,
                                const std::uint8_t* personalization,
                                std::size_t personalization_len,
                                std::uint32_t flags);
    ano_crypto_status_t (*generate)(void* ctx,
                                    std::uint8_t* out,
                                    std::size_t out_len,
                                    const std::uint8_t* additional_input,
                                    std::size_t additional_input_len,
                                    std::uint32_t flags);
    ano_crypto_status_t (*uninit)(void* ctx, std::size_t ctx_len);
};

ano_crypto_status_t fill_random_output(std::span<std::byte> output,
                                       const public_random_api& api);

} // namespace anosecurekit_enterprise::providers::anocrypto_c

#endif
