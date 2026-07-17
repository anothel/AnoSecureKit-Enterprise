# SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary
cmake_minimum_required(VERSION 3.20)

if(NOT DEFINED REQUIRE_VERIFIED)
  set(REQUIRE_VERIFIED OFF)
endif()
if(NOT DEFINED PROBE_ONLY)
  set(PROBE_ONLY OFF)
endif()
if(NOT DEFINED ALLOW_TEST_VERIFIER)
  set(ALLOW_TEST_VERIFIER OFF)
endif()
if(NOT DEFINED VERIFIER_TIMEOUT_SECONDS)
  set(VERIFIER_TIMEOUT_SECONDS 15)
endif()
if(NOT DEFINED VERIFIER_MAX_OUTPUT_BYTES)
  set(VERIFIER_MAX_OUTPUT_BYTES 1048576)
endif()
if(NOT VERIFIER_TIMEOUT_SECONDS MATCHES "^[1-9][0-9]*$"
   OR VERIFIER_TIMEOUT_SECONDS GREATER 60)
  message(FATAL_ERROR "VERIFIER_TIMEOUT_SECONDS must be an integer from 1 to 60")
endif()
if(NOT VERIFIER_MAX_OUTPUT_BYTES MATCHES "^[1-9][0-9]*$")
  message(FATAL_ERROR "VERIFIER_MAX_OUTPUT_BYTES must be a positive integer")
endif()

set(_backend_id none)
set(_path_source none)
set(_version unavailable)
set(_version_policy unavailable)
set(_backend unavailable)
set(_capability unavailable)
set(_verification unavailable)
set(_subject_digest unavailable)
set(_source_repository unavailable)
set(_source_revision unavailable)
set(_attestation_reference unavailable)
set(_trust_domain unavailable)
set(_reason "verifier executable unavailable")
set(_test_mode false)
if(DEFINED TEST_VERIFIER_SCRIPT AND NOT TEST_VERIFIER_SCRIPT STREQUAL "")
  set(_test_mode true)
endif()
if(DEFINED ATTESTATION_GENERATION_STATUS AND NOT ATTESTATION_GENERATION_STATUS STREQUAL "")
  set(_attestation_generation "${ATTESTATION_GENERATION_STATUS}")
else()
  set(_attestation_generation configured)
endif()
if(NOT _attestation_generation MATCHES
    "^(configured|generated|unavailable|blocked-external)$")
  message(FATAL_ERROR "Unsupported ATTESTATION_GENERATION_STATUS")
endif()

function(_verifier_write path content)
  if(path STREQUAL "")
    return()
  endif()
  get_filename_component(_directory "${path}" DIRECTORY)
  file(MAKE_DIRECTORY "${_directory}")
  file(REMOVE "${path}.tmp")
  file(WRITE "${path}.tmp" "${content}")
  file(RENAME "${path}.tmp" "${path}")
endfunction()

