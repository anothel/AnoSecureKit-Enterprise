# SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary
cmake_minimum_required(VERSION 3.20)

foreach(_required IN ITEMS SOURCE_DIR REGISTRY_FILE GIT_EXECUTABLE)
  if(NOT DEFINED ${_required} OR "${${_required}}" STREQUAL "")
    message(FATAL_ERROR "${_required} is required for pre-GA blocker registry verification")
  endif()
endforeach()
if(NOT EXISTS "${REGISTRY_FILE}" OR IS_DIRECTORY "${REGISTRY_FILE}")
  message(FATAL_ERROR "Pre-GA blocker registry is missing")
endif()

set(_required_docs
  PRE_GA_BLOCKER_REGISTRY.md
  DEVELOPMENT_FREEZE_AND_CHANGE_POLICY.md
  OPENSSL_PROFILE_GA_PATH.md
  ANOCRYPTO_C_PROFILE_ENABLEMENT_PATH.md)
set(_docs "")
foreach(_doc IN LISTS _required_docs)
  set(_path "${SOURCE_DIR}/docs/${_doc}")
  if(NOT EXISTS "${_path}" OR IS_DIRECTORY "${_path}")
    message(FATAL_ERROR "Required pre-GA document is missing: ${_doc}")
  endif()
  file(READ "${_path}" _content)
  string(APPEND _docs "\n${_content}")
endforeach()
file(READ "${SOURCE_DIR}/README.md" _readme)
string(APPEND _docs "\n${_readme}")
foreach(_marker IN ITEMS
    "support: unsupported pre-release/internal qualification"
    "OpenSSL local qualification: PASS"
    "OpenSSL hosted qualification: not passed / BLOCKED_EXTERNAL"
    "AnoCrypto-C profile: partial" "actual operational systems: inactive"
    "assigned operational roles: none" "activation_ready: false"
    "cryptographic evidence: unavailable" "trusted evidence: unavailable"
    "release authorization: denied-or-unavailable" "customer_release_ready: false"
    "NOW:" "none" "EXTERNAL:" "UPSTREAM:" "DECISION:" "LATER:"
    "does not require both profiles to become GA together"
    "new abstract policy" "speculative vendor adapter")
  string(FIND "${_docs}" "${_marker}" _position)
  if(_position EQUAL -1)
    message(FATAL_ERROR "Pre-GA documents omit required marker: ${_marker}")
  endif()
endforeach()

file(SIZE "${REGISTRY_FILE}" _size)
if(_size GREATER 524288)
  message(FATAL_ERROR "Pre-GA blocker registry exceeds 512 KiB")
endif()
file(READ "${REGISTRY_FILE}" _raw)
string(REPLACE "\r\n" "\n" _record "${_raw}")
if(_record MATCHES "\r")
  message(FATAL_ERROR "Pre-GA blocker registry contains a carriage return")
endif()
string(JSON _root_type ERROR_VARIABLE _json_error TYPE "${_record}")
if(_json_error OR NOT _root_type STREQUAL "OBJECT")
  message(FATAL_ERROR "Malformed pre-GA blocker registry JSON")
endif()

set(_root_fields
  schema_version product product_version support_state evaluated_source_revision
  customer_release_ready openssl_requires_anocrypto_c_ga blockers next_work later_items)
set(_blocker_fields
  blocker_id title category scope profile status severity owner_repository owner_role
  external_dependency blocking_gate required_evidence completion_condition
  deferred_reason last_verified_revision)
set(_later_fields later_id title reason)
set(_categories external organizational technical upstream policy evidence)
set(_statuses open blocked-external waiting-upstream waiting-decision in-progress
  verified-closed not-applicable)
set(_roles
  security-intake-owner incident-commander evidence-custodian evidence-reviewer
  release-authorizer product-owner community-liaison anocrypto-c-liaison
  customer-communications-owner)
