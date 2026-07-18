# SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary
cmake_minimum_required(VERSION 3.20)

foreach(_required IN ITEMS ENTERPRISE_SOURCE_DIR TEST_ROOT)
  if(NOT DEFINED ${_required} OR "${${_required}}" STREQUAL "")
    message(FATAL_ERROR "${_required} is required")
  endif()
endforeach()

set(_checker
  "${ENTERPRISE_SOURCE_DIR}/cmake/check_security_system_activation_readiness.cmake")
set(_fixtures
  "${ENTERPRISE_SOURCE_DIR}/tests/fixtures/security-system-readiness")

function(_prepare root)
  file(REMOVE_RECURSE "${root}")
  file(MAKE_DIRECTORY "${root}")
  file(COPY "${_fixtures}/" DESTINATION "${root}")
endfunction()

function(_run root expected)
  execute_process(
    COMMAND "${CMAKE_COMMAND}"
      -DSOURCE_DIR=${ENTERPRISE_SOURCE_DIR}
      -DFIXTURE_DIR=${root}
      -P "${_checker}"
    RESULT_VARIABLE _result OUTPUT_VARIABLE _out ERROR_VARIABLE _err)
  string(CONCAT _log "${_out}" "${_err}")
  if(_result EQUAL 0 OR NOT _log MATCHES "${expected}")
    message(FATAL_ERROR
      "Security system readiness mutation was not rejected as expected: ${expected}\n${_log}")
  endif()
endfunction()

function(_mutate name relative_path needle replacement expected)
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
  _run("${_root}" "${expected}")
endfunction()

function(_mutate_pair name relative_path needle1 replacement1 needle2 replacement2 expected)
  set(_root "${TEST_ROOT}/${name}")
  _prepare("${_root}")
  set(_path "${_root}/${relative_path}")
  file(READ "${_path}" _content)
  foreach(_index RANGE 1 2)
    string(FIND "${_content}" "${needle${_index}}" _position)
    if(_position EQUAL -1)
      message(FATAL_ERROR "${name}: mutation source text ${_index} is missing")
    endif()
    string(REPLACE "${needle${_index}}" "${replacement${_index}}" _content "${_content}")
  endforeach()
  file(WRITE "${_path}" "${_content}")
  _run("${_root}" "${expected}")
endfunction()

function(_prepare_allow root relative_path)
  _prepare("${root}")
  set(_path "${root}/${relative_path}")
  file(READ "${_path}" _content)
  string(REPLACE [=["role_assignment_status": "unassigned"]=]
    [=["role_assignment_status": "assigned-test-only"]=] _content "${_content}")
  string(REPLACE [=["authentication_mode": "not-configured"]=]
    [=["authentication_mode": "credentialless-oidc"]=] _content "${_content}")
  string(REPLACE [=["not-run"]=] [=["passed"]=] _content "${_content}")
  string(REPLACE [=["backend_status": "unavailable"]=]
    [=["backend_status": "available"]=] _content "${_content}")
  string(REPLACE [=["last_operation_status": "unavailable"]=]
    [=["last_operation_status": "available"]=] _content "${_content}")
  string(REPLACE [=["operation_success": false]=]
    [=["operation_success": true]=] _content "${_content}")
  string(REPLACE [=["transaction_state": "not-started"]=]
    [=["transaction_state": "completed"]=] _content "${_content}")
  string(REPLACE [=["approved_at": null]=]
    [=["approved_at": "2000-01-01T00:00:00Z"]=] _content "${_content}")
  string(REPLACE [=["expires_at": null]=]
    [=["expires_at": "2999-01-01T00:00:00Z"]=] _content "${_content}")
  string(REPLACE [=["activation_ready": false]=]
    [=["activation_ready": true]=] _content "${_content}")
  string(REPLACE [=["trusted_evidence": "unavailable"]=]
    [=["trusted_evidence": "verified"]=] _content "${_content}")
  string(REPLACE [=["release_authorization": "denied-or-unavailable"]=]
    [=["release_authorization": "allowed"]=] _content "${_content}")
  string(REPLACE [=["activation_decision": "deny"]=]
    [=["activation_decision": "allow"]=] _content "${_content}")
  file(WRITE "${_path}" "${_content}")