macro(_verifier_finish fail)
  string(TIMESTAMP _timestamp "%Y-%m-%dT%H:%M:%SZ" UTC)
  set(_text
    "attestation_generation: ${_attestation_generation}\n"
    "verifier_backend: ${_backend}\n"
    "verifier_backend_id: ${_backend_id}\n"
    "executable_path_source: ${_path_source}\n"
    "verifier_version: ${_version}\n"
    "version_policy: ${_version_policy}\n"
    "capability_status: ${_capability}\n"
    "verification_status: ${_verification}\n"
    "subject_digest: ${_subject_digest}\n"
    "source_repository: ${_source_repository}\n"
    "source_revision: ${_source_revision}\n"
    "attestation_reference: ${_attestation_reference}\n"
    "trust_domain: ${_trust_domain}\n"
    "verification_timestamp: ${_timestamp}\n"
    "test_mode: ${_test_mode}\n"
    "cryptographic_evidence: ${_verification}\n"
    "trusted_evidence: unavailable\n"
    "release_authorization: denied-or-unavailable\n"
    "customer_release_ready: false\n")
  string(REPLACE ";" "" _text "${_text}")
  if(DEFINED VERIFIER_TEXT_OUTPUT)
    _verifier_write("${VERIFIER_TEXT_OUTPUT}" "${_text}")
  endif()

  set(_json
    "{\"attestation_generation\":\"${_attestation_generation}\""
    ",\"verifier_backend\":\"${_backend}\""
    ",\"verifier_backend_id\":\"${_backend_id}\""
    ",\"executable_path_source\":\"${_path_source}\""
    ",\"verifier_version\":\"${_version}\""
    ",\"version_policy\":\"${_version_policy}\""
    ",\"capability_status\":\"${_capability}\""
    ",\"verification_status\":\"${_verification}\""
    ",\"subject_digest\":\"${_subject_digest}\""
    ",\"source_repository\":\"${_source_repository}\""
    ",\"source_revision\":\"${_source_revision}\""
    ",\"attestation_reference\":\"${_attestation_reference}\""
    ",\"trust_domain\":\"${_trust_domain}\""
    ",\"verification_timestamp\":\"${_timestamp}\""
    ",\"test_mode\":${_test_mode}"
    ",\"cryptographic_evidence\":\"${_verification}\""
    ",\"trusted_evidence\":\"unavailable\""
    ",\"release_authorization\":\"denied-or-unavailable\""
    ",\"customer_release_ready\":false}\n")
  string(REPLACE ";" "" _json "${_json}")
  if(DEFINED VERIFIER_JSON_OUTPUT)
    _verifier_write("${VERIFIER_JSON_OUTPUT}" "${_json}")
  endif()

  foreach(_line IN LISTS _text)
    string(REGEX REPLACE "\n$" "" _line "${_line}")
    if(NOT _line STREQUAL "")
      message(STATUS "${_line}")
    endif()
  endforeach()
  if(${fail})
    message(FATAL_ERROR "Release evidence verifier failed: ${_reason}")
  endif()
  return()
endmacro()

function(_verifier_output_within_limit stdout stderr label)
  string(LENGTH "${stdout}" _stdout_size)
  string(LENGTH "${stderr}" _stderr_size)
  if(_stdout_size GREATER VERIFIER_MAX_OUTPUT_BYTES
     OR _stderr_size GREATER VERIFIER_MAX_OUTPUT_BYTES)
    message(FATAL_ERROR "${label} exceeded verifier output limit")
  endif()
endfunction()

if(_test_mode AND NOT ALLOW_TEST_VERIFIER)
  set(_backend error)
  set(_capability error)
  set(_reason "test verifier is forbidden outside explicit test mode")
  _verifier_finish(TRUE)
endif()

if(DEFINED VERIFIER_EXECUTABLE AND NOT VERIFIER_EXECUTABLE STREQUAL "")
  set(_verifier "${VERIFIER_EXECUTABLE}")
  set(_path_source user-specified)
elseif(DEFINED INSTALLED_VERIFIER_EXECUTABLE
       AND NOT INSTALLED_VERIFIER_EXECUTABLE STREQUAL "")
  set(_verifier "${INSTALLED_VERIFIER_EXECUTABLE}")
  set(_path_source installed-metadata)
else()
  unset(_verifier CACHE)
  find_program(_verifier NAMES gh gh.exe)
  set(_path_source PATH)
endif()

if(NOT _verifier OR NOT EXISTS "${_verifier}")
  set(_reason "verifier executable unavailable")
  _verifier_finish(REQUIRE_VERIFIED)
endif()
if(IS_DIRECTORY "${_verifier}")
  set(_backend error)
  set(_capability error)
  set(_reason "verifier executable path is a directory")
  _verifier_finish(TRUE)
endif()
if(NOT IS_ABSOLUTE "${_verifier}")
  set(_backend error)
  set(_capability error)
  set(_reason "verifier executable path must be absolute")
  _verifier_finish(TRUE)
endif()
get_filename_component(_verifier_name "${_verifier}" NAME)
string(TOLOWER "${_verifier_name}" _verifier_name)
if(NOT _test_mode AND NOT _verifier_name MATCHES "^gh(\.exe)?$")
  set(_backend error)
  set(_capability error)
  set(_reason "production verifier executable identity is not gh")
  _verifier_finish(TRUE)
