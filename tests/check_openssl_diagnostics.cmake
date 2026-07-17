# SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary
cmake_minimum_required(VERSION 3.20)

if(NOT DEFINED INFO_EXECUTABLE OR INFO_EXECUTABLE STREQUAL "")
  message(FATAL_ERROR "INFO_EXECUTABLE is required")
endif()

execute_process(
  COMMAND "${INFO_EXECUTABLE}"
  RESULT_VARIABLE _text_result
  OUTPUT_VARIABLE _text
  ERROR_VARIABLE _text_error)
if(NOT _text_result EQUAL 0)
  message(FATAL_ERROR "Text diagnostics failed with ${_text_result}: ${_text_error}")
endif()

set(_required_text
  "Enterprise version: 0.1.0"
  "Community version: 0.4.0"
  "Profile: openssl"
  "Actual provider family: openssl"
  "Provider source: AnoSecureKit Community"
  "Implementation: complete"
  "Local verification: passed"
  "Remote verification: deferred"
  "Evidence bundle: present"
  "Attestation generation: configured"
  "Verifier backend: unavailable"
  "Verifier backend id: none"
  "Verifier version: unavailable"
  "Structural evidence: unavailable"
  "Cryptographic evidence: unavailable"
  "Trusted evidence: unavailable"
  "Release authorization: denied or unavailable"
  "Customer release: blocked"
  "Install/export: enabled"
  "Internal delivery package: enabled"
  "metadata; runtime version not queried")
foreach(_term IN LISTS _required_text)
  string(FIND "${_text}" "${_term}" _position)
  if(_position EQUAL -1)
    message(FATAL_ERROR "Text diagnostics are missing: ${_term}\n${_text}")
  endif()
endforeach()

execute_process(
  COMMAND "${INFO_EXECUTABLE}" --json
  RESULT_VARIABLE _json_result
  OUTPUT_VARIABLE _json
  ERROR_VARIABLE _json_error)
if(NOT _json_result EQUAL 0)
  message(FATAL_ERROR "JSON diagnostics failed with ${_json_result}: ${_json_error}")
endif()

function(_expect_json field expected)
  string(JSON _actual ERROR_VARIABLE _error GET "${_json}" "${field}")
  if(_error OR NOT "${_actual}" STREQUAL "${expected}")
    message(FATAL_ERROR
      "JSON field ${field}: expected '${expected}', got '${_actual}': ${_error}\n${_json}")
  endif()
endfunction()

_expect_json(enterprise_version "0.1.0")
_expect_json(community_version "0.4.0")
_expect_json(profile "openssl")
_expect_json(provider_source "AnoSecureKit Community")
_expect_json(actual_provider_family "openssl")
_expect_json(implementation_complete "ON")
_expect_json(local_verification "passed")
_expect_json(remote_verification "deferred")
_expect_json(qualification_status "local-pass-remote-deferred")
_expect_json(evidence_bundle "present")
_expect_json(attestation_generation "configured")
_expect_json(verifier_backend "unavailable")
_expect_json(verifier_backend_id "none")
_expect_json(verifier_version "unavailable")
_expect_json(structural_evidence "unavailable")
_expect_json(cryptographic_evidence "unavailable")
_expect_json(trusted_evidence "unavailable")
_expect_json(release_authorization "denied-or-unavailable")
_expect_json(customer_release_ready "OFF")
_expect_json(install_enabled "ON")
_expect_json(internal_delivery_enabled "ON")
_expect_json(openssl_runtime_version_verified "OFF")

if(DEFINED ENTERPRISE_SOURCE_DIR AND NOT ENTERPRISE_SOURCE_DIR STREQUAL "")
  string(FIND "${_json}" "${ENTERPRISE_SOURCE_DIR}" _source_path)
  if(NOT _source_path EQUAL -1)
    message(FATAL_ERROR "JSON diagnostics expose the local source path")
  endif()
endif()

message(STATUS "Enterprise OpenSSL text and JSON diagnostics passed")
