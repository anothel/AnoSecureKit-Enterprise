# SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary
cmake_minimum_required(VERSION 3.20)

if(NOT DEFINED AUTHORIZATION_RECORD OR AUTHORIZATION_RECORD STREQUAL ""
   OR NOT EXISTS "${AUTHORIZATION_RECORD}" OR IS_DIRECTORY "${AUTHORIZATION_RECORD}")
  message(FATAL_ERROR "Release authorization record is missing")
endif()
if(NOT DEFINED REQUIRE_ALLOW)
  set(REQUIRE_ALLOW ON)
endif()
if(NOT DEFINED ALLOW_TEST_FIXTURE)
  set(ALLOW_TEST_FIXTURE OFF)
endif()

file(SIZE "${AUTHORIZATION_RECORD}" _authorization_size)
if(_authorization_size GREATER 65536)
  message(FATAL_ERROR "Release authorization record exceeds 64 KiB")
endif()
file(READ "${AUTHORIZATION_RECORD}" _authorization)
string(JSON _root_type ERROR_VARIABLE _json_error TYPE "${_authorization}")
if(_json_error OR NOT _root_type STREQUAL "OBJECT")
  message(FATAL_ERROR "Malformed release authorization JSON: ${_json_error}")
endif()

set(_fields
  schema_version decision product enterprise_version community_version
  community_tree backend_profile provider_family source_revision
  qualification_status hosted_evidence_status hosted_evidence_reference
  codeql_required codeql_status artifact_manifest_digest artifact_set_digest
  trusted_evidence_digest
  signing_evidence_status signing_evidence_reference
  provenance_evidence_status provenance_evidence_reference
  authorization_status authorized_by authorized_at expires_at reason test_only)

foreach(_field IN LISTS _fields)
  string(REGEX MATCHALL "\"${_field}\"[ \\t\\r\\n]*:" _field_occurrences
    "${_authorization}")
  list(LENGTH _field_occurrences _field_occurrence_count)
  if(_field_occurrence_count GREATER 1)
    message(FATAL_ERROR "Duplicate release authorization field: ${_field}")
  endif()
endforeach()

string(JSON _field_count LENGTH "${_authorization}")
list(LENGTH _fields _expected_field_count)
if(NOT _field_count EQUAL _expected_field_count)
  message(FATAL_ERROR
    "Release authorization field count mismatch: expected ${_expected_field_count}, got ${_field_count}")
endif()
math(EXPR _last_field "${_field_count} - 1")
foreach(_index RANGE 0 ${_last_field})
  string(JSON _field MEMBER "${_authorization}" ${_index})
  list(FIND _fields "${_field}" _known_field)
  if(_known_field EQUAL -1)
    message(FATAL_ERROR "Unknown release authorization field: ${_field}")
  endif()
endforeach()

function(_authorization_get field expected_type output)
  string(JSON _type ERROR_VARIABLE _type_error TYPE "${_authorization}" "${field}")
  if(_type_error)
    message(FATAL_ERROR "Missing release authorization field: ${field}")
  endif()
  if(NOT _type STREQUAL "${expected_type}")
    message(FATAL_ERROR
      "Release authorization field ${field} must be ${expected_type}, got ${_type}")
  endif()
  string(JSON _value GET "${_authorization}" "${field}")
  set(${output} "${_value}" PARENT_SCOPE)
endfunction()

foreach(_field IN ITEMS
    schema_version decision product enterprise_version community_version
    community_tree backend_profile provider_family source_revision
    qualification_status hosted_evidence_status hosted_evidence_reference
    codeql_status artifact_manifest_digest artifact_set_digest
    trusted_evidence_digest
    signing_evidence_status signing_evidence_reference
    provenance_evidence_status provenance_evidence_reference
    authorization_status authorized_by authorized_at reason)
  _authorization_get("${_field}" STRING "_${_field}")
endforeach()
_authorization_get(codeql_required BOOLEAN _codeql_required)
_authorization_get(test_only BOOLEAN _test_only)
string(JSON _expires_type ERROR_VARIABLE _expires_error TYPE "${_authorization}" expires_at)
if(_expires_error OR (NOT _expires_type STREQUAL "STRING" AND NOT _expires_type STREQUAL "NULL"))
  message(FATAL_ERROR "Release authorization field expires_at must be STRING or NULL")
endif()
if(_expires_type STREQUAL "STRING")
  string(JSON _expires_at GET "${_authorization}" expires_at)
else()
  set(_expires_at "")
endif()