endif()

set(_command "${_verifier}")
if(_test_mode)
  if(NOT EXISTS "${TEST_VERIFIER_SCRIPT}" OR IS_DIRECTORY "${TEST_VERIFIER_SCRIPT}")
    set(_backend error)
    set(_capability error)
    set(_reason "test verifier fixture is missing")
    _verifier_finish(TRUE)
  endif()
  if(NOT DEFINED TEST_VERIFIER_MODE OR TEST_VERIFIER_MODE STREQUAL "")
    set(TEST_VERIFIER_MODE valid)
  endif()
  list(APPEND _command
    "-DFAKE_MODE=${TEST_VERIFIER_MODE}"
    "-DFAKE_REPOSITORY=${EXPECTED_SOURCE_REPOSITORY}"
    "-DFAKE_REVISION=${EXPECTED_SOURCE_REVISION}"
    "-DFAKE_SUBJECT_DIGEST=${EXPECTED_SUBJECT_DIGEST}"
    "-DFAKE_SUBJECT_NAME=${EXPECTED_SUBJECT_NAME}"
    "-DFAKE_WORKFLOW=${EXPECTED_WORKFLOW_IDENTITY}"
    "-DFAKE_TRUST_DOMAIN=${EXPECTED_TRUST_DOMAIN}"
    -P "${TEST_VERIFIER_SCRIPT}" --)
endif()

execute_process(
  COMMAND ${_command} --version
  TIMEOUT ${VERIFIER_TIMEOUT_SECONDS}
  RESULT_VARIABLE _version_result OUTPUT_VARIABLE _version_out ERROR_VARIABLE _version_err
  OUTPUT_STRIP_TRAILING_WHITESPACE ERROR_STRIP_TRAILING_WHITESPACE)
_verifier_output_within_limit("${_version_out}" "${_version_err}" "version probe")
if(NOT _version_result MATCHES "^-?[0-9]+$")
  set(_backend error)
  set(_capability error)
  set(_version_policy error)
  set(_reason "verifier version probe timed out")
  _verifier_finish(TRUE)
endif()
if(NOT _version_result EQUAL 0
   OR NOT _version_out MATCHES "^gh version ([0-9]+\.[0-9]+\.[0-9]+)([ \r\n]|$)")
  set(_backend error)
  set(_capability error)
  set(_version_policy error)
  set(_reason "malformed verifier version output")
  _verifier_finish(TRUE)
endif()
set(_version "${CMAKE_MATCH_1}")
set(_backend_id github-cli-attestation)

execute_process(
  COMMAND ${_command} attestation --help
  TIMEOUT ${VERIFIER_TIMEOUT_SECONDS}
  RESULT_VARIABLE _attestation_result
  OUTPUT_VARIABLE _attestation_out ERROR_VARIABLE _attestation_err)
_verifier_output_within_limit("${_attestation_out}" "${_attestation_err}" "attestation probe")
execute_process(
  COMMAND ${_command} attestation verify --help
  TIMEOUT ${VERIFIER_TIMEOUT_SECONDS}
  RESULT_VARIABLE _verify_help_result
  OUTPUT_VARIABLE _verify_help_out ERROR_VARIABLE _verify_help_err)
_verifier_output_within_limit("${_verify_help_out}" "${_verify_help_err}" "verify capability probe")
if(NOT _attestation_result MATCHES "^-?[0-9]+$"
   OR NOT _verify_help_result MATCHES "^-?[0-9]+$")
  set(_backend error)
  set(_capability error)
  set(_version_policy error)
  set(_reason "verifier capability probe timed out")
  _verifier_finish(TRUE)
endif()
if(_version VERSION_LESS "2.49.0" OR NOT _version VERSION_LESS "3.0.0")
  set(_backend unsupported)
  set(_capability unsupported)
  set(_version_policy unsupported)
  set(_reason "unsupported GitHub CLI version")
  _verifier_finish(REQUIRE_VERIFIED)
