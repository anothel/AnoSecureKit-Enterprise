# SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary
cmake_minimum_required(VERSION 3.20)

foreach(_required IN ITEMS SOURCE_DIR FIXTURE_DIR)
  if(NOT DEFINED ${_required} OR "${${_required}}" STREQUAL "")
    message(FATAL_ERROR "${_required} is required for security system activation readiness verification")
  endif()
endforeach()
if(NOT IS_DIRECTORY "${FIXTURE_DIR}")
  message(FATAL_ERROR "Security system readiness fixture directory is missing")
endif()

set(_required_docs
  SECURITY_EVIDENCE_REPOSITORY_REQUIREMENTS.md
  INCIDENT_TRACKER_REQUIREMENTS.md
  SECURITY_ARCHIVE_REQUIREMENTS.md
  SECURITY_OPERATIONS_ACTIVATION_CHECKLIST.md
  SECURITY_SYSTEM_INTEGRATION_BOUNDARY.md
  SECURITY_SYSTEM_ACTIVATION_READINESS_RESULT.md
  SECURITY_EVIDENCE_CUSTODY_POLICY.md
  SECURITY_DECISION_LOG_POLICY.md
  SECURITY_RECORD_RETENTION_POLICY.md
  SECURITY_EVIDENCE_HANDLING_RUNBOOK.md
  SECURITY_INCIDENT_RESPONSE_RUNBOOK.md
  SECURITY_OPERATIONS_ROLE_MODEL.md)
set(_docs "")
foreach(_doc IN LISTS _required_docs)
  set(_path "${SOURCE_DIR}/docs/${_doc}")
  if(NOT EXISTS "${_path}" OR IS_DIRECTORY "${_path}")
    message(FATAL_ERROR "Required security system readiness document is missing: ${_doc}")
  endif()
  file(READ "${_path}" _content)
  string(APPEND _docs "\n${_content}")
endforeach()
foreach(_marker IN ITEMS
    "approved evidence repository: not yet activated"
    "approved incident tracking system: not yet activated"
    "approved long-term archive: not yet activated"
    "approved private reporting channel: not yet activated"
    "assigned operational roles: none"
    "activation_ready: false"
    "customer_release_ready: false"
    "reported acknowledged triaged confirmed mitigating fixed requalifying closed rejected not-applicable"
    "storage integrity" "record integrity" "cryptographic evidence verification"
    "tracker state != release PASS" "restore rehearsal" "repository-independent recovery"
    "internal policy targets" "not statutory" "credentialless" "OIDC"
    "no network adapter" "vendor SDK" "silent/local fallback")
  string(FIND "${_docs}" "${_marker}" _found)
  if(_found EQUAL -1)
    message(FATAL_ERROR "Security system readiness documents omit required marker: ${_marker}")
  endif()
endforeach()

set(_operations
  create_record append_event attach_evidence_reference read_record export_record
  verify_record_version apply_retention apply_legal_hold revoke_record close_record
  reopen_record health_check capability_query)
set(_adapter_statuses
  available degraded unavailable unauthorized invalid-request conflict not-found
  rate-limited internal-error)
set(_retention_classes ephemeral operational security-record release-evidence legal-hold)
set(_workflow_states
  reported acknowledged triaged confirmed mitigating fixed requalifying closed
  rejected not-applicable)
set(_gates
  governance.system-owner-assigned governance.data-owner-assigned
  governance.security-owner-assigned governance.approver-assigned
  governance.retention-policy-approved governance.access-policy-approved
  governance.incident-workflow-approved security.threat-model
  security.least-privilege-roles security.authentication-method
  security.secret-oidc-policy security.audit-logging security.encryption
  security.backup-restore security.compromise-revocation
  security.vendor-security-review technical.sandbox-environment
  technical.schema-mapping technical.api-version-qualification
  technical.rate-size-limits technical.export-test technical.restore-test
  technical.outage-behavior technical.idempotency technical.duplicate-detection
  technical.clock-timestamp-handling technical.path-input-safety
  operations.role-assignment operations.on-call-escalation operations.monitoring
  operations.alerting operations.incident-tracker-integration
  operations.archive-handoff operations.tabletop-rehearsal
  operations.recovery-rehearsal operations.deactivation-procedure)
set(_roles
  security-intake-owner incident-commander evidence-custodian evidence-reviewer
  release-authorizer product-owner community-liaison anocrypto-c-liaison
  customer-communications-owner)