endfunction()

function(_allow_mutate name relative_path needle replacement expected)
  set(_root "${TEST_ROOT}/${name}")
  _prepare_allow("${_root}" "${relative_path}")
  set(_path "${_root}/${relative_path}")
  file(READ "${_path}" _content)
  string(FIND "${_content}" "${needle}" _position)
  if(_position EQUAL -1)
    message(FATAL_ERROR "${name}: allow mutation source text is missing")
  endif()
  string(REPLACE "${needle}" "${replacement}" _content "${_content}")
  file(WRITE "${_path}" "${_content}")
  _run("${_root}" "${expected}")
endfunction()

set(_valid_root "${TEST_ROOT}/valid")
_prepare("${_valid_root}")
execute_process(
  COMMAND "${CMAKE_COMMAND}"
    -DSOURCE_DIR=${ENTERPRISE_SOURCE_DIR}
    -DFIXTURE_DIR=${_valid_root}
    -P "${_checker}"
  RESULT_VARIABLE _valid_result OUTPUT_VARIABLE _valid_out ERROR_VARIABLE _valid_err)
if(NOT _valid_result EQUAL 0)
  message(FATAL_ERROR
    "Valid security system readiness fixtures were rejected\n${_valid_out}${_valid_err}")
endif()

_mutate(unknown-system-type evidence-repository.json
  [=["system_type": "evidence-repository"]=]
  [=["system_type": "unknown-system"]=] "Unsupported.*system_type")
_mutate(missing-backend-id evidence-repository.json
  [=["backend_id": "test-only:unselected-backend"]=]
  [=["backend_id": ""]=] "backend_id is missing")
_mutate(personal-email evidence-repository.json
  [=["backend_version": "not-configured"]=]
  [=["backend_version": "person@example.invalid"]=] "personal")
_mutate(secret-token evidence-repository.json
  [=["backend_version": "not-configured"]=]
  [=["backend_version": "token=abc123"]=] "secret or private-key")
_mutate(private-key evidence-repository.json
  [=["environment": "test-only:contract-fixture"]=]
  [=["environment": "-----BEGIN PRIVATE KEY-----"]=] "secret or private-key")
_mutate(actual-credential-path evidence-repository.json
  [=["backend_version": "not-configured"]=]
  [=["backend_version": "credentials/production.json"]=] "credential")
_mutate(absolute-windows-path evidence-repository.json
  [=["backend_version": "not-configured"]=]
  [=["backend_version": "C:\\Users\\operator\\record.json"]=] "local absolute path")
_mutate(absolute-posix-path evidence-repository.json
  [=["backend_version": "not-configured"]=]
  [=["backend_version": "/home/operator/record.json"]=] "local absolute path")
_mutate(actual-account-id evidence-repository.json
  [=["backend_id": "test-only:unselected-backend"]=]
  [=["backend_id": "test-only:account-123456789012"]=] "account identifier")
_mutate(secret-url evidence-repository.json
  [=["backend_version": "not-configured"]=]
  [=["backend_version": "https://private.invalid/backend"]=] "URL")
_mutate(missing-test-only evidence-repository.json
  [=["test_only": true]=] [=["omitted_test_only": true]=]
  "field count mismatch|Unknown.*field")
_mutate(production-mode evidence-repository.json
  [=["environment": "test-only:contract-fixture"]=]
  [=["environment": "production"]=] "attempts production mode")
_mutate(silent-local-fallback evidence-repository.json
  [=["fallback_mode": "forbidden"]=]
  [=["fallback_mode": "silent-local"]=] "silent local fallback")
_mutate(unknown-backend-status evidence-repository.json
  [=["backend_status": "unavailable"]=]
  [=["backend_status": "unknown"]=] "Unsupported.*backend_status")
