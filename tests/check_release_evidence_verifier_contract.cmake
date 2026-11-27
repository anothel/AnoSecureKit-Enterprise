# SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary
cmake_minimum_required(VERSION 3.20)

foreach(_required IN ITEMS ENTERPRISE_SOURCE_DIR TEST_ROOT)
  if(NOT DEFINED ${_required} OR "${${_required}}" STREQUAL "")
    message(FATAL_ERROR "${_required} is required")
  endif()
endforeach()

file(REMOVE_RECURSE "${TEST_ROOT}")
file(MAKE_DIRECTORY "${TEST_ROOT}")
set(_adapter "${ENTERPRISE_SOURCE_DIR}/cmake/check_release_evidence_verifier.cmake")
set(_fixture "${ENTERPRISE_SOURCE_DIR}/tests/fixtures/fake_release_evidence_verifier.cmake")
set(_artifact "${TEST_ROOT}/artifact.zip")
set(_bundle "${TEST_ROOT}/attestation.json")
file(WRITE "${_artifact}" "test-only artifact\n")
file(WRITE "${_bundle}" "{}\n")
file(SHA256 "${_artifact}" _artifact_sha)
set(_sha "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb")
set(_repo "anothel/AnoSecureKit-Enterprise")
set(_workflow "${_repo}/.github/workflows/anosecurekit-enterprise-ci.yml")

set(_common
  "-DVERIFIER_EXECUTABLE=${CMAKE_COMMAND}"
  "-DTEST_VERIFIER_SCRIPT=${_fixture}"
  "-DALLOW_TEST_VERIFIER=ON"
  "-DARTIFACT_PATH=${_artifact}"
  "-DEXPECTED_SOURCE_REPOSITORY=${_repo}"
  "-DEXPECTED_SOURCE_REVISION=${_sha}"
  "-DEXPECTED_SUBJECT_NAME=artifact.zip"
  "-DEXPECTED_SUBJECT_DIGEST=sha256:${_artifact_sha}"
  "-DEXPECTED_WORKFLOW_IDENTITY=${_workflow}"
  "-DEXPECTED_TRUST_DOMAIN=https://token.actions.githubusercontent.com"
  "-DATTESTATION_REFERENCE=https://github.com/${_repo}/attestations/123"
  "-DATTESTATION_BUNDLE=${_bundle}"
  "-DREQUIRE_VERIFIED=ON")

# Use a probe to prove the helper is checked before the backend is invoked.
function(_check_helper_rejection name path diagnostic)
  set(_json "${TEST_ROOT}/${name}.json")
  file(WRITE "${_json}" "{\"verification_status\":\"verified\"}\n")
  execute_process(COMMAND "${CMAKE_COMMAND}" ${_common}
    "-DVERIFIER_CAPTURE_EXECUTABLE=${path}" "-DVERIFIER_JSON_OUTPUT=${_json}"
    -DPROBE_ONLY=ON -P "${_adapter}"
    RESULT_VARIABLE _result OUTPUT_VARIABLE _out ERROR_VARIABLE _err)
  string(REGEX REPLACE "[ \t\r\n]+" " " _log "${_out}${_err}")
  if(NOT _result EQUAL 1 OR NOT _log MATCHES "${diagnostic}")
    message(FATAL_ERROR "${name}: expected helper rejection\n${_out}${_err}")
  endif()
  file(READ "${_json}" _record)
  foreach(_field IN ITEMS verification_status trusted_evidence release_authorization customer_release_ready)
    string(JSON _${_field} GET "${_record}" "${_field}")
  endforeach()
  if(NOT _verification_status STREQUAL "rejected"
     OR NOT _trusted_evidence STREQUAL "unavailable"
     OR NOT _release_authorization STREQUAL "denied-or-unavailable"
     OR _customer_release_ready)
    message(FATAL_ERROR "${name}: stale or unexpected verifier evidence")
  endif()
  set_property(GLOBAL APPEND PROPERTY _negative_cases "${name}")
endfunction()

