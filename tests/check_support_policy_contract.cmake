# SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary
cmake_minimum_required(VERSION 3.20)

foreach(_required IN ITEMS ENTERPRISE_SOURCE_DIR TEST_ROOT)
  if(NOT DEFINED ${_required} OR "${${_required}}" STREQUAL "")
    message(FATAL_ERROR "${_required} is required")
  endif()
endforeach()

set(_checker "${ENTERPRISE_SOURCE_DIR}/cmake/check_support_policy.cmake")

function(_prepare root)
  file(REMOVE_RECURSE "${root}")
  file(MAKE_DIRECTORY "${root}/docs" "${root}/packaging")
  file(COPY "${ENTERPRISE_SOURCE_DIR}/README.md"
    "${ENTERPRISE_SOURCE_DIR}/SECURITY.md"
    "${ENTERPRISE_SOURCE_DIR}/LICENSE"
    "${ENTERPRISE_SOURCE_DIR}/THIRD_PARTY_NOTICES.md" DESTINATION "${root}")
  file(COPY "${ENTERPRISE_SOURCE_DIR}/docs/" DESTINATION "${root}/docs")
  file(COPY "${ENTERPRISE_SOURCE_DIR}/packaging/DELIVERY_README.md.in"
    DESTINATION "${root}/packaging")
endfunction()

function(_run_negative name relative_path needle replacement expected)
  set(_root "${TEST_ROOT}/${name}")
  _prepare("${_root}")
  set(_path "${_root}/${relative_path}")
  if(needle STREQUAL "REMOVE")
    file(REMOVE "${_path}")
  else()
    file(READ "${_path}" _content)
    string(FIND "${_content}" "${needle}" _position)
    if(_position EQUAL -1)
      message(FATAL_ERROR "${name}: mutation source text is missing")
    endif()
    string(REPLACE "${needle}" "${replacement}" _content "${_content}")
    file(WRITE "${_path}" "${_content}")
  endif()
  execute_process(
    COMMAND "${CMAKE_COMMAND}" -DENTERPRISE_SOURCE_DIR=${_root} -P "${_checker}"
    RESULT_VARIABLE _result OUTPUT_VARIABLE _out ERROR_VARIABLE _err)
  string(CONCAT _log "${_out}" "${_err}")
  if(_result EQUAL 0 OR NOT _log MATCHES "${expected}")
    message(FATAL_ERROR "${name}: policy mutation was not rejected\n${_log}")
  endif()
endfunction()

set(_valid_root "${TEST_ROOT}/valid")
_prepare("${_valid_root}")
execute_process(
  COMMAND "${CMAKE_COMMAND}" -DENTERPRISE_SOURCE_DIR=${_valid_root} -P "${_checker}"
  RESULT_VARIABLE _valid_result OUTPUT_VARIABLE _valid_out ERROR_VARIABLE _valid_err)
if(NOT _valid_result EQUAL 0)
  message(FATAL_ERROR "Valid support policy was rejected\n${_valid_out}${_valid_err}")
endif()

_run_negative(missing-document docs/SUPPORT_LIFECYCLE_POLICY.md REMOVE ""
  "Required support policy document is missing")
_run_negative(missing-readme-link README.md
  "[Security policy](SECURITY.md)" "Security policy"
  "README document index is missing")
_run_negative(wrong-owner docs/VULNERABILITY_RESPONSE_POLICY.md
  "| OpenSSL provider defect | AnoSecureKit Community |"
  "| OpenSSL provider defect | AnoSecureKit Enterprise |"
  "Support policy contract is missing")
_run_negative(customer-ready SECURITY.md
  "customer_release_ready: false" "customer_release_ready: true"
  "Unsupported support/security claim is forbidden")
_run_negative(false-sla docs/VULNERABILITY_RESPONSE_POLICY.md
  "not a contractual SLA" "not a contractual SLA; contractual SLA applies"
  "Unsupported support/security claim is forbidden")
_run_negative(false-validation docs/SECURITY_RELEASE_AND_REVOCATION_POLICY.md
  "No KCMVP or FIPS validation is claimed"
  "No KCMVP or FIPS validation is claimed.\nFIPS validation: passed"
  "Unsupported support/security claim is forbidden")
_run_negative(invented-email SECURITY.md
  "security contact: not yet published"
  "security contact: security@example.invalid"
  "must not invent a security email address")

message(STATUS "Support policy contract passed: valid policy and 7 negative cases")
