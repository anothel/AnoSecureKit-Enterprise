// SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary
#include "anosecurekit_enterprise/enterprise.hpp"

#include "anosecurekit/base64.hpp"
#include "anosecurekit/error.hpp"
#include "anosecurekit/random.hpp"

#ifdef ANOSECUREKIT_ENTERPRISE_BACKEND_ANOCRYPTO_C
#include "random_adapter.hpp"
#include "status_mapping.hpp"

#include <anocrypto/ac_random.h>
#endif

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <cstring>
#include <iostream>
#include <span>
#include <string_view>
#include <utility>
#include <vector>

namespace
{
int fail(int code, std::string_view message)
{
    anosecurekit_enterprise::shutdown_backend();
    std::cerr << "random test failure: " << message << '\n';
    return code;
}

bool is_all_zero(std::span<const std::byte> data)
{
    return std::all_of(data.begin(), data.end(), [](std::byte value) {
        return value == std::byte{0};
    });
}

template <typename Function>
bool fails_as_error(Function&& function, anosecurekit::error_code expected)
{
    try
    {
        std::forward<Function>(function)();
    }
    catch (const anosecurekit::error& error)
    {
        return error.code() == expected;
    }
    catch (...)
    {
    }
    return false;
}

#ifdef ANOSECUREKIT_ENTERPRISE_BACKEND_ANOCRYPTO_C
struct mock_random_state
{
    bool available{true};
    ano_crypto_status_t context_status{ANO_CRYPTO_OK};
    ano_crypto_status_t init_status{ANO_CRYPTO_OK};
    ano_crypto_status_t generate_status{ANO_CRYPTO_OK};
    ano_crypto_status_t uninit_status{ANO_CRYPTO_OK};
    std::size_t fail_generate_call{};
    std::size_t available_calls{};
    std::size_t context_calls{};
    std::size_t init_calls{};
    std::size_t generate_calls{};
    std::size_t uninit_calls{};
    bool uninit_saw_live_context{};
    std::vector<std::size_t> chunks;
};

mock_random_state mock;

int mock_is_available()
{
    ++mock.available_calls;
    return mock.available ? 1 : 0;
}

ano_crypto_status_t mock_context_size(std::size_t* out_size)
{
    ++mock.context_calls;
    *out_size = 64;
    return mock.context_status;
}

ano_crypto_status_t mock_init(void* context,
                              std::size_t context_size,
                              const std::uint8_t*,
                              std::size_t,
                              std::uint32_t)
{
    ++mock.init_calls;
    std::memset(context, 0xa5, context_size);
    return mock.init_status;
}

ano_crypto_status_t mock_generate(void*,
                                  std::uint8_t* output,
                                  std::size_t output_size,
                                  const std::uint8_t*,
                                  std::size_t,
                                  std::uint32_t)
{
    ++mock.generate_calls;
    mock.chunks.push_back(output_size);
    std::memset(output, 0x5a, output_size);
    return mock.generate_calls == mock.fail_generate_call
        ? mock.generate_status
        : ANO_CRYPTO_OK;
}

ano_crypto_status_t mock_uninit(void* context, std::size_t context_size)
{
    ++mock.uninit_calls;
    const auto* bytes = static_cast<const unsigned char*>(context);
    mock.uninit_saw_live_context = std::any_of(
        bytes, bytes + context_size, [](unsigned char value) { return value != 0; });
    std::memset(context, 0, context_size);
    return mock.uninit_status;
}

constexpr anosecurekit_enterprise::providers::anocrypto_c::public_random_api mock_api{
    mock_is_available,
    mock_context_size,
    mock_init,
    mock_generate,
    mock_uninit,
};

bool check_mock_failures()
{
    using namespace anosecurekit_enterprise;
    using namespace anosecurekit_enterprise::providers::anocrypto_c;
    constexpr auto maximum = static_cast<std::size_t>(ANO_CRYPTO_RANDOM_MAX_REQUEST_SIZE);

    mock = {};
    anosecurekit::bytes empty;
    if (fill_random_output(empty, mock_api) != ANO_CRYPTO_OK || mock.available_calls != 0)
    {
        return false;
    }

    mock = {};
    anosecurekit::bytes chunked(maximum * 2 + 17);
    if (fill_random_output(chunked, mock_api) != ANO_CRYPTO_OK
        || mock.chunks != std::vector<std::size_t>{maximum, maximum, 17}
        || mock.init_calls != 1 || mock.uninit_calls != 1
        || !mock.uninit_saw_live_context || is_all_zero(chunked))
    {
        return false;
    }

    mock = {};
    mock.available = false;
    anosecurekit::bytes unavailable(16, std::byte{0xa5});
    if (fill_random_output(unavailable, mock_api) != ANO_CRYPTO_ERR_NOT_IMPLEMENTED
        || !is_all_zero(unavailable) || mock.context_calls != 0)
    {
        return false;
    }

    constexpr std::array failures{
        std::pair{ANO_CRYPTO_ERR_ENTROPY_SOURCE_FAILED,
                  backend_operation_status::entropy_failure},
        std::pair{ANO_CRYPTO_ERR_DRBG_RESEED_REQUIRED,
                  backend_operation_status::reseed_required},
        std::pair{ANO_CRYPTO_ERR_NOT_INITIALIZED,
                  backend_operation_status::not_operational},
        std::pair{ANO_CRYPTO_ERR_INVALID_ARGUMENT,
                  backend_operation_status::invalid_argument},
        std::pair{ANO_CRYPTO_ERR_RESOURCE_EXHAUSTED,
                  backend_operation_status::resource_exhausted},
        std::pair{ANO_CRYPTO_ERR_INTERNAL_ERROR,
                  backend_operation_status::internal_error},
    };
    for (const auto& [native_status, mapped_status] : failures)
    {
        mock = {};
        mock.fail_generate_call = 2;
        mock.generate_status = native_status;
        anosecurekit::bytes partial(maximum + 1, std::byte{0xa5});
        const auto status = fill_random_output(partial, mock_api);
        if (status != native_status || map_native_operation_status(status) != mapped_status
            || !is_all_zero(partial) || mock.generate_calls != 2
            || mock.uninit_calls != 1)
        {
            return false;
        }
    }

    mock = {};
    mock.init_status = ANO_CRYPTO_ERR_ENTROPY_SOURCE_FAILED;
    anosecurekit::bytes init_failure(32, std::byte{0xa5});
    if (fill_random_output(init_failure, mock_api)
        != ANO_CRYPTO_ERR_ENTROPY_SOURCE_FAILED
        || !is_all_zero(init_failure) || mock.generate_calls != 0
        || mock.uninit_calls != 1)
    {
        return false;
    }

    mock = {};
    mock.uninit_status = ANO_CRYPTO_ERR_INTERNAL_ERROR;
    anosecurekit::bytes cleanup_failure(32, std::byte{0xa5});
    return fill_random_output(cleanup_failure, mock_api) == ANO_CRYPTO_ERR_INTERNAL_ERROR
        && is_all_zero(cleanup_failure) && mock.uninit_calls == 1;
}

bool check_native_context_cleanup()
{
    std::size_t context_size = 0;
    if (ano_crypto_random_context_size(&context_size) != ANO_CRYPTO_OK
        || context_size == 0)
    {
        return false;
    }

    std::vector<std::uint8_t> context(context_size, 0xa5);
    if (ano_crypto_random_init(context.data(),
                               context.size(),
                               nullptr,
                               0,
                               ANO_CRYPTO_RANDOM_FLAG_NONE)
        != ANO_CRYPTO_OK)
    {
        return false;
    }
    return ano_crypto_random_uninit(context.data(), context.size()) == ANO_CRYPTO_OK
        && std::all_of(context.begin(), context.end(), [](std::uint8_t value) {
               return value == 0;
           });
}
#endif

} // namespace