_mutate_pair(rate-limit-success evidence-repository.json
  [=["last_operation_status": "unavailable"]=]
  [=["last_operation_status": "rate-limited"]=]
  [=["operation_success": false]=] [=["operation_success": true]=]
  "cannot report rate-limit")
_mutate(partial-write-committed evidence-repository.json
  [=["transaction_state": "not-started"]=]
  [=["transaction_state": "partial-committed"]=] "committed partial write")
_mutate(customer-ready-before-activation evidence-repository.json
  [=["customer_release_ready": false]=]
  [=["customer_release_ready": true]=] "customer-ready before activation")
_mutate(evidence-without-retention evidence-repository.json
  "worm-retention" "retention-omitted" "missing,")
_mutate(tracker-without-workflow incident-tracker.json
  [=["workflow_states": ["reported"]=]
  [=["workflow_states": ["omitted-reported"]=] "missing,")
_mutate(archive-without-restore security-archive.json
  "restore-rehearsal" "restore-omitted" "missing,")
_mutate(unknown-capability evidence-repository.json
  "object-version-id" "unknown-capability" "missing,")
_mutate(unknown-gate-result evidence-repository.json
  [=["security.threat-model": "not-run"]=]
  [=["security.threat-model": "unknown"]=] "Unsupported.*gate result")

_allow_mutate(allow-unassigned evidence-repository.json
  [=["role_assignment_status": "assigned-test-only"]=]
  [=["role_assignment_status": "unassigned"]=] "cannot allow with unassigned roles")
_allow_mutate(allow-missing-threat-model evidence-repository.json
  [=["threat_model_status": "passed"]=]
  [=["omitted_threat_model_status": "passed"]=] "field count mismatch|Unknown.*field")
_allow_mutate(allow-missing-access-review evidence-repository.json
  [=["access_review_status": "passed"]=]
  [=["omitted_access_review_status": "passed"]=] "field count mismatch|Unknown.*field")
_allow_mutate(allow-missing-backup-restore evidence-repository.json
  [=["backup_restore_status": "passed"]=]
  [=["omitted_backup_restore_status": "passed"]=] "field count mismatch|Unknown.*field")
_allow_mutate(allow-missing-export evidence-repository.json
  [=["export_status": "passed"]=]
  [=["omitted_export_status": "passed"]=] "field count mismatch|Unknown.*field")
_allow_mutate(allow-missing-outage-test evidence-repository.json
  [=["outage_test_status": "passed"]=]
  [=["omitted_outage_test_status": "passed"]=] "field count mismatch|Unknown.*field")
_allow_mutate(allow-unavailable evidence-repository.json
  [=["backend_status": "available"]=]
  [=["backend_status": "unavailable"]=] "cannot allow an unavailable")
_allow_mutate(allow-degraded evidence-repository.json
  [=["backend_status": "available"]=]
  [=["backend_status": "degraded"]=] "cannot allow an unavailable or degraded")
_allow_mutate(allow-failed-revocation evidence-repository.json
  [=["revocation_test_status": "passed"]=]
  [=["revocation_test_status": "failed"]=] "missing required revocation_test_status")
_allow_mutate(expired-approval evidence-repository.json
  [=["expires_at": "2999-01-01T00:00:00Z"]=]
  [=["expires_at": "2001-01-01T00:00:00Z"]=] "approval is expired")
_allow_mutate(future-approval evidence-repository.json
  [=["approved_at": "2000-01-01T00:00:00Z"]=]
  [=["approved_at": "2998-01-01T00:00:00Z"]=] "approved_at is in the future")
_allow_mutate(auth-allow-without-trusted-evidence evidence-repository.json
  [=["trusted_evidence": "verified"]=]
  [=["trusted_evidence": "unavailable"]=]
  "trusted evidence")

message(STATUS
  "Security system activation readiness contract passed: valid deny fixtures and 34 fail-closed negative cases")
