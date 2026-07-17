# SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary
cmake_minimum_required(VERSION 3.20)

foreach(_required IN ITEMS ENTERPRISE_SOURCE_DIR TEST_ROOT DEFAULT_AUTHORIZATION_RECORD)
  if(NOT DEFINED ${_required} OR "${${_required}}" STREQUAL "")
    message(FATAL_ERROR "${_required} is required")
  endif()
endforeach()

file(REMOVE_RECURSE "${TEST_ROOT}")
file(MAKE_DIRECTORY "${TEST_ROOT}")
set(_validator "${ENTERPRISE_SOURCE_DIR}/cmake/check_release_authorization.cmake")
set(_sha_a "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")
set(_sha_b "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb")
set(_digest_a "sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")
set(_digest_b "sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb")
set(_digest_c "sha256:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc")

string(CONCAT _allow
"{\n"
"  \"schema_version\": \"1\",\n"
"  \"decision\": \"allow\",\n"
"  \"product\": \"AnoSecureKit Enterprise\",\n"
"  \"enterprise_version\": \"0.1.0\",\n"
"  \"community_version\": \"0.4.0\",\n"
"  \"community_tree\": \"${_sha_a}\",\n"
"  \"backend_profile\": \"openssl\",\n"
"  \"provider_family\": \"openssl\",\n"
"  \"source_revision\": \"${_sha_b}\",\n"
"  \"qualification_status\": \"qualified\",\n"
"  \"hosted_evidence_status\": \"passed\",\n"
"  \"hosted_evidence_reference\": \"github-actions-run:123456\",\n"
"  \"codeql_required\": true,\n"
"  \"codeql_status\": \"passed\",\n"
"  \"artifact_manifest_digest\": \"${_digest_a}\",\n"
"  \"artifact_set_digest\": \"${_digest_b}\",\n"
"  \"trusted_evidence_digest\": \"${_digest_c}\",\n"
"  \"signing_evidence_status\": \"verified\",\n"
"  \"signing_evidence_reference\": \"signing-evidence:sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\",\n"
"  \"provenance_evidence_status\": \"verified\",\n"
"  \"provenance_evidence_reference\": \"provenance-evidence:sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb\",\n"
"  \"authorization_status\": \"active\",\n"
"  \"authorized_by\": \"role:test-release-authority\",\n"
"  \"authorized_at\": \"2026-01-01T00:00:00Z\",\n"
"  \"expires_at\": \"2099-01-01T00:00:00Z\",\n"
"  \"reason\": \"Test-only positive fixture.\",\n"
"  \"test_only\": true\n"
"}\n")

set(_common_args
  "-DEXPECTED_ENTERPRISE_VERSION=0.1.0"
  "-DEXPECTED_COMMUNITY_VERSION=0.4.0"
  "-DEXPECTED_COMMUNITY_TREE=${_sha_a}"
  "-DEXPECTED_BACKEND_PROFILE=openssl"
  "-DEXPECTED_PROVIDER_FAMILY=openssl"
  "-DEXPECTED_SOURCE_REVISION=${_sha_b}"
  "-DEXPECTED_ARTIFACT_MANIFEST_DIGEST=${_digest_a}"
  "-DEXPECTED_ARTIFACT_SET_DIGEST=${_digest_b}"
  "-DEXPECTED_TRUSTED_EVIDENCE_DIGEST=${_digest_c}"
  "-DEXPECTED_CODEQL_REQUIRED=ON"
  "-DREQUIRE_ALLOW=ON")

