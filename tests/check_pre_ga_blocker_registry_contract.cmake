# SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary
cmake_minimum_required(VERSION 3.20)

foreach(_required IN ITEMS ENTERPRISE_SOURCE_DIR TEST_ROOT GIT_EXECUTABLE)
  if(NOT DEFINED ${_required} OR "${${_required}}" STREQUAL "")
    message(FATAL_ERROR "${_required} is required")
  endif()
endforeach()

set(_checker "${ENTERPRISE_SOURCE_DIR}/cmake/check_pre_ga_blocker_registry.cmake")
set(_registry "${ENTERPRISE_SOURCE_DIR}/docs/PRE_GA_BLOCKER_REGISTRY.json")
file(READ "${_registry}" _valid_record)
string(JSON _evaluated_source_revision GET "${_valid_record}"
  evaluated_source_revision)

function(_run registry expected)
  execute_process(
    COMMAND "${CMAKE_COMMAND}"
      -DSOURCE_DIR=${ENTERPRISE_SOURCE_DIR}
      -DREGISTRY_FILE=${registry}
      -DGIT_EXECUTABLE=${GIT_EXECUTABLE}
      -P "${_checker}"
    RESULT_VARIABLE _result OUTPUT_VARIABLE _out ERROR_VARIABLE _err)
  string(CONCAT _log "${_out}" "${_err}")
  if(_result EQUAL 0 OR NOT _log MATCHES "${expected}")
    message(FATAL_ERROR
      "Pre-GA blocker registry mutation was not rejected as expected: ${expected}\n${_log}")
  endif()
endfunction()

function(_mutate name needle replacement expected)
  string(FIND "${_valid_record}" "${needle}" _position)
  if(_position EQUAL -1)
    message(FATAL_ERROR "${name}: mutation source text is missing")
  endif()
  string(REPLACE "${needle}" "${replacement}" _mutated "${_valid_record}")
  set(_path "${TEST_ROOT}/${name}.json")
  file(WRITE "${_path}" "${_mutated}")
  _run("${_path}" "${expected}")
endfunction()

file(REMOVE_RECURSE "${TEST_ROOT}")
file(MAKE_DIRECTORY "${TEST_ROOT}")
set(_valid_path "${TEST_ROOT}/valid.json")
file(WRITE "${_valid_path}" "${_valid_record}")
execute_process(
  COMMAND "${CMAKE_COMMAND}"
    -DSOURCE_DIR=${ENTERPRISE_SOURCE_DIR}
    -DREGISTRY_FILE=${_valid_path}
    -DGIT_EXECUTABLE=${GIT_EXECUTABLE}
    -P "${_checker}"
  RESULT_VARIABLE _valid_result OUTPUT_VARIABLE _valid_out ERROR_VARIABLE _valid_err)
if(NOT _valid_result EQUAL 0)
  message(FATAL_ERROR
    "Valid pre-GA blocker registry was rejected\n${_valid_out}${_valid_err}")
endif()

_mutate(duplicate-blocker-id PGA-OSSL-LOCAL-WSL PGA-OSSL-LOCAL-WINDOWS
  "Duplicate pre-GA blocker ID")
_mutate(unknown-status [=["status":"waiting-decision"]=]
  [=["status":"invented-status"]=] "Unsupported pre-GA blocker status")
_mutate(unknown-category [=["category":"organizational"]=]
  [=["category":"invented-category"]=] "Unsupported pre-GA blocker category")
_mutate(missing-owner [=["owner_role":]=] [=["omitted_owner_role":]=]
  "field count mismatch|Unknown pre-GA blocker field")
_mutate(wrong-repository-routing [=["owner_repository":"AnoCrypto-C"]=]
  [=["owner_repository":"AnoSecureKit-Enterprise"]=]
  "primitive/package blocker repository routing is incorrect")
_mutate(current-revision-mismatch
  "\"last_verified_revision\":\"${_evaluated_source_revision}\""
  [=["last_verified_revision":"0000000000000000000000000000000000000000"]=]
  "current revision mismatch")
_mutate(missing-required-evidence
  [=["required_evidence":["required:hosted-ubuntu-lanes:passed:exact-revision"]]=]
  [=["required_evidence":[]]=] "required evidence is missing")
_mutate(blocked-external-false-closure
  [=["blocker_id":"PGA-OSSL-HOSTED-UBUNTU","title":"Hosted Ubuntu execution","category":"external","scope":"openssl-ga","profile":"openssl","status":"blocked-external"]=]
  [=["blocker_id":"PGA-OSSL-HOSTED-UBUNTU","title":"Hosted Ubuntu execution","category":"external","scope":"openssl-ga","profile":"openssl","status":"verified-closed"]=]
  "false verified closure")
_mutate(anocrypto-primitive-as-enterprise-defect
  [=["category":"upstream","scope":"anocrypto-c-enablement"]=]
  [=["category":"technical","scope":"anocrypto-c-enablement"]=]
  "primitive/package blocker repository routing is incorrect")
_mutate(hosted-closed-by-local-pass
  [=["blocker_id":"PGA-OSSL-HOSTED-WINDOWS","title":"Hosted Windows execution","category":"external","scope":"openssl-ga","profile":"openssl","status":"blocked-external"]=]
  [=["blocker_id":"PGA-OSSL-HOSTED-WINDOWS","title":"Hosted Windows execution","category":"external","scope":"openssl-ga","profile":"openssl","status":"verified-closed"]=]
  "false verified closure")
_mutate(optional-enhancement-as-hard-blocker
  "Local Windows OpenSSL qualification" "Optional customer verification UX"
  "Optional enhancement cannot be classified")
_mutate(unsupported-product-as-ga
  "unsupported pre-release/internal qualification" "general availability"
  "falsely claims GA")
_mutate(customer-release-ready
  [=["customer_release_ready": false]=] [=["customer_release_ready": true]=]
  "cannot set customer_release_ready true")
_mutate(prohibited-kcmvp-claim
  "Local Windows OpenSSL qualification" "KCMVP validated OpenSSL qualification"
  "prohibited validation or GA claim")
_mutate(abstract-policy-task-without-blocker-id
  [=["blocker_id":]=] [=["abstract_policy_task":]=]
  "field count mismatch|Unknown pre-GA blocker field")

message(STATUS
  "Pre-GA blocker registry contract passed: valid registry and 15 fail-closed negative cases")
