# SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary
cmake_minimum_required(VERSION 3.20)

if(NOT IS_ABSOLUTE "${CAPTURE}" OR NOT IS_ABSOLUTE "${FIXTURE}")
  message(FATAL_ERROR "CAPTURE and FIXTURE must be absolute executable paths")
endif()
string(HEX "${FIXTURE}" fixture_hex)

function(run_capture result_var output_var format timeout limit)
  set(command_args "x${fixture_hex}")
  math(EXPR last_arg "${ARGC} - 1")
  foreach(index RANGE 5 ${last_arg})
    string(HEX "${ARGV${index}}" argument_hex)
    list(APPEND command_args "x${argument_hex}")
  endforeach()
  execute_process(
    COMMAND "${CAPTURE}" capture "${timeout}" "${limit}" "${format}" ${command_args}
    RESULT_VARIABLE result
    OUTPUT_VARIABLE output
    ERROR_QUIET
    ENCODING UTF-8
    TIMEOUT 5)
  set("${result_var}" "${result}" PARENT_SCOPE)
  set("${output_var}" "${output}" PARENT_SCOPE)
endfunction()

function(check_envelope name result output backend_exit expected_stdout expected_stderr)
  if(NOT "${result}" STREQUAL "0")
    message(FATAL_ERROR "${name}: expected capture to succeed, got '${result}'")
  endif()
  string(JSON member_count ERROR_VARIABLE json_error LENGTH "${output}")
  if(NOT "${json_error}" STREQUAL "NOTFOUND" OR NOT member_count EQUAL 4)
    message(FATAL_ERROR "${name}: expected a four-member capture envelope")
  endif()
  string(JSON protocol GET "${output}" protocol)
  string(JSON exit_type TYPE "${output}" exit)
  string(JSON exit_status GET "${output}" exit)
  if(NOT "${protocol}" STREQUAL "ask-verifier-capture-v1"
     OR NOT "${exit_type}" STREQUAL "NUMBER"
     OR NOT "${exit_status}" STREQUAL "${backend_exit}")
    message(FATAL_ERROR "${name}: capture protocol or backend exit status did not match")
  endif()
  foreach(stream IN ITEMS stdout stderr)
    string(JSON stream_type TYPE "${output}" "${stream}")
    string(JSON stream_value GET "${output}" "${stream}")
    if(NOT "${stream_type}" STREQUAL "STRING"
       OR NOT "${stream_value}" STREQUAL "${expected_${stream}}")
      string(LENGTH "${stream_value}" stream_length)
      string(LENGTH "${expected_${stream}}" expected_length)
      message(FATAL_ERROR
        "${name}: capture ${stream} bytes differed (got ${stream_length}, expected ${expected_length})")
    endif()
  endforeach()
endfunction()

function(check_failure name result output expected_status)
  if(NOT "${result}" STREQUAL "${expected_status}" OR NOT "${output}" STREQUAL "")
    message(FATAL_ERROR
      "${name}: expected capture status ${expected_status} with empty stdout, got '${result}'")
  endif()
endfunction()

string(ASCII 13 cr)
string(ASCII 27 escape)
run_capture(result output text 3000 1024 text)
check_envelope("text transport" "${result}" "${output}" 23
  "sample: \"quoted\" \\ text${cr}\nnext\tline\n"
  "note${escape}\n")