function(_run_record name content allow_fixture expect_success expected_text)
  set(_record "${TEST_ROOT}/${name}.json")
  file(WRITE "${_record}" "${content}")
  execute_process(
    COMMAND "${CMAKE_COMMAND}" "-DAUTHORIZATION_RECORD=${_record}"
      ${_common_args} "-DALLOW_TEST_FIXTURE=${allow_fixture}" -P "${_validator}"
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
endfunction()

function(_reject_replacement name expected from to)
  string(REPLACE "${from}" "${to}" _case "${_allow}")
  if(_case STREQUAL _allow)
    message(FATAL_ERROR "${name}: fixture replacement did not change input")
  endif()
  _run_record("${name}" "${_case}" ON FALSE "${expected}")
endfunction()

execute_process(
  COMMAND "${CMAKE_COMMAND}" "-DAUTHORIZATION_RECORD=${DEFAULT_AUTHORIZATION_RECORD}"
    -DREQUIRE_ALLOW=OFF -P "${_validator}"
  RESULT_VARIABLE _default_result OUTPUT_VARIABLE _default_out ERROR_VARIABLE _default_err)
string(CONCAT _default_log "${_default_out}" "${_default_err}")
if(NOT _default_result EQUAL 0 OR NOT _default_log MATCHES "authorization: denied or unavailable")
  message(FATAL_ERROR "Default authorization record is not a valid denial\n${_default_log}")
endif()

_run_record(positive-test-only "${_allow}" ON TRUE "authorization: allowed")
_run_record(empty-record "" ON FALSE "Malformed release authorization JSON")
file(REMOVE "${TEST_ROOT}/empty-record.json")
execute_process(
  COMMAND "${CMAKE_COMMAND}" "-DAUTHORIZATION_RECORD=${TEST_ROOT}/absent.json"
    ${_common_args} -DALLOW_TEST_FIXTURE=ON -P "${_validator}"
  RESULT_VARIABLE _missing_result OUTPUT_VARIABLE _missing_out ERROR_VARIABLE _missing_err)
string(CONCAT _missing_log "${_missing_out}" "${_missing_err}")
if(_missing_result EQUAL 0 OR NOT _missing_log MATCHES "record is missing")
  message(FATAL_ERROR "missing-record: expected missing record rejection\n${_missing_log}")
endif()
_run_record(malformed "{" ON FALSE "Malformed release authorization JSON")
_reject_replacement(unknown-schema "Unsupported release authorization schema version"
  "\"schema_version\": \"1\"" "\"schema_version\": \"2\"")
_reject_replacement(missing-decision "field count mismatch"
  "  \"decision\": \"allow\",\n" "")
_reject_replacement(unknown-decision "Unsupported decision"
  "\"decision\": \"allow\"" "\"decision\": \"maybe\"")
_reject_replacement(duplicate-decision "Duplicate release authorization field"
  "  \"decision\": \"allow\",\n"
  "  \"decision\": \"allow\",\n  \"decision\": \"deny\",\n")
_reject_replacement(source-mismatch "source_revision mismatch"
  "\"source_revision\": \"${_sha_b}\"" "\"source_revision\": \"${_sha_a}\"")
_reject_replacement(enterprise-version-mismatch "enterprise_version mismatch"
  "\"enterprise_version\": \"0.1.0\"" "\"enterprise_version\": \"9.9.9\"")
_reject_replacement(community-version-mismatch "community_version mismatch"
  "\"community_version\": \"0.4.0\"" "\"community_version\": \"0.5.0\"")
_reject_replacement(community-tree-mismatch "community_tree mismatch"
  "\"community_tree\": \"${_sha_a}\"" "\"community_tree\": \"${_sha_b}\"")
_reject_replacement(partial-anocrypto-profile "backend_profile mismatch"
  "\"backend_profile\": \"openssl\"" "\"backend_profile\": \"anocrypto-c\"")
_reject_replacement(provider-family-mismatch "provider_family mismatch"
  "\"provider_family\": \"openssl\"" "\"provider_family\": \"anocrypto-c\"")
_reject_replacement(manifest-digest-mismatch "artifact_manifest_digest mismatch"
  "\"artifact_manifest_digest\": \"${_digest_a}\"" "\"artifact_manifest_digest\": \"${_digest_b}\"")
_reject_replacement(artifact-set-digest-mismatch "artifact_set_digest mismatch"
  "\"artifact_set_digest\": \"${_digest_b}\"" "\"artifact_set_digest\": \"${_digest_a}\"")
_reject_replacement(trusted-evidence-digest-mismatch "trusted_evidence_digest mismatch"
  "\"trusted_evidence_digest\": \"${_digest_c}\"" "\"trusted_evidence_digest\": \"${_digest_a}\"")
_reject_replacement(qualification-deferred "Qualification status does not permit release"
  "\"qualification_status\": \"qualified\"" "\"qualification_status\": \"deferred\"")
_reject_replacement(hosted-not-run "Hosted evidence does not permit release"
  "\"hosted_evidence_status\": \"passed\"" "\"hosted_evidence_status\": \"not-run\"")
_reject_replacement(hosted-blocked-external "Hosted evidence does not permit release"
  "\"hosted_evidence_status\": \"passed\"" "\"hosted_evidence_status\": \"blocked-external\"")
_reject_replacement(codeql-not-run "Required CodeQL evidence does not permit release"
  "\"codeql_status\": \"passed\"" "\"codeql_status\": \"not-run\"")
_reject_replacement(missing-signing-evidence "field count mismatch"
  "  \"signing_evidence_reference\": \"signing-evidence:sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\",\n" "")
_reject_replacement(missing-provenance-evidence "field count mismatch"
  "  \"provenance_evidence_reference\": \"provenance-evidence:sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb\",\n" "")
_reject_replacement(expired "expired or has an invalid validity interval"
  "\"expires_at\": \"2099-01-01T00:00:00Z\"" "\"expires_at\": \"2020-01-01T00:00:00Z\"")
_reject_replacement(future-authorization "expired or has an invalid validity interval"
  "\"authorized_at\": \"2026-01-01T00:00:00Z\"" "\"authorized_at\": \"2098-01-01T00:00:00Z\"")
_reject_replacement(revoked "Release authorization is revoked"
  "\"authorization_status\": \"active\"" "\"authorization_status\": \"revoked\"")
_reject_replacement(unknown-evidence-status "Unsupported hosted_evidence_status"
  "\"hosted_evidence_status\": \"passed\"" "\"hosted_evidence_status\": \"mystery\"")
_reject_replacement(local-absolute-path "contains a local absolute path"
  "Test-only positive fixture." "Generated at C:\\\\Users\\\\operator\\\\release.")
_reject_replacement(secret-like-field "field count mismatch"
  "  \"reason\": \"Test-only positive fixture.\",\n"
  "  \"api_token\": \"do-not-store\",\n  \"reason\": \"Test-only positive fixture.\",\n")
_reject_replacement(production-allow-unavailable
  "Production allow requires verified cryptographic and trusted evidence"
  "\"test_only\": true" "\"test_only\": false")
_run_record(test-fixture-production-rejection "${_allow}" OFF FALSE
  "Test-only release authorization cannot authorize production delivery")

message(STATUS "Release authorization contract checks passed: default deny, positive test fixture, 30 fail-closed cases")