set(_root_fields
  schema_version system_type backend_id backend_version environment owner_role
  security_owner_role data_owner_role role_assignment_status authentication_mode
  capabilities required_gates gate_results threat_model_status access_review_status
  backup_restore_status export_status outage_test_status revocation_test_status
  tabletop_status backend_status fallback_mode last_operation_status
  operation_success transaction_state approved_at expires_at activation_ready
  trusted_evidence release_authorization customer_release_ready activation_decision
  test_only)
set(_capability_fields
  operations statuses retention_classes workflow_states system_features)

function(_enum label value)
  list(FIND ARGN "${value}" _found)
  if(_found EQUAL -1)
    message(FATAL_ERROR "Unsupported security system readiness ${label}: ${value}")
  endif()
endfunction()

function(_unsafe label value)
  string(TOLOWER "${value}" _lower)
  if(value MATCHES "[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z][A-Za-z]+")
    message(FATAL_ERROR "Security system readiness ${label} contains personal email or username")
  endif()
  if(_lower MATCHES "(secret|token|password|api[_ -]?key)[ \t]*[:=]"
     OR value MATCHES "BEGIN [A-Z ]*PRIVATE KEY")
    message(FATAL_ERROR "Security system readiness ${label} contains secret or private-key material")
  endif()
  if(value MATCHES "(^|[ \t\"])([A-Za-z]:[/\\\\]|/|\\\\\\\\)")
    message(FATAL_ERROR "Security system readiness ${label} contains a local absolute path")
  endif()
  if(_lower MATCHES "(^|[/\\\\])credentials?([/\\\\]|$)")
    message(FATAL_ERROR "Security system readiness ${label} contains an actual credential path")
  endif()
  if(_lower MATCHES "https?://")
    message(FATAL_ERROR "Security system readiness ${label} contains a real or secret URL")
  endif()
  if(value MATCHES "(^|[^0-9])[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]([^0-9]|$)"
     OR _lower MATCHES "(^|:)(account|subscription|tenant)[-_:][a-z0-9-]+")
    message(FATAL_ERROR "Security system readiness ${label} contains an actual account identifier")
  endif()
endfunction()

function(_timestamp label value allow_future)
  if(NOT value MATCHES "^[0-9][0-9][0-9][0-9]-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01])T([01][0-9]|2[0-3]):[0-5][0-9]:[0-5][0-9]Z$")
    message(FATAL_ERROR "Security system readiness ${label} must use UTC YYYY-MM-DDTHH:MM:SSZ")
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
    message(FATAL_ERROR "Security system readiness ${label} is not a valid calendar timestamp")
  endif()
  string(TIMESTAMP _now "%Y-%m-%dT%H:%M:%SZ" UTC)
  if(NOT allow_future AND _now STRLESS value)
    message(FATAL_ERROR "Security system readiness ${label} is in the future")
  endif()
endfunction()

function(_members label expected)
  set(_path ${ARGN})
  string(JSON _count ERROR_VARIABLE _error LENGTH "${_record}" ${_path})
  if(_error)
    message(FATAL_ERROR "Missing or malformed security system readiness object: ${label}")
  endif()
  list(LENGTH expected _expected_count)
  if(NOT _count EQUAL _expected_count)
    message(FATAL_ERROR "Security system readiness ${label} field count mismatch")
  endif()
  if(_count GREATER 0)
    math(EXPR _last "${_count} - 1")
    foreach(_index RANGE 0 ${_last})
      string(JSON _member MEMBER "${_record}" ${_path} ${_index})
      list(FIND expected "${_member}" _known)
      if(_known EQUAL -1)
        message(FATAL_ERROR "Unknown security system readiness ${label} field: ${_member}")
      endif()
    endforeach()
  endif()
endfunction()

function(_get output expected_type)
  set(_path ${ARGN})
  string(JSON _type ERROR_VARIABLE _error TYPE "${_record}" ${_path})
  if(_error)
    list(JOIN _path "." _label)
    message(FATAL_ERROR "Missing security system readiness field: ${_label}")
  endif()
  if(NOT _type STREQUAL "${expected_type}")
    list(JOIN _path "." _label)
    message(FATAL_ERROR "Security system readiness field ${_label} must be ${expected_type}")
  endif()
  string(JSON _value GET "${_record}" ${_path})
  set(${output} "${_value}" PARENT_SCOPE)
endfunction()

