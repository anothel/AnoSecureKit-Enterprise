# SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary
cmake_minimum_required(VERSION 3.20)

foreach(_required IN ITEMS ENTERPRISE_SOURCE_DIR TEST_ROOT DEFAULT_EVIDENCE_RECORD)
  if(NOT DEFINED ${_required} OR "${${_required}}" STREQUAL "")
    message(FATAL_ERROR "${_required} is required")
  endif()
endforeach()

file(REMOVE_RECURSE "${TEST_ROOT}")
file(MAKE_DIRECTORY "${TEST_ROOT}/artifacts")
set(_validator "${ENTERPRISE_SOURCE_DIR}/cmake/check_trusted_release_evidence.cmake")
set(_sha_a "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")
set(_sha_b "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb")
set(_zero "sha256:0000000000000000000000000000000000000000000000000000000000000000")

file(WRITE "${TEST_ROOT}/MANIFEST.sha256" "fixture manifest\n")
file(WRITE "${TEST_ROOT}/artifacts/SHA256SUMS.txt" "fixture checksums\n")
file(WRITE "${TEST_ROOT}/artifacts/bundle.spdx.json" "{}\n")
file(WRITE "${TEST_ROOT}/artifacts/package.zip" "fixture package\n")
file(SHA256 "${TEST_ROOT}/MANIFEST.sha256" _manifest_sha)
file(SHA256 "${TEST_ROOT}/artifacts/SHA256SUMS.txt" _set_sha)
file(SHA256 "${TEST_ROOT}/artifacts/bundle.spdx.json" _sbom_sha)
file(SHA256 "${TEST_ROOT}/artifacts/package.zip" _package_sha)
file(SIZE "${TEST_ROOT}/artifacts/SHA256SUMS.txt" _set_size)
file(SIZE "${TEST_ROOT}/artifacts/bundle.spdx.json" _sbom_size)
file(SIZE "${TEST_ROOT}/artifacts/package.zip" _package_size)
set(_manifest_digest "sha256:${_manifest_sha}")
set(_set_digest "sha256:${_set_sha}")
set(_sbom_digest "sha256:${_sbom_sha}")

set(_lanes
  "CodeQL C/C++"
  "downloaded-artifact-validation"
  "macos-latest appleclang Release shared=OFF"
  "non-bundled-consumer"
  "ubuntu-latest clang Debug sanitizers"
  "ubuntu-latest clang Release shared=OFF"
  "ubuntu-latest gcc Release shared=OFF"
  "ubuntu-latest gcc Release shared=ON"
  "windows-latest msvc Release shared=ON")
set(_required_lanes "[")
set(_lane_results "[")
set(_lane_index 0)
foreach(_lane IN LISTS _lanes)
  if(_lane_index GREATER 0)
    string(APPEND _required_lanes ",")
    string(APPEND _lane_results ",")
  endif()
  string(APPEND _required_lanes "\"${_lane}\"")
  string(APPEND _lane_results
    "{\"name\":\"${_lane}\",\"status\":\"passed\",\"runner_assigned\":true,\"source_revision\":\"${_sha_b}\"}")
  math(EXPR _lane_index "${_lane_index} + 1")
endforeach()
string(APPEND _required_lanes "]")
string(APPEND _lane_results "]")

string(CONCAT _files
  "[{\"name\":\"SHA256SUMS.txt\",\"size\":${_set_size},\"sha256\":\"${_set_digest}\"},"
  "{\"name\":\"bundle.spdx.json\",\"size\":${_sbom_size},\"sha256\":\"${_sbom_digest}\"},"
  "{\"name\":\"package.zip\",\"size\":${_package_size},\"sha256\":\"sha256:${_package_sha}\"}]")
