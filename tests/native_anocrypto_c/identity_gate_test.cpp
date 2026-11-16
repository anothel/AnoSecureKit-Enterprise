// SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary
// Linux shared-native fault injection: only the public identity query is
// interposed. All lifecycle and cryptographic operations use the real module.
#include "anosecurekit_enterprise/enterprise.hpp"
#include "anosecurekit/error.hpp"
#include "backend/crypto_backend.hpp"
#include <anocrypto/ac_build.h>
#include <anocrypto/ac_module.h>
#include <dlfcn.h>
#include <array>
#include <iostream>

namespace { int fault = 0; }
extern "C" ano_crypto_status_t ano_crypto_build_identity(ano_crypto_build_identity_t* out)
{
    using query = ano_crypto_status_t (*)(ano_crypto_build_identity_t*);
    static auto real_query = reinterpret_cast<query>(dlsym(RTLD_NEXT, "ano_crypto_build_identity"));
    if (real_query == nullptr) return ANO_CRYPTO_ERR_INTERNAL_ERROR;
    const auto status = real_query(out);
    if (status == ANO_CRYPTO_OK && out != nullptr) {
        if (fault == 1) out->git_commit = "identity-mismatch";
        if (fault == 2) out->compiler = nullptr;
    }
    return fault == 3 ? ANO_CRYPTO_ERR_INTERNAL_ERROR : status;
}
int main()
{
    using namespace anosecurekit_enterprise;
    namespace cb = anosecurekit::detail::crypto_backend;
    if (initialize_backend() != backend_runtime_status::ready) return 1;
    anosecurekit::key256 key{};
    std::array<std::byte, 12> nonce{};
    const std::array data{std::byte{1}};
    int failures = 0;
    const auto denied = [&]<class F>(F operation) {
        try { operation(); }
        catch (const anosecurekit::error& e) {
            if (e.code() == anosecurekit::error_code::backend_failure) return;
        }
        catch (...) {}
        ++failures;
    };
    for (int selected_fault : {1, 2, 3}) {
        fault = 0;
        const auto sealed = cb::aes256_gcm_encrypt(data, key, nonce, {});
        cb::Aes256GcmEncryptContext enc_aad(key, nonce), enc_update(key, nonce), enc_final(key, nonce);
        cb::Aes256GcmDecryptContext dec_aad(key, nonce), dec_update(key, nonce), dec_final(key, nonce);
        (void)enc_final.update(data);
        (void)dec_final.update(sealed.ciphertext);
        fault = selected_fault;
        if (initialize_backend() == backend_runtime_status::ready ||
            ano_crypto_module_require_operational() != ANO_CRYPTO_OK) return 2;
        denied([&] { (void)cb::sha256(data); });
        denied([&] { (void)cb::hmac_sha256(data, data); });
        denied([&] { (void)cb::hkdf_sha256(data, {}, {}, 32); });
        denied([&] { (void)cb::random_bytes(16); });
        denied([&] { (void)cb::generate_key(); });
        denied([&] { (void)cb::scrypt_key(data, data, {32768, 8, 1, 67108864}); });
        denied([&] { (void)cb::aes256_gcm_encrypt(data, key, nonce, {}); });
        denied([&] { (void)cb::aes256_gcm_decrypt(sealed.ciphertext, sealed.tag, key, nonce, {}); });
        denied([&] { cb::Aes256GcmEncryptContext context(key, nonce); });
        denied([&] { cb::Aes256GcmDecryptContext context(key, nonce); });
        denied([&] { enc_aad.update_aad(data); });
        denied([&] { (void)enc_update.update(data); });
        denied([&] { (void)enc_final.finalize(); });
        denied([&] { dec_aad.update_aad(data); });
        denied([&] { (void)dec_update.update(sealed.ciphertext); });
        denied([&] { (void)dec_final.finalize(sealed.tag); });
        if (!cb::random_bytes(0).empty()) return 3;
    }
    fault = 0;
    if (initialize_backend() != backend_runtime_status::ready) return 4;
    (void)cb::sha256(data);
    shutdown_backend();
    std::cout << "identity denial bypasses: " << failures << '\n';
    return failures == 0 ? 0 : 5;
}