function(_array_exact label expected)
  set(_path ${ARGN})
  string(JSON _type ERROR_VARIABLE _error TYPE "${_record}" ${_path})
  if(_error OR NOT _type STREQUAL "ARRAY")
    message(FATAL_ERROR "Security system readiness ${label} must be an array")
  endif()
  string(JSON _count LENGTH "${_record}" ${_path})
  list(LENGTH expected _expected_count)
  if(NOT _count EQUAL _expected_count)
    message(FATAL_ERROR "Security system readiness ${label} count mismatch")
  endif()
  set(_actual "")
  if(_count GREATER 0)
    math(EXPR _last "${_count} - 1")
    foreach(_index RANGE 0 ${_last})
      _get(_value STRING ${_path} ${_index})
      _unsafe("${label}" "${_value}")
      list(APPEND _actual "${_value}")
    endforeach()
  endif()
  if(NOT "${_actual}" STREQUAL "${expected}")
    message(FATAL_ERROR "Security system readiness ${label} has missing, unknown, duplicate, or reordered capability")
  endif()
endfunction()

file(GLOB _fixture_files LIST_DIRECTORIES false "${FIXTURE_DIR}/*.json")
list(SORT _fixture_files)
list(LENGTH _fixture_files _fixture_count)
if(NOT _fixture_count EQUAL 3)
  message(FATAL_ERROR "Security system readiness requires exactly 3 JSON fixtures")
endif()

