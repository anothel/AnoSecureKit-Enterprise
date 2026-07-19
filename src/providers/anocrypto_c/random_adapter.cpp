// SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary
#include "random_adapter.hpp"

#include "status_mapping.hpp"

#include "internal/secure_wipe.hpp"

#include "anosecurekit/types.hpp"

#include <algorithm>

namespace anosecurekit_enterprise::providers::anocrypto_c
{

ano_crypto_status_t fill_random_output(std::span<std::byte> output, const public_random_api& api)
{
    if (output.empty())
    {
        return ANO_CRYPTO_OK;
    }

    const auto fail = [output](ano_crypto_status_t status) {
        anosecurekit::internal::secure_wipe(output);
        return status;
    };
    if (api.is_available() == 0)
    {
        return fail(ANO_CRYPTO_ERR_NOT_IMPLEMENTED);
    }

    std::size_t context_size = 0;
    auto status = api.context_size(&context_size);
    if (map_native_operation_status(status) != backend_operation_status::success)
    {
        return fail(status);
    }
    if (context_size == 0)
    {
        return fail(ANO_CRYPTO_ERR_INTERNAL_ERROR);
    }

    anosecurekit::bytes context(context_size);
    anosecurekit::internal::wipe_on_exit erase_context(context);
    status = api.init(context.data(), context.size(), nullptr, 0, ANO_CRYPTO_RANDOM_FLAG_NONE);
    if (map_native_operation_status(status) != backend_operation_status::success)
    {
        (void)map_native_operation_status(api.uninit(context.data(), context.size()));
        return fail(status);
    }

    std::size_t offset = 0;
    while (offset < output.size())
    {
        const auto chunk_size =
            std::min(output.size() - offset, static_cast<std::size_t>(ANO_CRYPTO_RANDOM_MAX_REQUEST_SIZE));
        status = api.generate(context.data(), reinterpret_cast<std::uint8_t*>(output.data() + offset), chunk_size,
                              nullptr, 0, ANO_CRYPTO_RANDOM_FLAG_NONE);
        if (map_native_operation_status(status) != backend_operation_status::success)
        {
            break;
        }
        offset += chunk_size;
    }

    const auto uninit_status = api.uninit(context.data(), context.size());
    if (map_native_operation_status(status) == backend_operation_status::success)
    {
        status = uninit_status;
    }
    return map_native_operation_status(status) == backend_operation_status::success ? status : fail(status);
}

} // namespace anosecurekit_enterprise::providers::anocrypto_c