string(ASCII 195 169 32 236 149 136 32 240 159 141 128 unicode)
set(quoted [=[space "quote" then \]=])
set(slashed [=[two\\" backslashes]=])
run_capture(result output text 3000 1024 argv "" "${quoted}" "${slashed}" "${unicode}" "a;b" "")
check_envelope("argument transport" "${result}" "${output}" 0
  "<>\n<${quoted}>\n<${slashed}>\n<${unicode}>\n<a;b>\n<>\n" "")

set(cap 131072)
string(REPEAT "o" ${cap} expected_stdout)
string(REPEAT "e" ${cap} expected_stderr)
run_capture(result output text 3000 "${cap}" exact-cap)
check_envelope("both streams at independent limits" "${result}" "${output}" 0
  "${expected_stdout}" "${expected_stderr}")

run_capture(result output text 3000 "${cap}" stdout-over-cap)
check_failure("stdout over limit" "${result}" "${output}" 66)
run_capture(result output text 3000 "${cap}" stderr-over-cap)
check_failure("stderr over limit" "${result}" "${output}" 66)

run_capture(result output text 3000 1024 malformed-stdout)
check_failure("malformed UTF-8 on stdout" "${result}" "${output}" 68)
run_capture(result output json 3000 1024 malformed-stderr)
check_failure("malformed UTF-8 on stderr" "${result}" "${output}" 68)
run_capture(result output json 3000 1024 nul-stdout)
check_failure("raw NUL on stdout" "${result}" "${output}" 68)
run_capture(result output text 3000 1024 nul-stderr)
check_failure("raw NUL on stderr" "${result}" "${output}" 68)

run_capture(result output json 3000 1024 json)
set(expected_json [=[{"name":"\u0000","surrogate pair":"\uD83C\uDF40","literal":"\\u0000"}]=])
check_envelope("lossless JSON string escapes" "${result}" "${output}" 0
  "${expected_json}\n" "literal \\uD800\n")
run_capture(result output json 3000 1024 lone-surrogate)
check_failure("unpaired JSON escape" "${result}" "${output}" 70)

run_capture(result output text 3000 1024 signal)
check_failure("fixture terminated by signal" "${result}" "${output}" 69)

# Only the fixture's lifecycle markers are written to disk.
string(RANDOM LENGTH 16 ALPHABET "0123456789abcdef" marker_id)
set(marker "${CMAKE_CURRENT_BINARY_DIR}/capture-${marker_id}")
run_capture(result output text 700 1024 tree "${marker}")
execute_process(COMMAND "${CMAKE_COMMAND}" -E sleep 2)
set(tree_started FALSE)
set(tree_survived FALSE)
if(EXISTS "${marker}.started")
  set(tree_started TRUE)
endif()
if(EXISTS "${marker}.parent" OR EXISTS "${marker}.child")
  set(tree_survived TRUE)
endif()
file(REMOVE "${marker}.started" "${marker}.parent" "${marker}.child")
check_failure("process tree timeout" "${result}" "${output}" 67)
if(NOT tree_started)
  message(FATAL_ERROR "process tree timeout: fixture did not launch the descendant")
endif()
if(tree_survived)
  message(FATAL_ERROR "process tree timeout: a fixture process survived capture")
endif()

function(check_adapter_rejection mode diagnostic)
  set(report "${adapter_root}/${mode}.json")
  file(WRITE "${report}" "{\"verification_status\":\"verified\"}\n")
  execute_process(
    COMMAND "${CMAKE_COMMAND}"
      "-DVERIFIER_CAPTURE_EXECUTABLE=${CAPTURE}"
      "-DVERIFIER_CAPTURE_BUILD_RECEIPT=${CAPTURE_RECEIPT}"
      "-DVERIFIER_EXECUTABLE=${FIXTURE}" "-DTEST_VERIFIER_SCRIPT=${CMAKE_CURRENT_LIST_FILE}"
      "-DTEST_VERIFIER_MODE=${mode}" -DALLOW_TEST_VERIFIER=ON -DREQUIRE_VERIFIED=ON
      -DVERIFIER_TIMEOUT_SECONDS=1
      "-DARTIFACT_PATH=${artifact}" "-DEXPECTED_SUBJECT_DIGEST=sha256:${artifact_digest}"
      "-DEXPECTED_SOURCE_REPOSITORY=${repository}" "-DEXPECTED_SOURCE_REVISION=${revision}"
      "-DEXPECTED_WORKFLOW_IDENTITY=${repository}/.github/workflows/test.yml"
      "-DEXPECTED_TRUST_DOMAIN=https://token.actions.githubusercontent.com"
      "-DATTESTATION_REFERENCE=https://github.com/${repository}/attestations/1"
      "-DVERIFIER_JSON_OUTPUT=${report}" -P "${ADAPTER}"
    RESULT_VARIABLE result
    OUTPUT_QUIET
    ERROR_VARIABLE stderr
    TIMEOUT 5)
  string(REGEX REPLACE "[ \t\r\n]+" " " stderr "${stderr}")
  string(FIND "${stderr}" "${diagnostic}" diagnostic_position)
  if(NOT "${result}" STREQUAL "1" OR diagnostic_position EQUAL -1)
    message(FATAL_ERROR "${mode}: expected adapter rejection with '${diagnostic}', got '${result}'")
  endif()
  file(READ "${report}" record)
  string(JSON verification GET "${record}" verification_status)
  string(JSON trusted GET "${record}" trusted_evidence)
  string(JSON authorization GET "${record}" release_authorization)
  string(JSON ready_type TYPE "${record}" customer_release_ready)
  string(JSON ready GET "${record}" customer_release_ready)
  string(JSON test_mode GET "${record}" test_mode)
  if(NOT verification STREQUAL "rejected" OR NOT trusted STREQUAL "unavailable"
     OR NOT authorization STREQUAL "denied-or-unavailable" OR NOT ready_type STREQUAL "BOOLEAN"
     OR ready OR NOT test_mode)
    message(FATAL_ERROR "${mode}: adapter did not write a default-deny report")
  endif()
  message(STATUS "${mode}: exit 1, ${diagnostic}, test mode and default deny")
endfunction()

if(DEFINED ADAPTER)
  set(adapter_root "${CMAKE_CURRENT_BINARY_DIR}/capture-${marker_id}-adapter")
  set(artifact "${adapter_root}/fixture.txt")
  set(repository "fixture/synthetic")
  string(REPEAT "1" 40 revision)
  file(WRITE "${artifact}" "synthetic test artifact\n")
  file(SHA256 "${artifact}" artifact_digest)
  check_adapter_rejection(nul-stdout "verification output contains invalid verifier output bytes")
  check_adapter_rejection(malformed-stdout "verification output contains invalid verifier output bytes")
  check_adapter_rejection(lone-surrogate "malformed machine-readable verifier output")
  check_adapter_rejection(lone-low-surrogate "malformed machine-readable verifier output")
  check_adapter_rejection(raw-control "malformed machine-readable verifier output")
  check_adapter_rejection(escaped-nul-duplicate "duplicate JSON object member")
  check_adapter_rejection(array-ancestry "unexpected runnerEnvironment path")
  check_adapter_rejection(nested-document "machine-readable verifier output exceeds JSON nesting limit")
  file(REMOVE_RECURSE "${adapter_root}")
endif()
message(STATUS "Verifier capture checks passed")