set(_expected_ids
  PGA-OSSL-LOCAL-WINDOWS PGA-OSSL-LOCAL-WSL PGA-OSSL-HOSTED-UBUNTU
  PGA-OSSL-HOSTED-WINDOWS PGA-OSSL-HOSTED-MACOS PGA-OSSL-CODEQL
  PGA-OSSL-HOSTED-ARTIFACT-GENERATION PGA-OSSL-HOSTED-ARTIFACT-DOWNLOAD
  PGA-OSSL-ATTESTATION-GENERATION PGA-OSSL-ATTESTATION-CRYPTO-VERIFY
  PGA-OSSL-TRUSTED-EVIDENCE-CURRENT-REVISION
  PGA-OSSL-RELEASE-AUTHORIZATION-ARTIFACT-SET
  PGA-OSSL-PRIVATE-REPORTING-DECISION PGA-OSSL-OPERATIONAL-ROLE-ASSIGNMENT
  PGA-OSSL-SUPPORT-STATE-APPROVAL PGA-OSSL-SECURITY-SYSTEM-DECISION-OR-WAIVER
  PGA-ANO-HKDF-SHA256 PGA-ANO-SCRYPT PGA-ANO-AES256-GCM PGA-ANO-STREAMING-AEAD
  PGA-ANO-CAPABILITY-STATUS-FAILURE-CONTRACT PGA-ANO-FORCED-FAILURE-SEAMS
  PGA-ANO-APPROVED-PACKAGE-DIGEST PGA-ANO-STATIC-PACKAGE PGA-ANO-SHARED-PACKAGE
  PGA-ANO-ENTERPRISE-ADAPTER-PARITY PGA-ANO-INSTALL-EXPORT-CPACK
  PGA-ANO-HOSTED-QUALIFICATION PGA-ANO-CUSTOMER-AUTHORIZATION)
set(_expected_later
  LATER-CUSTOMER-VERIFICATION-UX LATER-OPTIONAL-PLATFORMS
  LATER-FUTURE-PROFILES LATER-UNSELECTED-VENDOR-ADAPTER
  LATER-OPERATIONAL-CONVENIENCE LATER-DOCUMENT-LINKS LATER-SCHEMA-EXTENSIONS)

function(_enum label value)
  list(FIND ARGN "${value}" _found)
  if(_found EQUAL -1)
    message(FATAL_ERROR "Unsupported pre-GA blocker ${label}: ${value}")
  endif()
endfunction()

function(_members json label expected)
  string(JSON _count ERROR_VARIABLE _error LENGTH "${json}")
  if(_error)
    message(FATAL_ERROR "Malformed pre-GA ${label} object")
  endif()
  list(LENGTH expected _expected_count)
  if(NOT _count EQUAL _expected_count)
    message(FATAL_ERROR "Pre-GA ${label} field count mismatch")
  endif()
  if(_count GREATER 0)
    math(EXPR _last "${_count} - 1")
    foreach(_index RANGE 0 ${_last})
      string(JSON _member MEMBER "${json}" ${_index})
      list(FIND expected "${_member}" _known)
      if(_known EQUAL -1)
        message(FATAL_ERROR "Unknown pre-GA ${label} field: ${_member}")
      endif()
    endforeach()
  endif()
endfunction()

function(_get output json expected_type)
  set(_path ${ARGN})
  string(JSON _type ERROR_VARIABLE _error TYPE "${json}" ${_path})
  if(_error)
    list(JOIN _path "." _label)
    message(FATAL_ERROR "Missing pre-GA registry field: ${_label}")
  endif()
  if(NOT _type STREQUAL "${expected_type}")
    list(JOIN _path "." _label)
    message(FATAL_ERROR "Pre-GA registry field ${_label} must be ${expected_type}")
  endif()
  string(JSON _value GET "${json}" ${_path})
  set(${output} "${_value}" PARENT_SCOPE)
endfunction()

function(_exact_array output json label expected)
  set(_path ${ARGN})
  string(JSON _type ERROR_VARIABLE _error TYPE "${json}" ${_path})
  if(_error OR NOT _type STREQUAL "ARRAY")
    message(FATAL_ERROR "Pre-GA registry ${label} must be an array")
  endif()
  string(JSON _count LENGTH "${json}" ${_path})
  set(_actual "")
  if(_count GREATER 0)
    math(EXPR _last "${_count} - 1")
    foreach(_index RANGE 0 ${_last})
      _get(_value "${json}" STRING ${_path} ${_index})
      list(APPEND _actual "${_value}")
    endforeach()
  endif()
  if(NOT "${_actual}" STREQUAL "${expected}")
    message(FATAL_ERROR "Pre-GA registry ${label} has missing, unknown, duplicate, or reordered entries")
  endif()
  set(${output} "${_actual}" PARENT_SCOPE)