if(NOT DEFINED VERIFIER_CAPTURE_EXECUTABLE OR NOT EXISTS "${VERIFIER_CAPTURE_EXECUTABLE}"
   OR NOT DEFINED VERIFIER_CAPTURE_BUILD_RECEIPT OR NOT EXISTS "${VERIFIER_CAPTURE_BUILD_RECEIPT}")
  message(FATAL_ERROR "A built capture helper and its trusted build receipt are required")
endif()
get_filename_component(_helper_name "${VERIFIER_CAPTURE_EXECUTABLE}" NAME)
_check_helper_rejection(missing-capture-helper "${TEST_ROOT}/missing/${_helper_name}"
  "verifier capture helper is missing or unsafe")
_check_helper_rejection(missing-capture-receipt "${VERIFIER_CAPTURE_EXECUTABLE}"
  "trusted verifier capture identity is missing or unsafe")
list(APPEND _common "-DVERIFIER_CAPTURE_EXECUTABLE=${VERIFIER_CAPTURE_EXECUTABLE}"
  "-DVERIFIER_CAPTURE_BUILD_RECEIPT=${VERIFIER_CAPTURE_BUILD_RECEIPT}")
set(_wrong_helper "${TEST_ROOT}/mismatched-helper/${_helper_name}")
file(WRITE "${_wrong_helper}" "not the expected verifier capture helper")
file(SHA256 "${_wrong_helper}" _wrong_digest)
file(WRITE "${_wrong_helper}.sha256" "${_wrong_digest}")
_check_helper_rejection(mismatched-capture-helper "${_wrong_helper}"
  "verifier capture helper identity mismatch")

function(_run name mode expect_success expected_text)
  set(_json "${TEST_ROOT}/${name}.json")
  set(_text "${TEST_ROOT}/${name}.txt")
  set(_limits)
  if(mode STREQUAL "timeout")
    list(APPEND _limits -DVERIFIER_TIMEOUT_SECONDS=1)
  elseif(mode STREQUAL "excessive-output")
    list(APPEND _limits -DVERIFIER_MAX_OUTPUT_BYTES=128)
  endif()
  execute_process(
    COMMAND "${CMAKE_COMMAND}" ${_common} "-DTEST_VERIFIER_MODE=${mode}"
      ${_limits}
      "-DVERIFIER_JSON_OUTPUT=${_json}" "-DVERIFIER_TEXT_OUTPUT=${_text}"
      -P "${_adapter}"
    WORKING_DIRECTORY "${TEST_ROOT}"
    RESULT_VARIABLE _result OUTPUT_VARIABLE _out ERROR_VARIABLE _err)
  string(CONCAT _log "${_out}" "${_err}")
  if(expect_success AND NOT _result EQUAL 0)
    message(FATAL_ERROR "${name}: expected success\n${_log}")
  elseif(NOT expect_success AND _result EQUAL 0)
    message(FATAL_ERROR "${name}: unexpectedly succeeded\n${_log}")
  endif()
  if(NOT expected_text STREQUAL "")
    # CMake wraps fatal errors across lines.
    string(REGEX REPLACE "[ \t\r\n]+" " " _comparison_log "${_log}")
    string(FIND "${_comparison_log}" "${expected_text}" _found)
    if(_found EQUAL -1)
      message(FATAL_ERROR "${name}: expected '${expected_text}'\n${_log}")
    endif()
  endif()
  if(EXISTS "${_json}.tmp" OR EXISTS "${_text}.tmp")
    message(FATAL_ERROR "${name}: verifier temporary output was not cleaned")
  endif()
  if(expect_success)
    set_property(GLOBAL APPEND PROPERTY _positive_cases "${name}")
  else()
    set_property(GLOBAL APPEND PROPERTY _negative_cases "${name}")
  endif()
endfunction()

_run(valid valid TRUE "cryptographic_evidence: verified")
file(READ "${TEST_ROOT}/valid.json" _valid_json)
foreach(_field IN ITEMS attestation_generation verifier_backend verifier_backend_id
    executable_path_source verifier_version version_policy capability_status
    verification_status subject_digest source_repository source_revision
    attestation_reference trust_domain verification_timestamp test_mode
    cryptographic_evidence trusted_evidence release_authorization
    customer_release_ready)
  string(JSON _value ERROR_VARIABLE _json_error GET "${_valid_json}" "${_field}")
  if(_json_error)
    message(FATAL_ERROR "valid diagnostics missing ${_field}: ${_json_error}")
  endif()