function(_require_enum field value)
  list(FIND ARGN "${value}" _match)
  if(_match EQUAL -1)
    message(FATAL_ERROR "Unsupported ${field}: ${value}")
  endif()
endfunction()

function(_require_git_sha field value)
  string(LENGTH "${value}" _length)
  if(NOT _length EQUAL 40 OR NOT value MATCHES "^[0-9a-f]+$")
    message(FATAL_ERROR "${field} must be a full lowercase Git SHA")
  endif()
endfunction()

function(_require_sha256 field value)
  string(LENGTH "${value}" _length)
  if(NOT _length EQUAL 71 OR NOT value MATCHES "^sha256:[0-9a-f]+$")
    message(FATAL_ERROR "${field} must use sha256:<64 lowercase hex>")
  endif()
endfunction()

function(_reject_sensitive_value field value)
  string(TOLOWER "${value}" _lower)
  if(value MATCHES "(^|[ \\t])([A-Za-z]:[/\\\\]|/home/|/Users/|/mnt/[A-Za-z]/|\\\\\\\\)")
    message(FATAL_ERROR "Release authorization field ${field} contains a local absolute path")
  endif()
  if(_lower MATCHES "(token|secret|password|api[_-]?key)[ \\t]*[:=]")
    message(FATAL_ERROR "Release authorization field ${field} contains secret-like data")
  endif()
endfunction()

foreach(_field IN LISTS _fields)
  if(DEFINED _${_field})
    _reject_sensitive_value("${_field}" "${_${_field}}")
  endif()
endforeach()

if(NOT _schema_version STREQUAL "1")
  message(FATAL_ERROR "Unsupported release authorization schema version: ${_schema_version}")
endif()
_require_enum(decision "${_decision}" deny allow)
_require_enum(qualification_status "${_qualification_status}"
  qualified deferred not-run blocked-external unverified partial)
_require_enum(hosted_evidence_status "${_hosted_evidence_status}"
  passed deferred not-run blocked-external unverified)
_require_enum(codeql_status "${_codeql_status}" passed deferred not-run blocked-external unverified)
_require_enum(signing_evidence_status "${_signing_evidence_status}" verified unavailable unverified)
_require_enum(provenance_evidence_status "${_provenance_evidence_status}" verified unavailable unverified)
_require_enum(authorization_status "${_authorization_status}" active inactive revoked)

if(_authorization_status STREQUAL "revoked")
  message(FATAL_ERROR "Release authorization is revoked")
endif()
if(NOT _product STREQUAL "AnoSecureKit Enterprise")
  message(FATAL_ERROR "Unsupported release authorization product: ${_product}")
endif()
_require_git_sha(community_tree "${_community_tree}")
_require_git_sha(source_revision "${_source_revision}")
_require_sha256(artifact_manifest_digest "${_artifact_manifest_digest}")
_require_sha256(artifact_set_digest "${_artifact_set_digest}")
_require_sha256(trusted_evidence_digest "${_trusted_evidence_digest}")
if(NOT _authorized_by MATCHES "^role:[a-z0-9][a-z0-9.-]+$")
  message(FATAL_ERROR "authorized_by must be a stable role:<identifier>")
endif()
set(_utc_timestamp_pattern
  "^[0-9][0-9][0-9][0-9]-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01])T([01][0-9]|2[0-3]):[0-5][0-9]:[0-5][0-9]Z$")
if(NOT _authorized_at MATCHES "${_utc_timestamp_pattern}")
  message(FATAL_ERROR "authorized_at must use UTC YYYY-MM-DDTHH:MM:SSZ")
endif()
string(LENGTH "${_reason}" _reason_length)
if(_reason_length LESS 1 OR _reason_length GREATER 500)
  message(FATAL_ERROR "reason must contain 1 to 500 characters")
endif()
if(_test_only AND NOT ALLOW_TEST_FIXTURE)
  message(FATAL_ERROR "Test-only release authorization cannot authorize production delivery")
endif()
if(DEFINED EXPECTED_TRUSTED_EVIDENCE_DIGEST
   AND NOT EXPECTED_TRUSTED_EVIDENCE_DIGEST STREQUAL ""
   AND NOT _trusted_evidence_digest STREQUAL EXPECTED_TRUSTED_EVIDENCE_DIGEST)
  message(FATAL_ERROR "Release authorization trusted_evidence_digest mismatch")
endif()

if(_decision STREQUAL "deny")
  message(STATUS "authorization: denied or unavailable")
  message(STATUS "customer_release_ready: false")
  if(REQUIRE_ALLOW)
    message(FATAL_ERROR "Customer release authorization denied")
  endif()
  return()