endfunction()

_members("${_record}" root "${_root_fields}")
foreach(_field IN ITEMS schema_version product product_version support_state
    evaluated_source_revision)
  _get(_${_field} "${_record}" STRING ${_field})
endforeach()
foreach(_field IN ITEMS customer_release_ready openssl_requires_anocrypto_c_ga)
  _get(_${_field} "${_record}" BOOLEAN ${_field})
endforeach()
if(NOT _schema_version STREQUAL "1" OR NOT _product STREQUAL "AnoSecureKit Enterprise"
   OR NOT _product_version STREQUAL "0.1.0")
  message(FATAL_ERROR "Pre-GA registry product/schema identity mismatch")
endif()
if(NOT _support_state STREQUAL "unsupported pre-release/internal qualification")
  message(FATAL_ERROR "Pre-GA registry falsely claims GA, production, or active support")
endif()
if(_customer_release_ready)
  message(FATAL_ERROR "Pre-GA registry cannot set customer_release_ready true")
endif()
if(_openssl_requires_anocrypto_c_ga)
  message(FATAL_ERROR "OpenSSL GA cannot require AnoCrypto-C future-profile GA without a product decision")
endif()
if(NOT _evaluated_source_revision MATCHES "^[0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f]$")
  message(FATAL_ERROR "Pre-GA registry evaluated source revision is malformed")
endif()
execute_process(
  COMMAND "${GIT_EXECUTABLE}" cat-file -e "${_evaluated_source_revision}^{commit}"
  WORKING_DIRECTORY "${SOURCE_DIR}" RESULT_VARIABLE _revision_result
  OUTPUT_QUIET ERROR_QUIET)
execute_process(
  COMMAND "${GIT_EXECUTABLE}" merge-base --is-ancestor "${_evaluated_source_revision}" HEAD
  WORKING_DIRECTORY "${SOURCE_DIR}" RESULT_VARIABLE _ancestor_result
  OUTPUT_QUIET ERROR_QUIET)
if(NOT _revision_result EQUAL 0 OR NOT _ancestor_result EQUAL 0)
  message(FATAL_ERROR "Pre-GA registry current revision binding does not resolve to an audited ancestor")
endif()

string(JSON _blocker_type TYPE "${_record}" blockers)
string(JSON _blocker_count LENGTH "${_record}" blockers)
if(NOT _blocker_type STREQUAL "ARRAY" OR NOT _blocker_count EQUAL 29)
  message(FATAL_ERROR "Pre-GA registry requires exactly 29 named blocker records")