endforeach()

_run(runner-environment-verified-identity runner-environment-verified-identity TRUE
  "cryptographic_evidence: verified")
_run(runner-environment-escaped-identity runner-environment-escaped-identity TRUE
  "cryptographic_evidence: verified")
_run(long-escaped-json long-escaped-json TRUE "cryptographic_evidence: verified")

foreach(_case IN ITEMS unsupported-version malformed-version capability-fail
    subcommand-missing timeout excessive-output malformed-json duplicate-json
    text-output missing-attestation multiple unsigned unsupported-predicate)
  if(_case STREQUAL "unsupported-version")
    set(_expected "unsupported GitHub CLI version")
  elseif(_case STREQUAL "excessive-output")
    set(_expected "exceeded verifier output limit")
  elseif(_case STREQUAL "missing-attestation")
    set(_expected "attestation unavailable")
  elseif(_case STREQUAL "multiple")
    set(_expected "ambiguous")
  else()
    set(_expected "Release evidence verifier failed")
  endif()
  _run("${_case}" "${_case}" FALSE "${_expected}")
endforeach()

_run(runner-environment-missing runner-environment-missing FALSE
  "missing certificate runnerEnvironment")
_run(runner-environment-duplicate runner-environment-duplicate FALSE
  "duplicate JSON object member")
_run(runner-environment-only-outside-certificate runner-environment-only-outside-certificate FALSE
  "unexpected runnerEnvironment path")
_run(runner-environment-misplaced runner-environment-misplaced FALSE
  "unexpected runnerEnvironment path")
_run(runner-environment-identity-without-certificate
  runner-environment-identity-without-certificate FALSE "missing certificate runnerEnvironment")
_run(runner-environment-identity-conflict runner-environment-identity-conflict FALSE
  "invalid verifiedIdentity runnerEnvironment")
_run(runner-environment-identity-missing runner-environment-identity-missing FALSE
  "invalid verifiedIdentity runnerEnvironment")
_run(runner-environment-identity-wrong-type runner-environment-identity-wrong-type FALSE
  "invalid verifiedIdentity runnerEnvironment")
_run(runner-environment-identity-not-object runner-environment-identity-not-object FALSE
  "invalid verifiedIdentity runnerEnvironment")
_run(runner-environment-identity-duplicate runner-environment-identity-duplicate FALSE
  "duplicate JSON object member")
_run(runner-environment-escaped-duplicate runner-environment-escaped-duplicate FALSE
  "duplicate JSON object member")
_run(duplicate-escaped-issuer duplicate-escaped-issuer FALSE "duplicate JSON object member")
_run(runner-environment-malformed runner-environment-malformed FALSE
  "malformed machine-readable verifier output")
_run(trailing-json-comma trailing-json-comma FALSE "malformed machine-readable verifier output")
_run(trailing-json-control trailing-json-control FALSE "malformed machine-readable verifier output")
_run(runner-environment-wrong-type runner-environment-wrong-type FALSE
  "self-hosted attestation is forbidden")
_run(runner-environment-self-hosted runner-environment-self-hosted FALSE
  "self-hosted attestation is forbidden")

_run(wrong-subject wrong-subject FALSE "attestation subject name or digest mismatch")
_run(wrong-digest wrong-digest FALSE "attestation subject name or digest mismatch")
_run(wrong-repository wrong-repository FALSE "verified repository or owner mismatch")
_run(wrong-owner wrong-owner FALSE "verified repository or owner mismatch")
_run(wrong-revision wrong-revision FALSE "verified source revision mismatch")
_run(wrong-workflow wrong-workflow FALSE "verified workflow identity mismatch")
_run(wrong-trust-domain wrong-trust-domain FALSE "verified trust domain mismatch")
foreach(_case IN ITEMS nonzero expired revoked)
  _run("${_case}" "${_case}" FALSE "verifier rejected the attestation")
