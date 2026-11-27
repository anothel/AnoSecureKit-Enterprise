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

set(_fixture_executable "${CMAKE_COMMAND}")
if(CMAKE_VERSION VERSION_LESS 3.24)
  # Older CMake scans past -- for documentation flags before running -P.
  # Use a native launcher to escape the final probe flag without a shell.
  set(_launcher_source "${TEST_ROOT}/launcher")
  file(MAKE_DIRECTORY "${_launcher_source}")
  file(WRITE "${_launcher_source}/CMakeLists.txt" [=[
cmake_minimum_required(VERSION 3.20)
project(VerifierFixtureLauncher LANGUAGES CXX)
add_executable(fixture-launcher main.cpp)
target_compile_features(fixture-launcher PRIVATE cxx_std_11)
if(MINGW)
  target_link_options(fixture-launcher PRIVATE -municode)
endif()
file(GENERATE OUTPUT "${CMAKE_BINARY_DIR}/launcher-$<CONFIG>.txt"
  CONTENT "$<TARGET_FILE:fixture-launcher>")
]=])
  file(WRITE "${_launcher_source}/main.cpp" [=[
#include <cstdlib>
#include <string>

#ifdef _WIN32
#include <windows.h>

int wmain(int argc, wchar_t** argv)
{
    const wchar_t* cmake = _wgetenv(L"VERIFIER_FIXTURE_CMAKE");
    if (!cmake || argc < 2) {
        return EXIT_FAILURE;
    }

    // Preserve the native quoting of every argument supplied by the adapter.
    std::wstring command = GetCommandLineW();
    const auto firstArgument = command.front() == L'"'
        ? command.find(L'"', 1) + 1 : command.find_first_of(L" \t");
    command.replace(0, firstArgument, L"\"" + std::wstring(cmake) + L"\"");
    const std::wstring last = argv[argc - 1];
    if (last == L"--version" || last == L"--help") {
        command.insert(command.rfind(last), L"fixture:");
    }

    STARTUPINFOW startup{};
    startup.cb = sizeof(startup);
    startup.dwFlags = STARTF_USESTDHANDLES;
    startup.hStdInput = GetStdHandle(STD_INPUT_HANDLE);
    startup.hStdOutput = GetStdHandle(STD_OUTPUT_HANDLE);
    startup.hStdError = GetStdHandle(STD_ERROR_HANDLE);
    PROCESS_INFORMATION child{};
    if (!CreateProcessW(cmake, &command[0], nullptr, nullptr, TRUE, 0,
                        nullptr, nullptr, &startup, &child)) {
        return EXIT_FAILURE;
    }
    CloseHandle(child.hThread);
    DWORD exitCode = EXIT_FAILURE;
    if (WaitForSingleObject(child.hProcess, INFINITE) == WAIT_OBJECT_0) {
        GetExitCodeProcess(child.hProcess, &exitCode);
    }
    CloseHandle(child.hProcess);
    return static_cast<int>(exitCode);
}
#else
#include <unistd.h>

int main(int argc, char** argv)
{
    char* cmake = std::getenv("VERIFIER_FIXTURE_CMAKE");
    if (!cmake || argc < 2) {
        return EXIT_FAILURE;
    }

    const std::string last = argv[argc - 1];
    std::string escaped;
    if (last == "--version" || last == "--help") {
        escaped = "fixture:" + last;
        argv[argc - 1] = &escaped[0];
    }
    argv[0] = cmake;
    execv(cmake, argv);
    return EXIT_FAILURE;
}
#endif
]=])
  execute_process(
    COMMAND "${CMAKE_COMMAND}" -S "${_launcher_source}" -B "${_launcher_source}/build"
      -DCMAKE_BUILD_TYPE=Release
    RESULT_VARIABLE _launcher_configure)
  if(NOT _launcher_configure STREQUAL "0")
    message(FATAL_ERROR "could not configure the CMake fixture launcher")
  endif()
  execute_process(
    COMMAND "${CMAKE_COMMAND}" --build "${_launcher_source}/build" --config Release
    RESULT_VARIABLE _launcher_build)
  if(NOT _launcher_build STREQUAL "0")
    message(FATAL_ERROR "could not build the CMake fixture launcher")
  endif()
  file(READ "${_launcher_source}/build/launcher-Release.txt" _fixture_executable)
  set(ENV{VERIFIER_FIXTURE_CMAKE} "${CMAKE_COMMAND}")
endif()

set(_common
  "-DVERIFIER_EXECUTABLE=${_fixture_executable}"
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