string(CONCAT _base
  "{\"schema_version\":\"1\",\"product\":\"AnoSecureKit Enterprise\""
  ",\"enterprise_version\":\"0.1.0\",\"community_version\":\"0.4.0\""
  ",\"community_tree\":\"${_sha_a}\",\"backend_profile\":\"openssl\""
  ",\"provider_family\":\"openssl\",\"source_revision\":\"${_sha_b}\""
  ",\"generated_at\":\"2026-01-01T00:00:00Z\",\"expires_at\":\"2099-01-01T00:00:00Z\""
  ",\"hosted\":{\"workflow_name\":\"AnoSecureKit Enterprise CI\",\"workflow_id\":\"312984578\""
  ",\"run_id\":\"123456\",\"event\":\"push\",\"source_revision\":\"${_sha_b}\""
  ",\"status\":\"passed\",\"required_lanes\":${_required_lanes},\"lane_results\":${_lane_results}}"
  ",\"codeql\":{\"required\":true,\"status\":\"passed\""
  ",\"analysis_reference\":\"https://github.com/anothel/AnoSecureKit-Enterprise/actions/runs/123456\"}"
  ",\"artifacts\":{\"manifest_digest\":\"${_manifest_digest}\""
  ",\"artifact_set_digest\":\"${_set_digest}\",\"files\":${_files}}"
  ",\"sbom\":{\"format\":\"SPDX-2.3\",\"digest\":\"${_sbom_digest}\"}"
  ",\"signing\":{\"status\":\"verified\",\"scheme\":\"sigstore\""
  ",\"key_id\":\"github-oidc:anothel/AnoSecureKit-Enterprise\""
  ",\"signature_reference\":\"https://github.com/anothel/AnoSecureKit-Enterprise/attestations/signature-123\"}"
  ",\"provenance\":{\"status\":\"verified\",\"predicate_type\":\"https://slsa.dev/provenance/v1\""
  ",\"statement_digest\":\"sha256:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd\""
  ",\"statement_reference\":\"https://github.com/anothel/AnoSecureKit-Enterprise/attestations/provenance-123\"}"
  ",\"revocation\":{\"status\":\"clear\""
  ",\"reference\":\"https://github.com/anothel/AnoSecureKit-Enterprise/attestations/revocation-123\"}}\n")

set(_common_args
  "-DEXPECTED_ENTERPRISE_VERSION=0.1.0"
  "-DEXPECTED_COMMUNITY_VERSION=0.4.0"
  "-DEXPECTED_COMMUNITY_TREE=${_sha_a}"
  "-DEXPECTED_BACKEND_PROFILE=openssl"
  "-DEXPECTED_PROVIDER_FAMILY=openssl"
  "-DEXPECTED_SOURCE_REVISION=${_sha_b}"
  "-DEXPECTED_ARTIFACT_MANIFEST_DIGEST=${_manifest_digest}"
  "-DEXPECTED_ARTIFACT_SET_DIGEST=${_set_digest}"
  "-DEXPECTED_SBOM_DIGEST=${_sbom_digest}"
  "-DARTIFACT_ROOT=${TEST_ROOT}/artifacts")

function(_run_case name content require_trusted allow_fixture expect_success expected_text)
  set(_record "${TEST_ROOT}/${name}.json")
  file(WRITE "${_record}" "${content}")
  execute_process(
    COMMAND "${CMAKE_COMMAND}" "-DEVIDENCE_RECORD=${_record}" ${_common_args}
      "-DREQUIRE_TRUSTED=${require_trusted}"
      "-DTEST_FIXTURE_MODE=ON" "-DALLOW_TEST_FIXTURE=${allow_fixture}"
      -P "${_validator}"
    RESULT_VARIABLE _result OUTPUT_VARIABLE _out ERROR_VARIABLE _err)
  string(CONCAT _log "${_out}" "${_err}")
  if(expect_success AND NOT _result EQUAL 0)
    message(FATAL_ERROR "${name}: expected success\n${_log}")
  elseif(NOT expect_success AND _result EQUAL 0)
    message(FATAL_ERROR "${name}: unexpectedly succeeded\n${_log}")
  endif()
  if(NOT expected_text STREQUAL "")
    string(FIND "${_log}" "${expected_text}" _found)
    if(_found EQUAL -1)
      message(FATAL_ERROR "${name}: expected '${expected_text}'\n${_log}")
    endif()
  endif()
  if(NOT expect_success)
    set_property(GLOBAL APPEND PROPERTY _evidence_negative_cases "${name}")
  endif()
endfunction()

function(_reject_replacement name expected from to)
  string(REPLACE "${from}" "${to}" _case "${_base}")
  if(_case STREQUAL _base)
    message(FATAL_ERROR "${name}: fixture replacement did not change input")
  endif()
  _run_case("${name}" "${_case}" OFF ON FALSE "${expected}")
endfunction()

_run_case(structural-positive-crypto-unavailable "${_base}" OFF ON TRUE
  "cryptographic_verifier: unavailable")
_run_case(cryptographic-verifier-unavailable "${_base}" ON ON FALSE
  "verification failed")