endif()
set(_version_policy supported)
if(NOT _attestation_result EQUAL 0 OR NOT _verify_help_result EQUAL 0
   OR NOT _attestation_out MATCHES "attestation"
   OR NOT _verify_help_out MATCHES "(--format|format)")
  set(_backend unsupported)
  set(_capability unsupported)
  set(_reason "GitHub CLI attestation verification capability unavailable")
  _verifier_finish(REQUIRE_VERIFIED)
endif()
set(_backend available)
set(_capability available)

if(PROBE_ONLY)
  set(_reason "probe completed; no attestation supplied")
  _verifier_finish(FALSE)
endif()

foreach(_required IN ITEMS ARTIFACT_PATH EXPECTED_SOURCE_REPOSITORY
    EXPECTED_SOURCE_REVISION EXPECTED_SUBJECT_DIGEST EXPECTED_WORKFLOW_IDENTITY
    EXPECTED_TRUST_DOMAIN ATTESTATION_REFERENCE)
  if(NOT DEFINED ${_required} OR "${${_required}}" STREQUAL "")
    set(_backend error)
    set(_verification rejected)
    set(_reason "${_required} is required for cryptographic verification")
    _verifier_finish(TRUE)
  endif()
endforeach()
set(_subject_digest "${EXPECTED_SUBJECT_DIGEST}")
set(_source_repository "${EXPECTED_SOURCE_REPOSITORY}")
set(_source_revision "${EXPECTED_SOURCE_REVISION}")
set(_attestation_reference "${ATTESTATION_REFERENCE}")
set(_trust_domain "${EXPECTED_TRUST_DOMAIN}")

if(NOT IS_ABSOLUTE "${ARTIFACT_PATH}" OR NOT EXISTS "${ARTIFACT_PATH}"
   OR IS_DIRECTORY "${ARTIFACT_PATH}" OR IS_SYMLINK "${ARTIFACT_PATH}")
  set(_verification rejected)
  set(_reason "artifact path is missing, unsafe, or not a regular absolute path")
  _verifier_finish(TRUE)
endif()
if(NOT EXPECTED_SOURCE_REPOSITORY MATCHES
    "^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$")
  set(_verification rejected)
  set(_reason "source repository is unsafe")
  _verifier_finish(TRUE)
endif()
if(NOT EXPECTED_SOURCE_REVISION MATCHES "^[0-9a-f]+$")
  set(_verification rejected)
  set(_reason "source revision is not lowercase hexadecimal")
  _verifier_finish(TRUE)
endif()
string(LENGTH "${EXPECTED_SOURCE_REVISION}" _revision_length)
if(NOT _revision_length EQUAL 40)
  set(_verification rejected)
  set(_reason "source revision is not a full Git SHA")
  _verifier_finish(TRUE)
endif()
if(NOT EXPECTED_SUBJECT_DIGEST MATCHES "^sha256:[0-9a-f]+$")
  set(_verification rejected)
  set(_reason "subject digest must use SHA-256")
  _verifier_finish(TRUE)
endif()
string(LENGTH "${EXPECTED_SUBJECT_DIGEST}" _digest_length)
if(NOT _digest_length EQUAL 71)
  set(_verification rejected)
  set(_reason "subject digest must contain 64 lowercase hexadecimal digits")
  _verifier_finish(TRUE)
endif()
if(NOT EXPECTED_WORKFLOW_IDENTITY MATCHES
    "^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+/\.github/workflows/[A-Za-z0-9_.-]+\.ya?ml$")
  set(_verification rejected)
  set(_reason "workflow identity is unsafe")
  _verifier_finish(TRUE)
endif()
if(NOT EXPECTED_TRUST_DOMAIN STREQUAL "https://token.actions.githubusercontent.com")
  set(_verification rejected)
  set(_reason "trust domain is unsupported")
  _verifier_finish(TRUE)
endif()
if(NOT ATTESTATION_REFERENCE MATCHES
    "^https://github\.com/${EXPECTED_SOURCE_REPOSITORY}/attestations/[1-9][0-9]*$")
  set(_verification rejected)
  set(_reason "attestation reference does not match the source repository")
  _verifier_finish(TRUE)
