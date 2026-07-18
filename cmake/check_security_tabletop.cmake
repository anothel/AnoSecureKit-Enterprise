# SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary
cmake_minimum_required(VERSION 3.20)

foreach(_required IN ITEMS FIXTURE_DIR EXPECTED_SOURCE_REVISION)
  if(NOT DEFINED ${_required} OR "${${_required}}" STREQUAL "")
    message(FATAL_ERROR "${_required} is required for the security tabletop check")
  endif()
endforeach()
if(NOT IS_DIRECTORY "${FIXTURE_DIR}")
  message(FATAL_ERROR "Security tabletop fixture directory is missing: ${FIXTURE_DIR}")
endif()

function(_record_members label expected)
  set(_path ${ARGN})
  string(JSON _count ERROR_VARIABLE _error LENGTH "${_record}" ${_path})
  if(_error)
    message(FATAL_ERROR "Missing or malformed tabletop object: ${label}")
  endif()
  list(LENGTH expected _expected_count)
  if(NOT _count EQUAL _expected_count)
    message(FATAL_ERROR
      "Tabletop ${label} field count mismatch: expected ${_expected_count}, got ${_count}")
  endif()
  if(_count GREATER 0)
    math(EXPR _last "${_count} - 1")
    foreach(_index RANGE 0 ${_last})
      string(JSON _member MEMBER "${_record}" ${_path} ${_index})
      list(FIND expected "${_member}" _known)
      if(_known EQUAL -1)
        message(FATAL_ERROR "Unknown tabletop ${label} field: ${_member}")
      endif()
    endforeach()
  endif()
endfunction()

function(_record_get output expected_type)
  set(_path ${ARGN})
  string(JSON _type ERROR_VARIABLE _error TYPE "${_record}" ${_path})
  if(_error)
    list(JOIN _path "." _label)
    message(FATAL_ERROR "Missing tabletop field: ${_label}")
  endif()
  if(NOT _type STREQUAL "${expected_type}")
    list(JOIN _path "." _label)
    message(FATAL_ERROR
      "Tabletop field ${_label} must be ${expected_type}, got ${_type}")
  endif()
  string(JSON _value GET "${_record}" ${_path})
  set(${output} "${_value}" PARENT_SCOPE)
endfunction()

function(_record_enum field value)
  list(FIND ARGN "${value}" _match)
  if(_match EQUAL -1)
    message(FATAL_ERROR "Unsupported tabletop ${field}: ${value}")
  endif()
endfunction()

function(_record_array output field)
  string(JSON _type ERROR_VARIABLE _error TYPE "${_record}" ${field})
  if(_error OR NOT _type STREQUAL "ARRAY")
    message(FATAL_ERROR "Tabletop field ${field} must be a non-empty ARRAY")
  endif()
  string(JSON _count LENGTH "${_record}" ${field})
  if(_count LESS 1)
    message(FATAL_ERROR "Tabletop field ${field} must be a non-empty ARRAY")
  endif()
  math(EXPR _last "${_count} - 1")
  set(_values "")
  foreach(_index RANGE 0 ${_last})
    string(JSON _item_type TYPE "${_record}" ${field} ${_index})
    if(NOT _item_type STREQUAL "STRING")
      message(FATAL_ERROR "Tabletop field ${field} entries must be STRING")
    endif()
    string(JSON _item GET "${_record}" ${field} ${_index})
    list(APPEND _values "${_item}")
  endforeach()
  set(${output} "${_values}" PARENT_SCOPE)
endfunction()

function(_valid_timestamp field value)
  set(_pattern
    "^[0-9][0-9][0-9][0-9]-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01])T([01][0-9]|2[0-3]):[0-5][0-9]:[0-5][0-9]Z$")
  if(NOT value MATCHES "${_pattern}")
    message(FATAL_ERROR "Tabletop ${field} must use UTC YYYY-MM-DDTHH:MM:SSZ")
  endif()
  string(SUBSTRING "${value}" 0 4 _year)
  string(SUBSTRING "${value}" 5 2 _month)
  string(SUBSTRING "${value}" 8 2 _day)
  string(REGEX REPLACE "^0" "" _month "${_month}")
  string(REGEX REPLACE "^0" "" _day "${_day}")
  math(EXPR _month_number "${_month}")
  math(EXPR _day_number "${_day}")
  set(_days 31 28 31 30 31 30 31 31 30 31 30 31)
  math(EXPR _month_index "${_month_number} - 1")
  list(GET _days ${_month_index} _month_days)
  if(_month_number EQUAL 2)
    math(EXPR _mod_4 "${_year} % 4")
    math(EXPR _mod_100 "${_year} % 100")
    math(EXPR _mod_400 "${_year} % 400")
    if(_mod_400 EQUAL 0 OR (_mod_4 EQUAL 0 AND NOT _mod_100 EQUAL 0))
      set(_month_days 29)
    endif()
  endif()
  if(_day_number GREATER _month_days)
    message(FATAL_ERROR "Tabletop ${field} is not a valid calendar timestamp")
  endif()