execute_process(
  COMMAND "${CMAKE_COMMAND}" "-DEVIDENCE_RECORD=${DEFAULT_EVIDENCE_RECORD}"
    "-DEXPECTED_ENTERPRISE_VERSION=0.1.0" "-DEXPECTED_COMMUNITY_VERSION=0.4.0"
    "-DEXPECTED_COMMUNITY_TREE=9b498f5431f217ac71e8d2e2c92df9e8b0122626"
    "-DEXPECTED_BACKEND_PROFILE=openssl" "-DEXPECTED_PROVIDER_FAMILY=openssl"
    "-DEXPECTED_SOURCE_REVISION=20565a677186409c0b645012cf920cae81962f16"
    -DREQUIRE_TRUSTED=OFF -P "${_validator}"
  RESULT_VARIABLE _default_result OUTPUT_VARIABLE _default_out ERROR_VARIABLE _default_err)
string(CONCAT _default_log "${_default_out}" "${_default_err}")
if(NOT _default_result EQUAL 0
   OR NOT _default_log MATCHES "trusted_evidence_status: (unavailable|rejected)")
  message(FATAL_ERROR "Default trusted evidence is not a valid fail-closed record\n${_default_log}")
endif()

file(REMOVE "${TEST_ROOT}/missing.json")
execute_process(
  COMMAND "${CMAKE_COMMAND}" "-DEVIDENCE_RECORD=${TEST_ROOT}/missing.json" ${_common_args}
    -DREQUIRE_TRUSTED=OFF -DTEST_FIXTURE_MODE=ON -DALLOW_TEST_FIXTURE=ON
    -P "${_validator}"
  RESULT_VARIABLE _missing_result OUTPUT_VARIABLE _missing_out ERROR_VARIABLE _missing_err)
string(CONCAT _missing_log "${_missing_out}" "${_missing_err}")
if(_missing_result EQUAL 0 OR NOT _missing_log MATCHES "record is missing")
  message(FATAL_ERROR "missing: expected rejection\n${_missing_log}")
endif()
set_property(GLOBAL APPEND PROPERTY _evidence_negative_cases missing)

_run_case(empty "" OFF ON FALSE "Malformed trusted release evidence JSON")
_run_case(malformed "{" OFF ON FALSE "Malformed trusted release evidence JSON")
_reject_replacement(unknown-schema "Unsupported trusted release evidence schema version"
  "\"schema_version\":\"1\"" "\"schema_version\":\"2\"")
_reject_replacement(missing-field "field count mismatch"
  ",\"product\":\"AnoSecureKit Enterprise\"" "")
_reject_replacement(duplicate-key "not in canonical form"
  "\"schema_version\":\"1\"" "\"schema_version\":\"1\",\"schema_version\":\"1\"")
_reject_replacement(unknown-field "field count mismatch"
  "\"schema_version\":\"1\"" "\"schema_version\":\"1\",\"unexpected\":\"value\"")
_reject_replacement(noncanonical "not in canonical form" "{\"schema_version\"" "{ \"schema_version\"")
_reject_replacement(unknown-status "Unsupported trusted evidence hosted.status"
  "\"status\":\"passed\",\"required_lanes\"" "\"status\":\"mystery\",\"required_lanes\"")
_reject_replacement(source-mismatch "source_revision mismatch"
  "\"source_revision\":\"${_sha_b}\"" "\"source_revision\":\"${_sha_a}\"")
_reject_replacement(enterprise-version-mismatch "enterprise_version mismatch"
  "\"enterprise_version\":\"0.1.0\"" "\"enterprise_version\":\"9.9.9\"")
_reject_replacement(community-version-mismatch "community_version mismatch"
  "\"community_version\":\"0.4.0\"" "\"community_version\":\"9.9.9\"")
_reject_replacement(community-tree-mismatch "community_tree mismatch"
  "\"community_tree\":\"${_sha_a}\"" "\"community_tree\":\"${_sha_b}\"")
_reject_replacement(backend-profile-mismatch "backend_profile mismatch"
  "\"backend_profile\":\"openssl\"" "\"backend_profile\":\"anocrypto-c\"")
_reject_replacement(provider-family-mismatch "provider_family mismatch"
  "\"provider_family\":\"openssl\"" "\"provider_family\":\"anocrypto-c\"")
_reject_replacement(hosted-source-mismatch "hosted source_revision mismatch"
  "\"event\":\"push\",\"source_revision\":\"${_sha_b}\""
  "\"event\":\"push\",\"source_revision\":\"${_sha_a}\"")
