# SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary
cmake_minimum_required(VERSION 3.20)

foreach(_required IN ITEMS ENTERPRISE_SOURCE_DIR TEST_ROOT EXPECTED_SOURCE_REVISION)
  if(NOT DEFINED ${_required} OR "${${_required}}" STREQUAL "")
    message(FATAL_ERROR "${_required} is required")
  endif()
endforeach()

set(_checker "${ENTERPRISE_SOURCE_DIR}/cmake/check_security_tabletop.cmake")
set(_source_fixtures "${ENTERPRISE_SOURCE_DIR}/tests/fixtures/security-tabletop")

function(_prepare root)
  file(REMOVE_RECURSE "${root}")
  file(MAKE_DIRECTORY "${root}")
  file(COPY "${_source_fixtures}/" DESTINATION "${root}")
endfunction()

function(_run_mutation name relative_path needle replacement expected)
  set(_root "${TEST_ROOT}/${name}")
  _prepare("${_root}")
  set(_path "${_root}/${relative_path}")
  file(READ "${_path}" _content)
  string(FIND "${_content}" "${needle}" _position)
  if(_position EQUAL -1)
    message(FATAL_ERROR "${name}: mutation source text is missing")
  endif()
  string(REPLACE "${needle}" "${replacement}" _content "${_content}")
  file(WRITE "${_path}" "${_content}")
  execute_process(
    COMMAND "${CMAKE_COMMAND}"
      -DFIXTURE_DIR=${_root}
      -DEXPECTED_SOURCE_REVISION=${EXPECTED_SOURCE_REVISION}
      -P "${_checker}"
    RESULT_VARIABLE _result OUTPUT_VARIABLE _out ERROR_VARIABLE _err)
  string(CONCAT _log "${_out}" "${_err}")
  if(_result EQUAL 0 OR NOT _log MATCHES "${expected}")
    message(FATAL_ERROR "${name}: tabletop mutation was not rejected\n${_log}")
  endif()
endfunction()

set(_valid_root "${TEST_ROOT}/valid")
_prepare("${_valid_root}")
execute_process(
  COMMAND "${CMAKE_COMMAND}"
    -DFIXTURE_DIR=${_valid_root}
    -DEXPECTED_SOURCE_REVISION=${EXPECTED_SOURCE_REVISION}
    -P "${_checker}"
  RESULT_VARIABLE _valid_result OUTPUT_VARIABLE _valid_out ERROR_VARIABLE _valid_err)
if(NOT _valid_result EQUAL 0)
  message(FATAL_ERROR
    "Valid security tabletop fixtures were rejected\n${_valid_out}${_valid_err}")
endif()

_run_mutation(unknown-severity scenario-a.json
  "\"severity\": \"critical\"" "\"severity\": \"urgent\""
  "Unsupported tabletop severity")
_run_mutation(missing-scenario-id scenario-a.json
  "  \"scenario_id\": \"A\",\n" ""
  "Tabletop root field count mismatch")
_run_mutation(personal-email scenario-a.json
  "test-only:community-tree:9b498f5431f217ac71e8d2e2c92df9e8b0122626"
  "test-only:person@example.invalid"
  "contains personal email data")
_run_mutation(personal-name scenario-a.json
  "\"routing_owner\": \"community-liaison\""
  "\"routing_owner\": \"Alice Example\""
  "Unsupported tabletop routing_owner")
_run_mutation(secret-token scenario-a.json
  "test-only:community-tree:9b498f5431f217ac71e8d2e2c92df9e8b0122626"
  "test-only:token=abc123"
  "contains secret-like data")
_run_mutation(private-key scenario-a.json
  "test-only:community-tree:9b498f5431f217ac71e8d2e2c92df9e8b0122626"
  "test-only:-----BEGIN PRIVATE KEY-----"
  "contains secret-like data")
_run_mutation(critical-release-allowed scenario-a.json
  "\"authorization_action\": \"deny\""
  "\"authorization_action\": \"allow\""
  "Critical/high tabletop incident cannot allow release")
_run_mutation(compromised-evidence-verified scenario-c.json
  "\"trusted_evidence\": \"rejected\""
  "\"trusted_evidence\": \"verified\""
  "final_decision.trusted_evidence must be 'rejected'")
_run_mutation(revoked-customer-ready scenario-d.json
  "\"customer_release_ready\": false"
  "\"customer_release_ready\": true"
  "Customer release readiness must remain false")
_run_mutation(anocrypto-openssl-fallback scenario-c.json
  "\"fallback_action\": \"none\""
  "\"fallback_action\": \"openssl\""
  "OpenSSL fallback is forbidden")
_run_mutation(community-private-patch scenario-a.json
  "\"remediation_path\": \"consume-new-community-revision\""
  "\"remediation_path\": \"enterprise-private-patch\""
  "remediation_path must be 'consume-new-community-revision'")
_run_mutation(adapter-primitive-misroute scenario-b.json
  "\"routing_owner\": \"product-owner\""
  "\"routing_owner\": \"anocrypto-c-liaison\""
  "routing_owner must be 'product-owner'")
_run_mutation(invalid-evidence-reuse scenario-c.json
  "\"evidence_action\": \"reject\""
  "\"evidence_action\": \"reuse\""
  "cannot reuse or verify affected evidence")
_run_mutation(production-mode scenario-a.json
  "\"execution_mode\": \"test-only\""
  "\"execution_mode\": \"production\""
  "cannot run in production mode")
_run_mutation(unsupported-profile-delivery scenario-b.json
  "\"customer_delivery_target\": false"
  "\"customer_delivery_target\": true"
  "Customer release readiness must remain false")
_run_mutation(reauthorization-before-closure scenario-a.json
  "\"authorization_action\": \"deny\""
  "\"authorization_action\": \"reauthorize-before-closure\""
  "reauthorization before closure is forbidden")
_run_mutation(closure-without-requalification scenario-a.json
  "    \"requalifying\",\n" ""
  "cannot close without requalification")
_run_mutation(future-reported-at scenario-a.json
  "\"reported_at\": \"2026-07-17T00:00:00Z\""
  "\"reported_at\": \"2999-07-17T00:00:00Z\""
  "reported_at is in the future")
_run_mutation(unknown-owner scenario-c.json
  "\"routing_owner\": \"anocrypto-c-liaison\""
  "\"routing_owner\": \"unknown-owner\""
  "Unsupported tabletop routing_owner")
_run_mutation(unknown-field scenario-a.json
  "  \"customer_delivery_target\": false\n}"
  "  \"customer_delivery_target\": false,\n  \"unknown_field\": \"rejected\"\n}"
  "Tabletop root field count mismatch")

message(STATUS
  "Security tabletop contract passed: valid scenarios and 20 fail-closed negative cases")