endif()
if(DEFINED ATTESTATION_BUNDLE AND NOT ATTESTATION_BUNDLE STREQUAL "")
  if(NOT IS_ABSOLUTE "${ATTESTATION_BUNDLE}" OR NOT EXISTS "${ATTESTATION_BUNDLE}"
     OR IS_DIRECTORY "${ATTESTATION_BUNDLE}" OR IS_SYMLINK "${ATTESTATION_BUNDLE}")
    set(_verification rejected)
    set(_reason "attestation bundle path is missing or unsafe")
    _verifier_finish(TRUE)
  endif()
endif()

file(SHA256 "${ARTIFACT_PATH}" _artifact_sha)
if(NOT "sha256:${_artifact_sha}" STREQUAL EXPECTED_SUBJECT_DIGEST)
  set(_verification rejected)
  set(_reason "artifact subject digest mismatch")
  _verifier_finish(TRUE)
endif()
if(NOT DEFINED EXPECTED_SUBJECT_NAME OR EXPECTED_SUBJECT_NAME STREQUAL "")
  get_filename_component(EXPECTED_SUBJECT_NAME "${ARTIFACT_PATH}" NAME)
endif()
if(NOT EXPECTED_SUBJECT_NAME MATCHES
    "^[A-Za-z0-9][A-Za-z0-9._+-]*(/[A-Za-z0-9][A-Za-z0-9._+-]*)*$")
  set(_verification rejected)
  set(_reason "artifact subject name is unsafe")
  _verifier_finish(TRUE)
endif()

set(_verify_command ${_command} attestation verify "${ARTIFACT_PATH}"
  --repo "${EXPECTED_SOURCE_REPOSITORY}"
  --signer-workflow "${EXPECTED_WORKFLOW_IDENTITY}"
  --source-digest "${EXPECTED_SOURCE_REVISION}"
  --cert-oidc-issuer "${EXPECTED_TRUST_DOMAIN}"
  --predicate-type "https://slsa.dev/provenance/v1"
  --deny-self-hosted-runners --limit 2 --format json)
if(DEFINED ATTESTATION_BUNDLE AND NOT ATTESTATION_BUNDLE STREQUAL "")
  list(APPEND _verify_command --bundle "${ATTESTATION_BUNDLE}")
endif()
execute_process(
  COMMAND ${_verify_command}
  TIMEOUT ${VERIFIER_TIMEOUT_SECONDS}
  RESULT_VARIABLE _verify_result OUTPUT_VARIABLE _verify_out ERROR_VARIABLE _verify_err
  OUTPUT_STRIP_TRAILING_WHITESPACE ERROR_STRIP_TRAILING_WHITESPACE)
_verifier_output_within_limit("${_verify_out}" "${_verify_err}" "verification output")
if(NOT _verify_result MATCHES "^-?[0-9]+$")
  set(_backend error)
  set(_verification rejected)
  set(_reason "verifier process timed out")
  _verifier_finish(TRUE)
endif()
if(NOT _verify_result EQUAL 0)
  if(_verify_err MATCHES "[Nn]o attestations found|attestation missing")
    set(_verification unavailable)
    set(_reason "attestation unavailable")
  else()
    set(_verification rejected)
    set(_reason "verifier rejected the attestation")
  endif()
  _verifier_finish(REQUIRE_VERIFIED)
endif()

string(JSON _result_type ERROR_VARIABLE _json_error TYPE "${_verify_out}")
if(_json_error OR NOT _result_type STREQUAL "ARRAY")
  set(_backend error)
  set(_verification rejected)
  set(_reason "malformed machine-readable verifier output")
  _verifier_finish(TRUE)
endif()
string(JSON _result_count LENGTH "${_verify_out}")
if(NOT _result_count EQUAL 1)
  set(_verification rejected)
  set(_reason "multiple or missing attestation results are ambiguous")
  _verifier_finish(TRUE)