_reject_replacement(workflow-mismatch "workflow identity mismatch"
  "\"workflow_id\":\"312984578\"" "\"workflow_id\":\"1\"")

list(GET _lanes 0 _first_lane)
string(REPLACE "\"required_lanes\":[\"${_first_lane}\"," "\"required_lanes\":["
  _missing_lane "${_base}")
_run_case(required-lane-missing "${_missing_lane}" OFF ON FALSE "required hosted lane count mismatch")
foreach(_status IN ITEMS runner-not-assigned skipped deferred blocked-external)
  string(REPLACE
    "{\"name\":\"${_first_lane}\",\"status\":\"passed\",\"runner_assigned\":true"
    "{\"name\":\"${_first_lane}\",\"status\":\"${_status}\",\"runner_assigned\":false"
    _lane_case "${_base}")
  string(REPLACE "\"status\":\"passed\",\"required_lanes\""
    "\"status\":\"blocked-external\",\"required_lanes\"" _lane_case "${_lane_case}")
  _run_case("lane-${_status}" "${_lane_case}" ON ON FALSE "required hosted lane did")
endforeach()
_reject_replacement(runner-assignment-contradiction "Passed hosted lane must have an assigned runner"
  "{\"name\":\"${_first_lane}\",\"status\":\"passed\",\"runner_assigned\":true"
  "{\"name\":\"${_first_lane}\",\"status\":\"passed\",\"runner_assigned\":false")

string(REPLACE
  "\"codeql\":{\"required\":true,\"status\":\"passed\",\"analysis_reference\":\"https://github.com/anothel/AnoSecureKit-Enterprise/actions/runs/123456\"}"
  "\"codeql\":{\"required\":true,\"status\":\"not-run\",\"analysis_reference\":\"unavailable\"}"
  _codeql_case "${_base}")
_run_case(codeql-not-run "${_codeql_case}" ON ON FALSE "required CodeQL evidence did")
_reject_replacement(codeql-reference-unsafe "CodeQL analysis reference is missing or unsafe"
  "https://github.com/anothel/AnoSecureKit-Enterprise/actions/runs/123456" "https://example.invalid/codeql")

string(REGEX REPLACE
  ",\\{\"name\":\"package\\.zip\",\"size\":[0-9]+,\"sha256\":\"sha256:[0-9a-f]+\"\\}"
  "" _artifact_missing "${_base}")
_run_case(artifact-missing "${_artifact_missing}" OFF ON FALSE "artifact inventory mismatch")
_reject_replacement(artifact-name-mismatch "artifact inventory mismatch"
  "\"name\":\"package.zip\"" "\"name\":\"other.zip\"")
_reject_replacement(artifact-size-mismatch "artifact size mismatch"
  "\"name\":\"package.zip\",\"size\":${_package_size}"
  "\"name\":\"package.zip\",\"size\":999999")
_reject_replacement(artifact-digest-mismatch "artifact digest mismatch"
  "sha256:${_package_sha}" "sha256:eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee")
_reject_replacement(manifest-digest-mismatch "artifact_manifest_digest mismatch"
  "${_manifest_digest}" "sha256:eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee")
_reject_replacement(artifact-set-digest-mismatch "artifact_set_digest mismatch"
  "\"artifact_set_digest\":\"${_set_digest}\""
  "\"artifact_set_digest\":\"sha256:eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee\"")
_reject_replacement(sbom-digest-mismatch "sbom_digest mismatch"
  "\"sbom\":{\"format\":\"SPDX-2.3\",\"digest\":\"${_sbom_digest}\"}"
  "\"sbom\":{\"format\":\"SPDX-2.3\",\"digest\":\"sha256:eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee\"}")
_reject_replacement(path-traversal "artifact name is unsafe"
  "\"name\":\"package.zip\"" "\"name\":\"../package.zip\"")
_reject_replacement(windows-absolute-path "contains a local absolute path"
  "https://github.com/anothel/AnoSecureKit-Enterprise/actions/runs/123456" "C:\\\\Users\\\\operator\\\\codeql")
_reject_replacement(posix-absolute-path "contains a local absolute path"
  "https://github.com/anothel/AnoSecureKit-Enterprise/actions/runs/123456" "/home/operator/codeql")
_reject_replacement(secret-like-value "contains secret-like data"
  "https://github.com/anothel/AnoSecureKit-Enterprise/actions/runs/123456" "api_token=do-not-store")

