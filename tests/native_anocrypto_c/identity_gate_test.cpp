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
    const std::array data{std::byte{1}, std::byte{2}};
    int failures = 0;
    const auto denied = [&]<class F>(const char* name, F operation) {
        try { operation(); }
        catch (const anosecurekit::error& e) {
            if (e.code() == anosecurekit::error_code::backend_failure) return;
        }
        catch (...) {}
        std::cerr << "operation was not denied with backend_failure: " << name << '\n';
        ++failures;
    };
    // Fault 0 exercises real shutdown with live stream contexts. The other
    // faults change identity while the native module remains operational.
    for (int selected_fault : {1, 2, 3, 0}) {
        fault = 0;
        const auto sealed = cb::aes256_gcm_encrypt(data, key, nonce, {});
        cb::Aes256GcmEncryptContext enc_aad(key, nonce), enc_update(key, nonce), enc_final(key, nonce);
        cb::Aes256GcmDecryptContext dec_aad(key, nonce), dec_update(key, nonce), dec_final(key, nonce);
        const auto first = std::span<const std::byte>{data}.first(1);
        const auto rest = std::span<const std::byte>{data}.subspan(1);
        const auto encrypted = std::span<const std::byte>{sealed.ciphertext};
        // Exercise an already-started stream, not just its first data update.
        (void)enc_update.update(first);
        (void)dec_update.update(encrypted.first(1));
        (void)enc_final.update(data);
        (void)dec_final.update(sealed.ciphertext);
        fault = selected_fault;
        if (selected_fault == 0) {
            shutdown_backend();
            if (ano_crypto_module_require_operational() == ANO_CRYPTO_OK) return 2;
        } else if (ano_crypto_module_require_operational() != ANO_CRYPTO_OK) return 2;
        // Do not refresh Enterprise state first: every operation must query
        // identity itself, even when the previous snapshot was ready.
        denied("sha256", [&] { (void)cb::sha256(data); });
        denied("hmac", [&] { (void)cb::hmac_sha256(data, data); });
        denied("hkdf", [&] { (void)cb::hkdf_sha256(data, {}, {}, 32); });
        denied("random", [&] { (void)cb::random_bytes(16); });
        denied("key generation", [&] { (void)cb::generate_key(); });
        denied("scrypt", [&] { (void)cb::scrypt_key(data, data, {32768, 8, 1, 67108864}); });
        denied("encrypt", [&] { (void)cb::aes256_gcm_encrypt(data, key, nonce, {}); });
        denied("decrypt", [&] { (void)cb::aes256_gcm_decrypt(sealed.ciphertext, sealed.tag, key, nonce, {}); });
        denied("encrypt init", [&] { cb::Aes256GcmEncryptContext context(key, nonce); });
        denied("decrypt init", [&] { cb::Aes256GcmDecryptContext context(key, nonce); });
        denied("encrypt AAD", [&] { enc_aad.update_aad(data); });
        denied("encrypt update", [&] { (void)enc_update.update(rest); });
        denied("encrypt final", [&] { (void)enc_final.finalize(); });
        denied("decrypt AAD", [&] { dec_aad.update_aad(data); });
        denied("decrypt update", [&] { (void)dec_update.update(encrypted.subspan(1)); });
        denied("decrypt final", [&] { (void)dec_final.finalize(sealed.tag); });
        if (!cb::random_bytes(0).empty()) return 3;
        if (selected_fault != 0) {
            if (initialize_backend() == backend_runtime_status::ready) return 2;
            fault = 0;
            // Positive controls show that the exact operations denied above
            // were otherwise valid and that denial did not consume state.
            enc_aad.update_aad(data);
            dec_aad.update_aad(data);
            const auto aad_ciphertext = enc_aad.update(data);
            const auto aad_tag = enc_aad.finalize();
            if (dec_aad.update(aad_ciphertext) != anosecurekit::bytes(data.begin(), data.end())) return 6;
            dec_aad.finalize(aad_tag);
            (void)enc_update.update(rest);
            if (enc_update.finalize() != sealed.tag) return 7;
            if (dec_update.update(encrypted.subspan(1)) != anosecurekit::bytes(rest.begin(), rest.end())) return 8;
            dec_update.finalize(sealed.tag);
            if (enc_final.finalize() != sealed.tag) return 9;
            dec_final.finalize(sealed.tag);
        }
    }
    fault = 0;
    if (initialize_backend() != backend_runtime_status::ready) return 4;
    (void)cb::sha256(data);
    shutdown_backend();
    std::cout << "identity denial bypasses: " << failures << '\n';
    return failures == 0 ? 0 : 5;
}