set(_seen_types "")
foreach(_fixture IN LISTS _fixture_files)
  file(SIZE "${_fixture}" _size)
  if(_size GREATER 131072)
    message(FATAL_ERROR "Security system readiness fixture exceeds 128 KiB")
  endif()
  file(READ "${_fixture}" _record_raw)
  string(REPLACE "\r\n" "\n" _record "${_record_raw}")
  if(_record MATCHES "\r")
    message(FATAL_ERROR "Security system readiness fixture contains a carriage return")
  endif()
  string(JSON _root_type ERROR_VARIABLE _error TYPE "${_record}")
  if(_error OR NOT _root_type STREQUAL "OBJECT")
    message(FATAL_ERROR "Malformed security system readiness JSON")
  endif()
  _members(root "${_root_fields}")
  _members(capabilities "${_capability_fields}" capabilities)

  foreach(_field IN LISTS _root_fields)
    string(REGEX MATCHALL "\"${_field}\"[ \t\n]*:" _matches "${_record}")
    list(LENGTH _matches _match_count)
    if(NOT _match_count EQUAL 1)
      message(FATAL_ERROR "Duplicate or missing security system readiness field: ${_field}")
    endif()
  endforeach()

  foreach(_field IN ITEMS
      schema_version system_type backend_id backend_version environment owner_role
      security_owner_role data_owner_role role_assignment_status authentication_mode
      threat_model_status access_review_status backup_restore_status export_status
      outage_test_status revocation_test_status tabletop_status backend_status
      fallback_mode last_operation_status transaction_state trusted_evidence
      release_authorization activation_decision)
    _get(_${_field} STRING ${_field})
    _unsafe("${_field}" "${_${_field}}")
  endforeach()
  foreach(_field IN ITEMS operation_success activation_ready customer_release_ready test_only)
    _get(_${_field} BOOLEAN ${_field})
  endforeach()

  if(NOT _schema_version STREQUAL "1")
    message(FATAL_ERROR "Unsupported security system readiness schema version")
  endif()
  _enum(system_type "${_system_type}"
    evidence-repository incident-tracker security-archive)
  list(FIND _seen_types "${_system_type}" _duplicate_type)
  if(NOT _duplicate_type EQUAL -1)
    message(FATAL_ERROR "Duplicate security system readiness system type")
  endif()
  list(APPEND _seen_types "${_system_type}")

  get_filename_component(_fixture_name "${_fixture}" NAME_WE)
  if(NOT _fixture_name STREQUAL _system_type)
    message(FATAL_ERROR "Security system readiness fixture name/type mismatch")
  endif()
  if(NOT _backend_id MATCHES "^test-only:[a-z0-9-]+$" OR _backend_id STREQUAL "test-only:")
    message(FATAL_ERROR "Security system readiness backend_id is missing or unsafe")
  endif()
  if(NOT _backend_version STREQUAL "not-configured"
     OR NOT _environment STREQUAL "test-only:contract-fixture")
    message(FATAL_ERROR "Security system readiness fixture attempts production mode")
  endif()
  foreach(_role_field IN ITEMS owner_role security_owner_role data_owner_role)
    _enum("${_role_field}" "${_${_role_field}}" ${_roles})
  endforeach()
  _enum(role_assignment_status "${_role_assignment_status}" unassigned assigned-test-only)
  _enum(authentication_mode "${_authentication_mode}"
    not-configured credentialless-oidc managed-workload-identity)

  _array_exact("adapter operations" "${_operations}" capabilities operations)
  _array_exact("adapter statuses" "${_adapter_statuses}" capabilities statuses)
  _array_exact("retention classes" "${_retention_classes}" capabilities retention_classes)
  _array_exact("workflow states" "${_workflow_states}" capabilities workflow_states)
  _array_exact("required gates" "${_gates}" required_gates)

  if(_system_type STREQUAL "evidence-repository")
    set(_features
      idempotency-key duplicate-write-detection partial-transaction-semantics
      authoritative-timestamp remote-id-canonical-digest-binding
      backend-version-binding no-local-fallback
      append-only-records object-version-id sha256-metadata canonical-digest
      worm-retention rbac-separation audit-log legal-hold revocation-deletion
      encryption region-control backup-disaster-recovery export-stability
      fail-closed credentialless-auth secret-rotation)
  elseif(_system_type STREQUAL "incident-tracker")
    set(_features
      idempotency-key duplicate-write-detection partial-transaction-semantics
      authoritative-timestamp remote-id-canonical-digest-binding
      backend-version-binding no-local-fallback
      immutable-record-id workflow-state-machine severity-bindings
      nonpersonal-routing custody-reference decision-reference
      authorization-binding evidence-binding artifact-binding
      disclosure-notification next-review closure-reopen audit-history
      attachment-digest restricted-visibility export-backup duplicate-link
      upstream-downstream-link)
  else()
    set(_features
      idempotency-key duplicate-write-detection partial-transaction-semantics
      authoritative-timestamp remote-id-canonical-digest-binding
      backend-version-binding no-local-fallback
      original-bytes ingest-digest periodic-verification migration-record
      expiry-policy legal-hold deletion-approval-evidence restore-rehearsal
      offline-export repository-independent-recovery audit-preservation
      key-lifecycle compromise-handling)
  endif()
  _array_exact("${_system_type} features" "${_features}" capabilities system_features)

  _members(gate_results "${_gates}" gate_results)
  foreach(_gate IN LISTS _gates)
    _get(_gate_result STRING gate_results "${_gate}")
    _enum("gate result ${_gate}" "${_gate_result}" not-run passed failed expired)
  endforeach()
  foreach(_field IN ITEMS threat_model_status access_review_status
      backup_restore_status export_status outage_test_status
      revocation_test_status tabletop_status)
    _enum("${_field}" "${_${_field}}" not-run passed failed expired)
  endforeach()
  _enum(backend_status "${_backend_status}" ${_adapter_statuses})
  _enum(last_operation_status "${_last_operation_status}" ${_adapter_statuses})
  _enum(transaction_state "${_transaction_state}"
    not-started no-write completed recoverable-partial partial-committed)
  if(NOT _fallback_mode STREQUAL "forbidden")
    message(FATAL_ERROR "Security system readiness forbids silent local fallback")
  endif()
  if(_operation_success AND NOT _last_operation_status STREQUAL "available")
    message(FATAL_ERROR "Security system readiness cannot report rate-limit or failed status as success")
  endif()
  if(_transaction_state STREQUAL "partial-committed")
    message(FATAL_ERROR "Security system readiness forbids a committed partial write")
  endif()

  unset(_approved_at)
  unset(_expires_at)
  foreach(_time_field IN ITEMS approved_at expires_at)
    string(JSON _time_type TYPE "${_record}" ${_time_field})
    set(_${_time_field}_type "${_time_type}")
    if(_time_type STREQUAL "STRING")
      string(JSON _${_time_field} GET "${_record}" ${_time_field})
      if(_time_field STREQUAL "approved_at")
        _timestamp(approved_at "${_approved_at}" FALSE)
      else()
        _timestamp(expires_at "${_expires_at}" TRUE)
        string(TIMESTAMP _now "%Y-%m-%dT%H:%M:%SZ" UTC)
        if(NOT _now STRLESS _expires_at)
          message(FATAL_ERROR "Security system readiness approval is expired")
        endif()
      endif()
    elseif(NOT _time_type STREQUAL "NULL")
      message(FATAL_ERROR "Security system readiness ${_time_field} must be STRING or NULL")
    endif()
  endforeach()
  if(DEFINED _approved_at AND DEFINED _expires_at AND NOT _approved_at STRLESS _expires_at)
    message(FATAL_ERROR "Security system readiness approval interval is invalid")
  endif()

  _enum(trusted_evidence "${_trusted_evidence}" unavailable rejected verified)
  _enum(release_authorization "${_release_authorization}" denied-or-unavailable allowed)
  _enum(activation_decision "${_activation_decision}" deny allow)
  if(NOT _test_only)
    message(FATAL_ERROR "Security system readiness fixtures require test-only mode")
  endif()
  if(_customer_release_ready)
    message(FATAL_ERROR "Security system cannot be customer-ready before activation")
  endif()
  if(_activation_decision STREQUAL "deny")
    if(_activation_ready)
      message(FATAL_ERROR "Denied security system readiness cannot set activation_ready")
    endif()
    if(NOT _approved_at_type STREQUAL "NULL" OR NOT _expires_at_type STREQUAL "NULL")
      message(FATAL_ERROR "Denied security system readiness cannot contain approval timestamps")
    endif()
  else()
    foreach(_field IN ITEMS threat_model_status access_review_status
        backup_restore_status export_status outage_test_status
        revocation_test_status tabletop_status)
      if(NOT _${_field} STREQUAL "passed")
        message(FATAL_ERROR "Security system readiness allow is missing required ${_field}")
      endif()
    endforeach()
    foreach(_gate IN LISTS _gates)
      _get(_gate_result STRING gate_results "${_gate}")
      if(NOT _gate_result STREQUAL "passed")
        message(FATAL_ERROR "Security system readiness allow has an unpassed gate: ${_gate}")
      endif()
    endforeach()
    if(NOT _trusted_evidence STREQUAL "verified"
       OR NOT _release_authorization STREQUAL "allowed")
      message(FATAL_ERROR "Security system readiness cannot allow without trusted evidence and authorization")
    endif()
    if(NOT _role_assignment_status STREQUAL "assigned-test-only")
      message(FATAL_ERROR "Security system readiness cannot allow with unassigned roles")
    endif()
    if(NOT _backend_status STREQUAL "available")
      message(FATAL_ERROR "Security system readiness cannot allow an unavailable or degraded backend")
    endif()
    if(_authentication_mode STREQUAL "not-configured")
      message(FATAL_ERROR "Security system readiness cannot allow without approved authentication")
    endif()
    if(NOT _activation_ready)
      message(FATAL_ERROR "Security system readiness allow requires activation_ready")
    endif()
    if(NOT DEFINED _approved_at OR NOT DEFINED _expires_at)
      message(FATAL_ERROR "Security system readiness allow requires approval timestamps")
    endif()
    message(FATAL_ERROR "Test-only security system readiness fixtures can never activate a production system")
  endif()
