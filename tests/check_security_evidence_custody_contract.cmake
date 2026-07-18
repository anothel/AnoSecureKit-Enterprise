# SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary
cmake_minimum_required(VERSION 3.20)

foreach(_required IN ITEMS ENTERPRISE_SOURCE_DIR TEST_ROOT EXPECTED_COMMUNITY_TREE)
  if(NOT DEFINED ${_required} OR "${${_required}}" STREQUAL "")
    message(FATAL_ERROR "${_required} is required")
  endif()
endforeach()

set(_checker "${ENTERPRISE_SOURCE_DIR}/cmake/check_security_evidence_custody.cmake")
set(_fixtures "${ENTERPRISE_SOURCE_DIR}/tests/fixtures/security-custody")
set(_tabletop "${ENTERPRISE_SOURCE_DIR}/tests/fixtures/security-tabletop")

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
      -DTABLETOP_FIXTURE_DIR=${_tabletop}
      -DEXPECTED_COMMUNITY_TREE=${EXPECTED_COMMUNITY_TREE}
      -P "${_checker}"
    RESULT_VARIABLE _result OUTPUT_VARIABLE _out ERROR_VARIABLE _err)
  string(CONCAT _log "${_out}" "${_err}")
  if(_result EQUAL 0 OR NOT _log MATCHES "${expected}")
    message(FATAL_ERROR "Security custody mutation was not rejected as expected: ${expected}\n${_log}")
  endif()
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
  _run("${_root}" "${expected}")
endfunction()

function(_run_remove name relative_path expected)
  set(_root "${TEST_ROOT}/${name}")
  _prepare("${_root}")
  file(REMOVE "${_root}/${relative_path}")
  _run("${_root}" "${expected}")
endfunction()

set(_valid_root "${TEST_ROOT}/valid")
_prepare("${_valid_root}")
execute_process(
  COMMAND "${CMAKE_COMMAND}"
    -DSOURCE_DIR=${ENTERPRISE_SOURCE_DIR}
    -DFIXTURE_DIR=${_valid_root}
    -DTABLETOP_FIXTURE_DIR=${_tabletop}
    -DEXPECTED_COMMUNITY_TREE=${EXPECTED_COMMUNITY_TREE}
    -P "${_checker}"
  RESULT_VARIABLE _valid_result OUTPUT_VARIABLE _valid_out ERROR_VARIABLE _valid_err)
if(NOT _valid_result EQUAL 0)
  message(FATAL_ERROR "Valid security custody fixtures were rejected\n${_valid_out}${_valid_err}")
endif()

_run_mutation(duplicate-record-id custody/scenario-f.json
  "test-only:custody-f" "test-only:custody-a" "Duplicate security custody record ID")
_run_mutation(duplicate-evidence-id custody/scenario-f.json
  "test-only:evidence-f" "test-only:evidence-a" "Duplicate security custody evidence ID")
_run_mutation(duplicate-decision-id decisions/scenario-b.jsonl
  "test-only:decision-b-02" "test-only:decision-b-01" "Duplicate security decision ID")
_run_remove(missing-custody custody/scenario-f.json "exactly 6 _custody_files")
_run_remove(missing-original-evidence evidence/scenario-a.txt "exactly 6 _evidence_files")
_run_mutation(decision-sequence-gap decisions/scenario-a.jsonl
  [=["sequence":2]=] [=["sequence":3]=] "decision sequence gap")
_run_mutation(transfer-sequence-gap custody/scenario-a.json
  [=["sequence":  2]=] [=["sequence":  3]=] "transfer sequence gap or reorder")
_run_mutation(reordered-transfer custody/scenario-a.json
  "2026-07-18T00:02:00Z" "2026-07-17T23:59:00Z" "transfer timestamps are reordered")
_run_mutation(previous-entry-digest-mismatch custody/scenario-a.json
  [=["previous_entry_digest":  "sha256:f6d9d5e7159829fc39ac9eea23b008fec596967f7f00ab5ab914f7e0ff43e8b8"]=]
  [=["previous_entry_digest":  "sha256:0000000000000000000000000000000000000000000000000000000000000000"]=]
  "previous entry digest mismatch")
_run_mutation(previous-decision-digest-mismatch decisions/scenario-a.jsonl
  [=["previous_decision_digest":"sha256:d15100128f05932154dd110aa41888bd91a8decd97b3d79ab73f46b02ed986ae"]=]
  [=["previous_decision_digest":"sha256:0000000000000000000000000000000000000000000000000000000000000000"]=]
  "decision previous digest mismatch")
_run_mutation(evidence-sha-mismatch custody/scenario-a.json
  "sha256:435b3e26019e118f50e7a4b707d37598b671782af7ac8fafadc18543259df2d7"
  "sha256:435b3e26019e118f50e7a4b707d37598b671782af7ac8fafadc18543259df2d8"
  "evidence SHA mismatch")