endfunction()

function(_require_value label actual expected)
  if(NOT actual STREQUAL expected)
    message(FATAL_ERROR
      "Scenario ${_scenario_id} ${label} must be '${expected}', got '${actual}'")
  endif()
endfunction()

function(_require_requalification value)
  list(FIND _required_requalification "${value}" _found)
  if(_found EQUAL -1)
    message(FATAL_ERROR
      "Scenario ${_scenario_id} required_requalification is missing: ${value}")
  endif()
endfunction()

file(GLOB _records LIST_DIRECTORIES false "${FIXTURE_DIR}/*.json")
list(SORT _records)
list(LENGTH _records _record_count)
if(NOT _record_count EQUAL 6)
  message(FATAL_ERROR
    "Security tabletop requires exactly 6 scenario records, found ${_record_count}")
endif()

set(_root_fields
  schema_version record_type scenario_id severity affected_product
  affected_revision affected_profile affected_dependency reported_at triage_state
  qualification_action evidence_action authorization_action artifact_action
  routing_owner required_requalification customer_notification_state final_decision
  fallback_action remediation_path execution_mode production_use
  customer_delivery_target)
set(_roles
  security-intake-owner incident-commander evidence-custodian product-owner community-liaison
  anocrypto-c-liaison release-authorizer evidence-reviewer
  customer-communications-owner)
set(_incident_states
  reported acknowledged triaged confirmed mitigating fixed requalifying closed
  rejected not-applicable)
set(_transition_edges
  "reported>acknowledged" "acknowledged>triaged" "triaged>confirmed"
  "triaged>rejected" "triaged>not-applicable" "confirmed>mitigating"
  "mitigating>fixed" "fixed>requalifying" "requalifying>closed")
set(_requalification_values
  community-revision enterprise-adapter approved-anocrypto-c-digest
  anocrypto-c-partial-profile no-openssl-fallback windows-full wsl-full
  windows-regression wsl-regression artifact-set manifest sbom attestation
  hosted-qualification signing-provenance-chain trusted-evidence authorization)
set(_seen_scenarios "")