endforeach()

set(_expected_types evidence-repository incident-tracker security-archive)
if(NOT "${_seen_types}" STREQUAL "${_expected_types}")
  message(FATAL_ERROR "Security system readiness fixture types are incomplete")
endif()

file(READ "${SOURCE_DIR}/release/customer-release-authorization.json" _authorization)
string(JSON _authorization_decision ERROR_VARIABLE _authorization_error
  GET "${_authorization}" decision)
if(_authorization_error OR NOT _authorization_decision STREQUAL "deny")
  message(FATAL_ERROR "Security system readiness requires default release authorization deny")
endif()
file(READ "${SOURCE_DIR}/cmake/anosecurekitEnterpriseConfig.cmake.in" _package_config)
if(NOT _package_config MATCHES "ANOSECUREKIT_ENTERPRISE_CUSTOMER_RELEASE_READY FALSE")
  message(FATAL_ERROR "Security system readiness requires customer_release_ready false")
endif()
file(READ "${SOURCE_DIR}/tests/package/check_delivery_package.cmake" _package_check)
foreach(_package_marker IN ITEMS "security-system-readiness" "activation_decision")
  string(FIND "${_package_check}" "${_package_marker}" _package_marker_position)
  if(_package_marker_position EQUAL -1)
    message(FATAL_ERROR
      "Security system readiness fixture package exclusion is missing: ${_package_marker}")
  endif()
endforeach()

message(STATUS
  "Security system activation readiness passed: 3 test-only deny fixtures, 36 gates each, systems inactive, customer release blocked")