endif()
set(_seen_ids "")
set(_expected_now "")
set(_expected_external "")
set(_expected_upstream "")
set(_expected_decision "")
math(EXPR _blocker_last "${_blocker_count} - 1")
foreach(_index RANGE 0 ${_blocker_last})
  string(JSON _blocker GET "${_record}" blockers ${_index})
  _members("${_blocker}" blocker "${_blocker_fields}")
  foreach(_field IN ITEMS blocker_id title category scope profile status severity
      owner_repository owner_role external_dependency blocking_gate
      completion_condition deferred_reason last_verified_revision)
    _get(_${_field} "${_blocker}" STRING ${_field})
    if(_${_field} STREQUAL "")
      message(FATAL_ERROR "Pre-GA blocker ${_field} is empty")
    endif()
  endforeach()
  foreach(_field IN LISTS _blocker_fields)
    string(REGEX MATCHALL "\"${_field}\"[ \t\n]*:" _matches "${_blocker}")
    list(LENGTH _matches _match_count)
    if(NOT _match_count EQUAL 1)
      message(FATAL_ERROR "Duplicate or missing pre-GA blocker field: ${_field}")
    endif()
  endforeach()
  if(NOT _blocker_id MATCHES "^PGA-(OSSL|ANO)-[A-Z0-9-]+$")
    message(FATAL_ERROR "Pre-GA blocker ID is missing or malformed")
  endif()
  list(FIND _seen_ids "${_blocker_id}" _duplicate)
  if(NOT _duplicate EQUAL -1)
    message(FATAL_ERROR "Duplicate pre-GA blocker ID: ${_blocker_id}")
  endif()
  list(APPEND _seen_ids "${_blocker_id}")
  _enum(category "${_category}" ${_categories})
  _enum(status "${_status}" ${_statuses})
  _enum(severity "${_severity}" critical high medium low)
  _enum(owner_repository "${_owner_repository}"
    AnoSecureKit-Enterprise AnoCrypto-C anosecurekit-community)
  _enum(owner_role "${_owner_role}" ${_roles})
  if(_title MATCHES "(KCMVP|FIPS|[Gg]eneral [Aa]vailability|[Aa]ctive [Ss]upport)")
    message(FATAL_ERROR "Pre-GA blocker title contains a prohibited validation or GA claim")
  endif()
  if(_title MATCHES "([Oo]ptional|[Cc]onvenience|[Uu]nselected vendor|[Ss]peculative)")
    message(FATAL_ERROR "Optional enhancement cannot be classified as a hard pre-GA blocker")
  endif()
  if(NOT _last_verified_revision STREQUAL _evaluated_source_revision)
    message(FATAL_ERROR "Pre-GA blocker current revision mismatch: ${_blocker_id}")
  endif()

  if(_blocker_id MATCHES "^PGA-OSSL-")
    if(NOT _scope STREQUAL "openssl-ga" OR NOT _profile STREQUAL "openssl"
       OR NOT _owner_repository STREQUAL "AnoSecureKit-Enterprise")
      message(FATAL_ERROR "OpenSSL blocker scope/profile/repository routing is incorrect: ${_blocker_id}")
    endif()
  else()
    if(NOT _scope STREQUAL "anocrypto-c-enablement" OR NOT _profile STREQUAL "anocrypto-c")
      message(FATAL_ERROR "AnoCrypto-C blocker scope/profile separation is incorrect: ${_blocker_id}")
    endif()
    if(_blocker_id MATCHES "^PGA-ANO-(HKDF|SCRYPT|AES256|STREAMING|CAPABILITY|FORCED|APPROVED|STATIC|SHARED)-")
      if(NOT _category STREQUAL "upstream" OR NOT _owner_repository STREQUAL "AnoCrypto-C")
        message(FATAL_ERROR "AnoCrypto-C primitive/package blocker repository routing is incorrect: ${_blocker_id}")
      endif()
    elseif(_blocker_id MATCHES "^PGA-ANO-(ENTERPRISE|INSTALL)-")
      if(NOT _category STREQUAL "technical" OR NOT _owner_repository STREQUAL "AnoSecureKit-Enterprise")
        message(FATAL_ERROR "Enterprise AnoCrypto-C adapter blocker routing is incorrect: ${_blocker_id}")
      endif()
    endif()
  endif()

  string(JSON _evidence_type TYPE "${_blocker}" required_evidence)
  string(JSON _evidence_count LENGTH "${_blocker}" required_evidence)
  if(NOT _evidence_type STREQUAL "ARRAY" OR _evidence_count LESS 1)
    message(FATAL_ERROR "Pre-GA blocker required evidence is missing: ${_blocker_id}")
  endif()
  math(EXPR _evidence_last "${_evidence_count} - 1")
  foreach(_evidence_index RANGE 0 ${_evidence_last})
    _get(_evidence "${_blocker}" STRING required_evidence ${_evidence_index})
    if(_evidence STREQUAL "")
      message(FATAL_ERROR "Pre-GA blocker required evidence is empty: ${_blocker_id}")
    endif()
    if(_status STREQUAL "verified-closed")
      if(_evidence MATCHES "^required:" OR _evidence MATCHES "(unavailable|pending|future)")
        message(FATAL_ERROR "Pre-GA blocker has false verified closure without actual evidence: ${_blocker_id}")
      endif()
      if(_evidence MATCHES "^repo:([^#]+)")
        if(NOT EXISTS "${SOURCE_DIR}/${CMAKE_MATCH_1}")
          message(FATAL_ERROR "Closed blocker repository evidence is missing: ${_blocker_id}")
        endif()
      endif()
    endif()
  endforeach()
  if(_status STREQUAL "verified-closed")
    if(NOT _blocker_id MATCHES "^PGA-OSSL-LOCAL-(WINDOWS|WSL)$"
       OR NOT _deferred_reason STREQUAL "not-deferred")
      message(FATAL_ERROR "Only evidenced local OpenSSL blockers may be verified-closed")
    endif()
  else()
    if(_deferred_reason STREQUAL "not-deferred")
      message(FATAL_ERROR "Open pre-GA blocker is missing a deferred reason: ${_blocker_id}")
    endif()
    if(_status STREQUAL "blocked-external")
      list(APPEND _expected_external "${_blocker_id}")
    elseif(_status STREQUAL "waiting-upstream")
      list(APPEND _expected_upstream "${_blocker_id}")
    elseif(_status STREQUAL "waiting-decision")
      list(APPEND _expected_decision "${_blocker_id}")
    elseif(_status MATCHES "^(open|in-progress)$")
      list(APPEND _expected_now "${_blocker_id}")
    endif()
  endif()