string(REPLACE
  "\"signing\":{\"status\":\"verified\",\"scheme\":\"sigstore\",\"key_id\":\"github-oidc:anothel/AnoSecureKit-Enterprise\",\"signature_reference\":\"https://github.com/anothel/AnoSecureKit-Enterprise/attestations/signature-123\"}"
  "\"signing\":{\"status\":\"unavailable\",\"scheme\":\"unavailable\",\"key_id\":\"unavailable\",\"signature_reference\":\"unavailable\"}"
  _signing_unavailable "${_base}")
_run_case(signing-unavailable "${_signing_unavailable}" ON ON FALSE "signing evidence unavailable")
_reject_replacement(unknown-signing-scheme "Unsupported trusted evidence signing.scheme"
  "\"scheme\":\"sigstore\"" "\"scheme\":\"unknown\"")
_reject_replacement(unknown-signing-key "Unknown trusted evidence signing key identity"
  "github-oidc:anothel/AnoSecureKit-Enterprise" "github-oidc:unknown/repository")
string(REPLACE "\"signing\":{\"status\":\"verified\""
  "\"signing\":{\"status\":\"rejected\"" _invalid_signature "${_base}")
_run_case(invalid-signature "${_invalid_signature}" ON ON FALSE "signing evidence rejected")
_reject_replacement(signature-reference-unsafe "signature reference is missing or unsafe"
  "https://github.com/anothel/AnoSecureKit-Enterprise/attestations/signature-123" "https://example.invalid/signature")

string(REPLACE
  "\"provenance\":{\"status\":\"verified\",\"predicate_type\":\"https://slsa.dev/provenance/v1\",\"statement_digest\":\"sha256:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd\",\"statement_reference\":\"https://github.com/anothel/AnoSecureKit-Enterprise/attestations/provenance-123\"}"
  "\"provenance\":{\"status\":\"unavailable\",\"predicate_type\":\"unavailable\",\"statement_digest\":\"${_zero}\",\"statement_reference\":\"unavailable\"}"
  _provenance_unavailable "${_base}")
_run_case(provenance-unavailable "${_provenance_unavailable}" ON ON FALSE "provenance evidence")
_reject_replacement(provenance-digest-invalid "must use sha256"
  "sha256:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd" "sha256:bad")
_reject_replacement(provenance-reference-unsafe "provenance reference is missing or unsafe"
  "https://github.com/anothel/AnoSecureKit-Enterprise/attestations/provenance-123" "https://example.invalid/provenance")

string(REPLACE "\"expires_at\":\"2099-01-01T00:00:00Z\""
  "\"expires_at\":\"2020-01-01T00:00:00Z\"" _expired "${_base}")
string(REPLACE "\"generated_at\":\"2026-01-01T00:00:00Z\""
  "\"generated_at\":\"2019-01-01T00:00:00Z\"" _expired "${_expired}")
_run_case(expired "${_expired}" ON ON FALSE "trusted release evidence is")
_reject_replacement(future-generation "generation time is in the future"
  "\"generated_at\":\"2026-01-01T00:00:00Z\"" "\"generated_at\":\"2098-01-01T00:00:00Z\"")
_reject_replacement(invalid-calendar-timestamp "not a valid calendar timestamp"
  "\"generated_at\":\"2026-01-01T00:00:00Z\"" "\"generated_at\":\"2026-02-31T00:00:00Z\"")
string(REPLACE "\"revocation\":{\"status\":\"clear\""
  "\"revocation\":{\"status\":\"revoked\"" _revoked "${_base}")
_run_case(revoked "${_revoked}" ON ON FALSE "trusted release evidence is")
_run_case(test-fixture-production "${_base}" OFF OFF FALSE
  "Test-only evidence fixture cannot be used by a production gate")
_reject_replacement(partial-anocrypto-profile "backend_profile mismatch"
  "\"backend_profile\":\"openssl\"" "\"backend_profile\":\"anocrypto-c-partial\"")
_reject_replacement(openssl-fallback-provider "provider_family mismatch"
  "\"provider_family\":\"openssl\"" "\"provider_family\":\"openssl-direct-fallback\"")

get_property(_negative_cases GLOBAL PROPERTY _evidence_negative_cases)
list(LENGTH _negative_cases _negative_count)
message(STATUS
  "Trusted release evidence contract passed: structural valid, crypto unavailable, ${_negative_count} fail-closed cases")