int main()
{
    using namespace anosecurekit_enterprise;

    if (!anosecurekit::random_bytes(0).empty())
    {
        return fail(1, "zero-length output");
    }

#ifdef ANOSECUREKIT_ENTERPRISE_BACKEND_ANOCRYPTO_C
    constexpr auto capability_mask =
        backend_capability_bit(crypto_backend_capability::sha256)
        | backend_capability_bit(crypto_backend_capability::hmac_sha256)
        | backend_capability_bit(crypto_backend_capability::random);
    const auto initial = current_backend_runtime();
    if ((initial.module_state != backend_module_state::uninitialized
         && initial.module_state != backend_module_state::shutdown)
        || initial.capability_mask != capability_mask || backend_profile_ready()
        || !fails_as_error([] { (void)anosecurekit::random_bytes(1); },
                           anosecurekit::error_code::backend_failure)
        || !fails_as_error([] { (void)anosecurekit::generate_key(); },
                           anosecurekit::error_code::backend_failure)
        || !fails_as_error([] { (void)anosecurekit::random_token(1); },
                           anosecurekit::error_code::backend_failure))
    {
        return fail(2, "pre-initialization gate");
    }
    const auto* service_name = ano_crypto_random_service_name();
    if (ano_crypto_random_is_available() == 0 || service_name == nullptr
        || std::string_view{service_name}
            != "AnoCrypto-C HMAC_DRBG-SHA-256 random service"
        || !check_mock_failures())
    {
        return fail(3, "public service or mock failure contract");
    }
#endif

    if (initialize_backend() != backend_runtime_status::ready)
    {
        return fail(4, "runtime initialization");
    }

#ifdef ANOSECUREKIT_ENTERPRISE_BACKEND_ANOCRYPTO_C
    const auto runtime = current_backend_runtime();
    if (runtime.status != backend_runtime_status::ready
        || runtime.module_state != backend_module_state::operational
        || runtime.capability_mask != capability_mask || backend_profile_ready()
        || anocrypto_backend_available() || !check_native_context_cleanup())
    {
        return fail(5, "native runtime or context cleanup");
    }
#endif

    constexpr auto maximum = std::size_t{65536};
    constexpr std::array sizes{
        std::size_t{0},
        std::size_t{1},
        std::size_t{65535},
        maximum,
        maximum + 1,
        maximum * 2,
        maximum * 4 + 123,
    };
    for (const auto size : sizes)
    {
        const auto output = anosecurekit::random_bytes(size);
        if (output.size() != size || (!output.empty() && is_all_zero(output)))
        {
            return fail(6, "requested length or nonzero output");
        }
    }

    const auto first = anosecurekit::random_bytes(32);
    const auto second = anosecurekit::random_bytes(32);
    const auto key = anosecurekit::generate_key();
    const auto token = anosecurekit::random_token(32);
    if (first == second || key.size() != 32 || is_all_zero(key)
        || anosecurekit::base64url_decode(token).size() != 32
        || !fails_as_error([] { (void)anosecurekit::random_token(0); },
                           anosecurekit::error_code::invalid_input))
    {
        return fail(7, "consecutive output, key, or token contract");
    }

    shutdown_backend();
#ifdef ANOSECUREKIT_ENTERPRISE_BACKEND_ANOCRYPTO_C
    if (!anosecurekit::random_bytes(0).empty()
        || !fails_as_error([] { (void)anosecurekit::random_bytes(1); },
                           anosecurekit::error_code::backend_failure)
        || !fails_as_error([] { (void)anosecurekit::generate_key(); },
                           anosecurekit::error_code::backend_failure))
    {
        return fail(8, "post-shutdown gate");
    }
#endif
    return 0;
}