endif()
foreach(_unique IN ITEMS verificationResult predicateType sourceRepositoryURI
    sourceRepositoryDigest buildSignerURI runnerEnvironment verifiedTimestamps)
  string(REGEX MATCHALL "\"${_unique}\"[ \t\r\n]*:" _matches "${_verify_out}")
  list(LENGTH _matches _match_count)
  if(NOT _match_count EQUAL 1)
    set(_backend error)
    set(_verification rejected)
    set(_reason "duplicate or missing JSON field: ${_unique}")
    _verifier_finish(TRUE)
  endif()
endforeach()

string(JSON _predicate ERROR_VARIABLE _field_error GET "${_verify_out}"
  0 verificationResult statement predicateType)
if(_field_error OR NOT _predicate STREQUAL "https://slsa.dev/provenance/v1")
  set(_verification rejected)
  set(_reason "unsupported attestation predicate type")
  _verifier_finish(TRUE)
endif()
string(JSON _subject_count ERROR_VARIABLE _field_error LENGTH "${_verify_out}"
  0 verificationResult statement subject)
if(_field_error OR _subject_count LESS 1)
  set(_verification rejected)
  set(_reason "attestation subject is missing")
  _verifier_finish(TRUE)
endif()
set(_subject_matches 0)
math(EXPR _subject_last "${_subject_count} - 1")
foreach(_index RANGE 0 ${_subject_last})
  string(JSON _name ERROR_VARIABLE _subject_error GET "${_verify_out}"
    0 verificationResult statement subject ${_index} name)
  string(JSON _digest ERROR_VARIABLE _digest_error GET "${_verify_out}"
    0 verificationResult statement subject ${_index} digest sha256)
  if(NOT _subject_error AND NOT _digest_error
     AND _name STREQUAL EXPECTED_SUBJECT_NAME
     AND "sha256:${_digest}" STREQUAL EXPECTED_SUBJECT_DIGEST)
    math(EXPR _subject_matches "${_subject_matches} + 1")
  endif()
endforeach()
if(NOT _subject_matches EQUAL 1)
  set(_verification rejected)
  set(_reason "attestation subject name or digest mismatch")
  _verifier_finish(TRUE)
endif()

foreach(_field IN ITEMS sourceRepositoryURI sourceRepositoryDigest buildSignerURI
    runnerEnvironment issuer)
  string(JSON _certificate_${_field} ERROR_VARIABLE _field_error GET "${_verify_out}"
    0 verificationResult signature certificate ${_field})
  if(_field_error)
    set(_verification rejected)
    set(_reason "unsigned or malformed verifier result")
    _verifier_finish(TRUE)
  endif()
endforeach()
if(NOT _certificate_sourceRepositoryURI STREQUAL
    "https://github.com/${EXPECTED_SOURCE_REPOSITORY}")
  set(_verification rejected)
  set(_reason "verified repository or owner mismatch")
  _verifier_finish(TRUE)
endif()
if(NOT _certificate_sourceRepositoryDigest STREQUAL EXPECTED_SOURCE_REVISION)
  set(_verification rejected)
  set(_reason "verified source revision mismatch")
  _verifier_finish(TRUE)
endif()
string(FIND "${_certificate_buildSignerURI}"
  "https://github.com/${EXPECTED_WORKFLOW_IDENTITY}@" _workflow_position)
if(NOT _workflow_position EQUAL 0)
  set(_verification rejected)
  set(_reason "verified workflow identity mismatch")
  _verifier_finish(TRUE)
endif()
if(NOT _certificate_runnerEnvironment STREQUAL "github-hosted")
  set(_verification rejected)
  set(_reason "self-hosted attestation is forbidden")
  _verifier_finish(TRUE)
endif()
if(NOT _certificate_issuer STREQUAL EXPECTED_TRUST_DOMAIN)
  set(_verification rejected)
  set(_reason "verified trust domain mismatch")
  _verifier_finish(TRUE)
endif()
string(JSON _timestamp_count ERROR_VARIABLE _timestamp_error LENGTH "${_verify_out}"
  0 verificationResult verifiedTimestamps)
if(_timestamp_error OR _timestamp_count LESS 1)
  set(_verification rejected)
  set(_reason "verified timestamp is missing")
  _verifier_finish(TRUE)
endif()

set(_verification verified)
set(_reason "verification succeeded")
_verifier_finish(FALSE)