foreach(_record_path IN LISTS _records)
  file(SIZE "${_record_path}" _record_size)
  if(_record_size GREATER 65536)
    message(FATAL_ERROR "Security tabletop record exceeds 64 KiB: ${_record_path}")
  endif()
  file(READ "${_record_path}" _record_raw)
  string(REPLACE "\r\n" "\n" _record "${_record_raw}")
  if(_record MATCHES "\r")
    message(FATAL_ERROR "Security tabletop record contains a non-canonical carriage return")
  endif()
  if(_record MATCHES "[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z][A-Za-z]+")
    message(FATAL_ERROR "Security tabletop record contains personal email data")
  endif()
  string(TOLOWER "${_record}" _lower_record)
  if(_lower_record MATCHES
      "(secret|token|password|private[_ -]?key|api[_ -]?key)[ \t]*[:=]"
     OR _record MATCHES "BEGIN [A-Z ]*PRIVATE KEY")
    message(FATAL_ERROR "Security tabletop record contains secret-like data")
  endif()

  string(JSON _root_type ERROR_VARIABLE _json_error TYPE "${_record}")
  if(_json_error OR NOT _root_type STREQUAL "OBJECT")
    message(FATAL_ERROR "Malformed security tabletop JSON: ${_json_error}")
  endif()
  _record_members(root "${_root_fields}")
  _record_members(final_decision
    "qualification;trusted_evidence;release_authorization;customer_release_ready"
    final_decision)

  foreach(_field IN ITEMS
      schema_version record_type scenario_id severity affected_product
      affected_revision affected_profile affected_dependency reported_at
      qualification_action evidence_action authorization_action artifact_action
      routing_owner customer_notification_state fallback_action remediation_path
      execution_mode)
    _record_get(_${_field} STRING ${_field})
  endforeach()
  _record_get(_production_use BOOLEAN production_use)
  _record_get(_customer_delivery_target BOOLEAN customer_delivery_target)
  foreach(_field IN ITEMS qualification trusted_evidence release_authorization)
    _record_get(_final_${_field} STRING final_decision ${_field})
  endforeach()
  _record_get(_final_customer_release_ready BOOLEAN
    final_decision customer_release_ready)
  _record_array(_triage_states triage_state)
  _record_array(_required_requalification required_requalification)

  get_filename_component(_record_name "${_record_path}" NAME)
  string(TOLOWER "${_scenario_id}" _scenario_slug)
  if(NOT _record_name STREQUAL "scenario-${_scenario_slug}.json")
    message(FATAL_ERROR
      "Scenario ${_scenario_id} filename mismatch: ${_record_name}")
  endif()
  list(FIND _seen_scenarios "${_scenario_id}" _duplicate)
  if(NOT _duplicate EQUAL -1)
    message(FATAL_ERROR "Duplicate tabletop scenario ID: ${_scenario_id}")
  endif()
  list(APPEND _seen_scenarios "${_scenario_id}")

  _record_enum(schema_version "${_schema_version}" 1)
  _record_enum(record_type "${_record_type}" test-only-security-tabletop)
  _record_enum(scenario_id "${_scenario_id}" A B C D E F)
  _record_enum(severity "${_severity}" critical high medium low)
  _record_enum(affected_product "${_affected_product}"
    "AnoSecureKit Enterprise" "AnoSecureKit Community" "AnoCrypto-C")
  _record_enum(affected_profile "${_affected_profile}" openssl anocrypto-c-partial)
  _record_enum(qualification_action "${_qualification_action}"
    invalidate set-not-passed)
  _record_enum(evidence_action "${_evidence_action}"
    reject set-unavailable verified reuse)
  _record_enum(authorization_action "${_authorization_action}"
    deny revoke set-unavailable allow reauthorize-before-closure)
  _record_enum(artifact_action "${_artifact_action}"
    block-generation withdraw-test-only quarantine-and-regenerate-test-only)
  _record_enum(routing_owner "${_routing_owner}" ${_roles})
  _record_enum(customer_notification_state "${_customer_notification_state}"
    not-sent-test-only)
  _record_enum(fallback_action "${_fallback_action}" none openssl)
  _record_enum(execution_mode "${_execution_mode}" test-only production)
  _record_enum(final_decision.qualification "${_final_qualification}"
    passed invalidated not-passed)
  _record_enum(final_decision.trusted_evidence "${_final_trusted_evidence}"
    verified rejected unavailable)

  if(NOT _affected_revision MATCHES "^test-only:")
    message(FATAL_ERROR
      "Scenario ${_scenario_id} affected_revision requires a test-only marker")
  endif()
  if(_affected_revision STREQUAL EXPECTED_SOURCE_REVISION)
    message(FATAL_ERROR
      "Scenario ${_scenario_id} test fixture aliases the current source revision")
  endif()
  _valid_timestamp(reported_at "${_reported_at}")
  string(TIMESTAMP _now "%Y-%m-%dT%H:%M:%SZ" UTC)
  if(_now STRLESS _reported_at)
    message(FATAL_ERROR "Scenario ${_scenario_id} reported_at is in the future")
  endif()

  foreach(_state IN LISTS _triage_states)
    _record_enum(triage_state "${_state}" ${_incident_states})
  endforeach()
  list(GET _triage_states 0 _first_state)
  list(GET _triage_states -1 _last_state)
  if(NOT _first_state STREQUAL "reported" OR NOT _last_state STREQUAL "closed")
    message(FATAL_ERROR
      "Scenario ${_scenario_id} must transition from reported to closed")
  endif()
  list(FIND _triage_states requalifying _requalifying_state)
  if(_requalifying_state EQUAL -1)
    message(FATAL_ERROR
      "Scenario ${_scenario_id} cannot close without requalification")
  endif()
  list(LENGTH _triage_states _state_count)
  math(EXPR _edge_last "${_state_count} - 2")
  foreach(_index RANGE 0 ${_edge_last})
    math(EXPR _next "${_index} + 1")
    list(GET _triage_states ${_index} _from)
    list(GET _triage_states ${_next} _to)
    list(FIND _transition_edges "${_from}>${_to}" _allowed_edge)
    if(_allowed_edge EQUAL -1)
      message(FATAL_ERROR
        "Scenario ${_scenario_id} has invalid incident transition: ${_from} -> ${_to}")
    endif()
  endforeach()
  foreach(_requirement IN LISTS _required_requalification)
    _record_enum(required_requalification "${_requirement}"
      ${_requalification_values})
  endforeach()
  if(_qualification_action STREQUAL "invalidate")
    _require_value(final_decision.qualification
      "${_final_qualification}" invalidated)
  else()
    _require_value(final_decision.qualification
      "${_final_qualification}" not-passed)
  endif()
  if(_evidence_action STREQUAL "reject")
    _require_value(final_decision.trusted_evidence
      "${_final_trusted_evidence}" rejected)
  elseif(_evidence_action STREQUAL "set-unavailable")
    _require_value(final_decision.trusted_evidence
      "${_final_trusted_evidence}" unavailable)
  else()
    message(FATAL_ERROR
      "Scenario ${_scenario_id} cannot reuse or verify affected evidence")
  endif()
  if(_authorization_action STREQUAL "reauthorize-before-closure")
    message(FATAL_ERROR "Tabletop reauthorization before closure is forbidden")
  endif()
  if(_severity MATCHES "^(critical|high)$"
     AND NOT _authorization_action MATCHES "^(deny|revoke|set-unavailable)$")
    message(FATAL_ERROR "Critical/high tabletop incident cannot allow release")
  endif()
  if(NOT _final_release_authorization STREQUAL "denied-or-unavailable")
    message(FATAL_ERROR
      "Scenario ${_scenario_id} final release authorization must be denied-or-unavailable")
  endif()
  if(_final_customer_release_ready OR _customer_delivery_target)
    message(FATAL_ERROR "Customer release readiness must remain false")
  endif()
  if(_fallback_action STREQUAL "openssl")
    message(FATAL_ERROR "OpenSSL fallback is forbidden in security tabletop records")
  endif()
  if(NOT _execution_mode STREQUAL "test-only" OR _production_use)
    message(FATAL_ERROR "Security tabletop fixtures cannot run in production mode")
  endif()

  if(_scenario_id STREQUAL "A")
    _require_value(affected_product "${_affected_product}" "AnoSecureKit Community")
    _require_value(affected_profile "${_affected_profile}" openssl)
    _require_value(affected_dependency "${_affected_dependency}" "Community OpenSSL provider")
    _require_value(routing_owner "${_routing_owner}" community-liaison)
    _require_value(remediation_path "${_remediation_path}" consume-new-community-revision)
    _require_requalification(community-revision)
    _require_requalification(windows-full)
    _require_requalification(wsl-full)
  elseif(_scenario_id STREQUAL "B")
    _require_value(affected_product "${_affected_product}" "AnoSecureKit Enterprise")
    _require_value(affected_profile "${_affected_profile}" anocrypto-c-partial)
    _require_value(affected_dependency "${_affected_dependency}" "AnoCrypto-C adapter")
    _require_value(routing_owner "${_routing_owner}" product-owner)
    _require_value(remediation_path "${_remediation_path}" fix-enterprise-adapter)
    _require_requalification(enterprise-adapter)
    _require_requalification(windows-regression)
    _require_requalification(wsl-regression)
  elseif(_scenario_id STREQUAL "C")
    _require_value(affected_product "${_affected_product}" "AnoCrypto-C")
    _require_value(affected_profile "${_affected_profile}" anocrypto-c-partial)
    _require_value(affected_dependency "${_affected_dependency}" "AnoCrypto-C package digest")
    _require_value(routing_owner "${_routing_owner}" anocrypto-c-liaison)
    _require_value(remediation_path "${_remediation_path}" consume-new-anocrypto-c-package)
    _require_requalification(approved-anocrypto-c-digest)
    _require_requalification(no-openssl-fallback)
  elseif(_scenario_id STREQUAL "D")
    _require_value(affected_product "${_affected_product}" "AnoSecureKit Enterprise")
    _require_value(affected_dependency "${_affected_dependency}" "signing trust chain")
    _require_value(routing_owner "${_routing_owner}" evidence-reviewer)
    _require_value(remediation_path "${_remediation_path}" new-signing-provenance-chain)
    _require_requalification(signing-provenance-chain)
    _require_requalification(trusted-evidence)
  elseif(_scenario_id STREQUAL "E")
    _require_value(affected_product "${_affected_product}" "AnoSecureKit Enterprise")
    _require_value(affected_dependency "${_affected_dependency}" "hosted qualification evidence")
    _require_value(routing_owner "${_routing_owner}" evidence-reviewer)
    _require_value(remediation_path "${_remediation_path}" rerun-hosted-qualification)
    _require_requalification(hosted-qualification)
    _require_requalification(attestation)
  elseif(_scenario_id STREQUAL "F")
    _require_value(affected_product "${_affected_product}" "AnoSecureKit Enterprise")
    _require_value(affected_dependency "${_affected_dependency}" "artifact manifest SBOM")
    _require_value(routing_owner "${_routing_owner}" product-owner)
    _require_value(remediation_path "${_remediation_path}" regenerate-artifact-set)
    _require_requalification(artifact-set)
    _require_requalification(manifest)
    _require_requalification(sbom)
  endif()
endforeach()

foreach(_required_scenario IN ITEMS A B C D E F)
  list(FIND _seen_scenarios "${_required_scenario}" _found)
  if(_found EQUAL -1)
    message(FATAL_ERROR "Required tabletop scenario is missing: ${_required_scenario}")
  endif()
endforeach()

message(STATUS
  "Enterprise security tabletop check passed: scenarios A-F, fail-closed decisions, no production use")