_run_mutation(invalid-sha-format custody/scenario-a.json
  "sha256:435b3e26019e118f50e7a4b707d37598b671782af7ac8fafadc18543259df2d7"
  "sha256:not-a-digest" "must use sha256")
_run_mutation(negative-size custody/scenario-a.json
  [=["size":  219]=] [=["size":  -1]=] "size must be non-negative")
_run_mutation(overflow-size custody/scenario-a.json
  [=["size":  219]=] [=["size":  9223372036854775808]=] "size exceeds signed 64-bit range")
_run_mutation(future-collection custody/scenario-a.json
  "2026-07-18T00:00:00Z" "2999-07-18T00:00:00Z" "collected_at is in the future")
_run_mutation(unknown-custodian custody/scenario-a.json
  [=["custodian_role":  "evidence-reviewer"]=] [=["custodian_role":  "unknown-custodian"]=]
  "Unsupported security custody custodian_role")
_run_mutation(personal-email custody/scenario-a.json
  "test-only:custody-a" "person@example.invalid" "contains personal email data")
_run_mutation(personal-name custody/scenario-a.json
  [=["custodian_role":  "evidence-reviewer"]=] [=["custodian_role":  "Alice Example"]=]
  "Unsupported security custody custodian_role")
_run_mutation(secret-token custody/scenario-a.json
  "test-only:custody-a" "test-only:token=abc123" "contains secret-like data")
_run_mutation(private-key custody/scenario-a.json
  "initial synthetic collection" "-----BEGIN PRIVATE KEY-----" "contains secret-like data")
_run_mutation(absolute-windows-path custody/scenario-a.json
  "evidence/scenario-a.txt" [=[C:\\temp\\scenario-a.txt]=]
  "local absolute path|scenario-relative evidence path")
_run_mutation(absolute-posix-path custody/scenario-a.json
  "evidence/scenario-a.txt" "/home/test/scenario-a.txt"
  "local absolute path|scenario-relative evidence path")
_run_mutation(missing-test-only-marker custody/scenario-a.json
  [=["test_only":  true]=] [=["omitted_test_only":  true]=] "Unknown custody root field")
_run_mutation(production-use decisions/scenario-a.jsonl
  [=["test_only":true]=] [=["test_only":false]=] "require test-only markers")
_run_mutation(missing-evidence-reference decisions/scenario-a.jsonl
  [=["evidence_references":["test-only:evidence-a"]]=] [=["evidence_references":[]]=]
  "evidence reference is missing")
_run_mutation(critical-release-allow decisions/scenario-a.jsonl
  "deny-customer-release" "allow-customer-release" "Critical/high incident cannot allow")
_run_mutation(revoked-evidence-verified decisions/scenario-c.jsonl
  [=["trusted_evidence_status":"rejected"]=] [=["trusted_evidence_status":"verified"]=]
  "cannot remain trusted verified")
_run_mutation(revoked-authorization-customer-ready decisions/scenario-d.jsonl
  [=["customer_release_ready":false]=] [=["customer_release_ready":true]=]
  "cannot be customer-ready")
_run_mutation(closure-before-requalification decisions/scenario-a.jsonl
  [=["decision_type":"triage","decision":"record-triage"]=]
  [=["decision_type":"incident-closure","decision":"close-after-requalification"]=]
  "closure requires prior requalification")
_run_mutation(community-private-patch decisions/scenario-a.jsonl
  "route-community" "enterprise-private-patch" "decision routing is incorrect")
_run_mutation(anocrypto-openssl-fallback decisions/scenario-c.jsonl
  "require-upstream-package-replacement" "openssl-fallback" "forbids OpenSSL fallback")
_run_mutation(adapter-primitive-misclassification decisions/scenario-b.jsonl
  "AnoSecureKit Enterprise" "AnoCrypto-C" "does not match tabletop product boundary")
_run_mutation(legal-hold-auto-delete custody/scenario-d.json
  "preserved-legal-hold" "deleted" "Unsupported security custody final_disposition")
_run_mutation(altered-prior-decision decisions/scenario-a.jsonl
  "record synthetic incident scope and evidence" "altered synthetic incident scope and evidence"
  "decision digest mismatch")
_run_mutation(missing-final-disposition custody/scenario-a.json
  [=[    "final_disposition":  "retained",
]=] "" "Custody root field count mismatch")
_run_mutation(unknown-decision decisions/scenario-a.jsonl
  "record-triage" "unknown-decision" "Unsupported security custody decision")
_run_mutation(unknown-status decisions/scenario-a.jsonl
  [=["status":"recorded"]=] [=["status":"unknown"]=] "Unsupported security custody status")
_run_mutation(empty-rationale decisions/scenario-a.jsonl
  "record synthetic incident scope and evidence" "" "rationale must not be empty")
_run_mutation(source-revision-mismatch custody/scenario-f.json
  "ea3b9d0dae40a359ecdb9cde8116d152a20b5a81"
  "0000000000000000000000000000000000000000" "source revisions do not match")

message(STATUS
  "Security evidence custody contract passed: valid A-F fixtures and 39 fail-closed negative cases")