endforeach()
if(NOT "${_seen_ids}" STREQUAL "${_expected_ids}")
  message(FATAL_ERROR "Pre-GA registry blocker set has a missing, unknown, or reordered ID")
endif()

string(JSON _next_work GET "${_record}" next_work)
_members("${_next_work}" next_work "NOW;EXTERNAL;UPSTREAM;DECISION;LATER")
_exact_array(_now "${_record}" NOW "${_expected_now}" next_work NOW)
_exact_array(_external "${_record}" EXTERNAL "${_expected_external}" next_work EXTERNAL)
_exact_array(_upstream "${_record}" UPSTREAM "${_expected_upstream}" next_work UPSTREAM)
_exact_array(_decision "${_record}" DECISION "${_expected_decision}" next_work DECISION)
_exact_array(_later_queue "${_record}" LATER "${_expected_later}" next_work LATER)
if(_now)
  message(FATAL_ERROR "Pre-GA NOW queue must be none at this baseline")
endif()

string(JSON _later_type TYPE "${_record}" later_items)
string(JSON _later_count LENGTH "${_record}" later_items)
list(LENGTH _expected_later _expected_later_count)
if(NOT _later_type STREQUAL "ARRAY" OR NOT _later_count EQUAL _expected_later_count)
  message(FATAL_ERROR "Pre-GA LATER item count mismatch")
endif()
set(_seen_later "")
math(EXPR _later_last "${_later_count} - 1")
foreach(_index RANGE 0 ${_later_last})
  string(JSON _later GET "${_record}" later_items ${_index})
  _members("${_later}" later_item "${_later_fields}")
  foreach(_field IN ITEMS later_id title reason)
    _get(_${_field} "${_later}" STRING ${_field})
    if(_${_field} STREQUAL "")
      message(FATAL_ERROR "Pre-GA LATER ${_field} is empty")
    endif()
  endforeach()
  list(APPEND _seen_later "${_later_id}")
endforeach()
if(NOT "${_seen_later}" STREQUAL "${_expected_later}")
  message(FATAL_ERROR "Pre-GA LATER set has a missing, anonymous, unknown, or reordered item")
endif()

file(READ "${SOURCE_DIR}/release/customer-release-authorization.json" _authorization)
string(JSON _authorization_decision ERROR_VARIABLE _authorization_error
  GET "${_authorization}" decision)
if(_authorization_error OR NOT _authorization_decision STREQUAL "deny")
  message(FATAL_ERROR "Pre-GA registry requires default release authorization deny")
endif()
file(READ "${SOURCE_DIR}/cmake/anosecurekitEnterpriseConfig.cmake.in" _package_config)
if(NOT _package_config MATCHES "ANOSECUREKIT_ENTERPRISE_CUSTOMER_RELEASE_READY FALSE")
  message(FATAL_ERROR "Pre-GA registry requires customer_release_ready false")
endif()

message(STATUS
  "Pre-GA blocker registry passed: 29 named blockers, 2 evidenced local closures, NOW none, customer release blocked")