endforeach()

execute_process(
  COMMAND "${CMAKE_COMMAND}" "-DVERIFIER_EXECUTABLE=${TEST_ROOT}/missing-gh"
    -DREQUIRE_VERIFIED=ON -P "${_adapter}"
  RESULT_VARIABLE _missing_result OUTPUT_VARIABLE _missing_out ERROR_VARIABLE _missing_err)
string(CONCAT _missing_log "${_missing_out}" "${_missing_err}")
if(_missing_result EQUAL 0 OR NOT _missing_log MATCHES "verifier executable unavailable")
  message(FATAL_ERROR "missing executable was not rejected\n${_missing_log}")
endif()
set_property(GLOBAL APPEND PROPERTY _negative_cases missing-executable)

execute_process(
  COMMAND "${CMAKE_COMMAND}" "-DVERIFIER_EXECUTABLE=${TEST_ROOT}"
    -DREQUIRE_VERIFIED=ON -P "${_adapter}"
  RESULT_VARIABLE _directory_result OUTPUT_VARIABLE _directory_out ERROR_VARIABLE _directory_err)
string(CONCAT _directory_log "${_directory_out}" "${_directory_err}")
if(_directory_result EQUAL 0 OR NOT _directory_log MATCHES "path is a directory")
  message(FATAL_ERROR "directory executable was not rejected\n${_directory_log}")
endif()
set_property(GLOBAL APPEND PROPERTY _negative_cases executable-directory)

execute_process(
  COMMAND "${CMAKE_COMMAND}" ${_common} -DTEST_VERIFIER_MODE=valid
    "-DARTIFACT_PATH=relative/artifact.zip" -P "${_adapter}"
  RESULT_VARIABLE _path_result OUTPUT_VARIABLE _path_out ERROR_VARIABLE _path_err)
string(CONCAT _path_log "${_path_out}" "${_path_err}")
if(_path_result EQUAL 0 OR NOT _path_log MATCHES "artifact path is missing, unsafe")
  message(FATAL_ERROR "unsafe local artifact path was not rejected\n${_path_log}")
endif()
set_property(GLOBAL APPEND PROPERTY _negative_cases unsafe-local-path)

set(_marker "${TEST_ROOT}/shell-injection-marker")
execute_process(
  COMMAND "${CMAKE_COMMAND}" ${_common} -DTEST_VERIFIER_MODE=valid
    "-DEXPECTED_SOURCE_REPOSITORY=${_repo};${CMAKE_COMMAND} -E touch ${_marker}"
    -P "${_adapter}"
  RESULT_VARIABLE _shell_result OUTPUT_VARIABLE _shell_out ERROR_VARIABLE _shell_err)
if(_shell_result EQUAL 0 OR EXISTS "${_marker}")
  message(FATAL_ERROR "shell metacharacter input was executed or accepted")
endif()
set_property(GLOBAL APPEND PROPERTY _negative_cases shell-metacharacter)

execute_process(
  COMMAND "${CMAKE_COMMAND}" ${_common} -DTEST_VERIFIER_MODE=valid
    -DALLOW_TEST_VERIFIER=OFF -P "${_adapter}"
  RESULT_VARIABLE _production_result OUTPUT_VARIABLE _production_out ERROR_VARIABLE _production_err)
string(CONCAT _production_log "${_production_out}" "${_production_err}")
if(_production_result EQUAL 0 OR NOT _production_log MATCHES "test verifier is forbidden")
  message(FATAL_ERROR "test verifier was accepted in production mode\n${_production_log}")
endif()
set_property(GLOBAL APPEND PROPERTY _negative_cases test-verifier-production)

get_property(_negative_cases GLOBAL PROPERTY _negative_cases)
list(LENGTH _negative_cases _negative_count)
get_property(_positive_cases GLOBAL PROPERTY _positive_cases)
list(LENGTH _positive_cases _positive_count)
message(STATUS
  "Release evidence verifier contract passed: fake isolated, ${_positive_count} positive and ${_negative_count} fail-closed cases")