endif()

foreach(_required IN ITEMS
    EXPECTED_ENTERPRISE_VERSION EXPECTED_COMMUNITY_VERSION EXPECTED_COMMUNITY_TREE
    EXPECTED_BACKEND_PROFILE EXPECTED_PROVIDER_FAMILY EXPECTED_SOURCE_REVISION
    EXPECTED_ARTIFACT_MANIFEST_DIGEST EXPECTED_ARTIFACT_SET_DIGEST
    EXPECTED_TRUSTED_EVIDENCE_DIGEST EXPECTED_CODEQL_REQUIRED)
  if(NOT DEFINED ${_required} OR "${${_required}}" STREQUAL "")
    message(FATAL_ERROR "${_required} is required for an allow decision")
  endif()
endforeach()

foreach(_binding IN ITEMS
    enterprise_version community_version community_tree backend_profile
    provider_family source_revision artifact_manifest_digest artifact_set_digest
    trusted_evidence_digest)
  string(TOUPPER "${_binding}" _binding_upper)
  set(_expected_name "EXPECTED_${_binding_upper}")
  set(_actual "${_${_binding}}")
  set(_expected "${${_expected_name}}")
  if(NOT _actual STREQUAL _expected)
    message(FATAL_ERROR
      "Release authorization ${_binding} mismatch: expected '${_expected}', got '${_actual}'")
  endif()
endforeach()
if(NOT "${_codeql_required}" STREQUAL "${EXPECTED_CODEQL_REQUIRED}")
  message(FATAL_ERROR "Release authorization CodeQL policy mismatch")
endif()
if(NOT _backend_profile STREQUAL "openssl" OR NOT _provider_family STREQUAL "openssl")
  message(FATAL_ERROR "Only a complete OpenSSL provider-family profile may be authorized")
endif()
if(NOT _qualification_status STREQUAL "qualified")
  message(FATAL_ERROR "Qualification status does not permit release: ${_qualification_status}")
endif()
if(NOT _hosted_evidence_status STREQUAL "passed")
  message(FATAL_ERROR "Hosted evidence does not permit release: ${_hosted_evidence_status}")
endif()
if(NOT _hosted_evidence_reference MATCHES "^github-actions-run:[0-9]+$")
  message(FATAL_ERROR "Hosted evidence reference is missing or unsupported")
endif()
if(_codeql_required AND NOT _codeql_status STREQUAL "passed")
  message(FATAL_ERROR "Required CodeQL evidence does not permit release: ${_codeql_status}")
endif()
if(NOT _signing_evidence_status STREQUAL "verified"
   OR NOT _signing_evidence_reference MATCHES "^signing-evidence:sha256:[0-9a-f]+$")
  message(FATAL_ERROR "Signing evidence is missing or unverified")
endif()
string(REGEX REPLACE "^signing-evidence:" "" _signing_digest
  "${_signing_evidence_reference}")
_require_sha256(signing_evidence_reference "${_signing_digest}")
if(NOT _provenance_evidence_status STREQUAL "verified"
   OR NOT _provenance_evidence_reference MATCHES "^provenance-evidence:sha256:[0-9a-f]+$")
  message(FATAL_ERROR "Provenance evidence is missing or unverified")
endif()
string(REGEX REPLACE "^provenance-evidence:" "" _provenance_digest
  "${_provenance_evidence_reference}")
_require_sha256(provenance_evidence_reference "${_provenance_digest}")
if(NOT _authorization_status STREQUAL "active")
  message(FATAL_ERROR "Release authorization is not active")
endif()
if(NOT _expires_type STREQUAL "STRING"
   OR NOT _expires_at MATCHES "${_utc_timestamp_pattern}")
  message(FATAL_ERROR "Allow authorization requires expires_at in UTC YYYY-MM-DDTHH:MM:SSZ")
endif()
string(TIMESTAMP _now "%Y-%m-%dT%H:%M:%SZ" UTC)
if(_now STRLESS _authorized_at OR NOT _authorized_at STRLESS _expires_at
   OR NOT _now STRLESS _expires_at)
  message(FATAL_ERROR "Release authorization is expired or has an invalid validity interval")
endif()
if(NOT _test_only)
  message(FATAL_ERROR
    "Production signing/provenance evidence verification is not implemented; allow remains unavailable")
endif()

message(STATUS "authorization: allowed")
message(STATUS "customer_release_ready: true")
