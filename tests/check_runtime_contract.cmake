# SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary
if(NOT DEFINED ENTERPRISE_SOURCE_DIR OR NOT DEFINED ENTERPRISE_BINARY_ROOT)
  message(FATAL_ERROR "ENTERPRISE_SOURCE_DIR and ENTERPRISE_BINARY_ROOT are required")
endif()

file(REMOVE_RECURSE "${ENTERPRISE_BINARY_ROOT}")
file(MAKE_DIRECTORY "${ENTERPRISE_BINARY_ROOT}")

set(_fake_prefix "${ENTERPRISE_BINARY_ROOT}/fake-prefix")
file(MAKE_DIRECTORY "${_fake_prefix}/lib/cmake/AnoCryptoC")
file(WRITE "${_fake_prefix}/lib/cmake/AnoCryptoC/AnoCryptoCConfig.cmake"
  "if(NOT TARGET AnoCryptoC::AnoCryptoC)\n  add_library(AnoCryptoC::AnoCryptoC INTERFACE IMPORTED)\nendif()\n")
file(WRITE "${_fake_prefix}/lib/cmake/AnoCryptoC/AnoCryptoCConfigVersion.cmake"
  "set(PACKAGE_VERSION \"0.1.0\")\nset(PACKAGE_VERSION_COMPATIBLE TRUE)\nset(PACKAGE_VERSION_EXACT TRUE)\n")

set(_complete_capabilities "sha256;hmac-sha256;hkdf-sha256;random;scrypt;aes256-gcm;aes256-gcm-stream")

function(write_runtime_fixture name contract_version initialize_status runtime_status module_state self_test_status module_version build_identity)
  set(_source "${ENTERPRISE_BINARY_ROOT}/${name}-source")
  file(MAKE_DIRECTORY "${_source}")
  file(WRITE "${_source}/provider.cpp" "int enterprise_crypto_provider_fixture_symbol = 0;\n")
  file(WRITE "${_source}/runtime.cpp"
"#include \"anosecurekit_enterprise/detail/provider_runtime_contract.hpp\"\n"
"namespace anosecurekit_enterprise::detail {\n"
"namespace {\n"
"backend_runtime_status initialize() noexcept { return backend_runtime_status::${initialize_status}; }\n"
"void shutdown() noexcept {}\n"
"backend_runtime_info snapshot() noexcept {\n"
"  return {\"anocrypto-c\", \"${module_version}\", \"${build_identity}\", "
"backend_runtime_status::${runtime_status}, backend_module_state::${module_state}, "
"backend_self_test_status::${self_test_status}, 127};\n"
"}\n"
"constexpr provider_runtime_api api{${contract_version}, initialize, shutdown, snapshot};\n"
"}\n"
"const provider_runtime_api& selected_provider_runtime() noexcept { return api; }\n"
"}\n")
  file(WRITE "${_source}/CMakeLists.txt"
"cmake_minimum_required(VERSION 3.20)\n"
"project(${name} LANGUAGES CXX)\n"
"add_library(AnoCryptoC::AnoCryptoC INTERFACE IMPORTED)\n"
"add_library(test_provider OBJECT provider.cpp)\n"
"set_property(TARGET test_provider PROPERTY ANOSECUREKIT_ENTERPRISE_PROVIDER_BACKEND_ID \"anocrypto-c\")\n"
"set_property(TARGET test_provider PROPERTY ANOSECUREKIT_ENTERPRISE_PROVIDER_CAPABILITIES \"${_complete_capabilities}\")\n"
"target_link_libraries(test_provider PRIVATE AnoCryptoC::AnoCryptoC)\n"
"add_library(test_runtime OBJECT runtime.cpp)\n"
"set_property(TARGET test_runtime PROPERTY ANOSECUREKIT_ENTERPRISE_PROVIDER_BACKEND_ID \"anocrypto-c\")\n"
"set_property(TARGET test_runtime PROPERTY ANOSECUREKIT_ENTERPRISE_RUNTIME_CONTRACT_VERSION \"1\")\n"
"target_link_libraries(test_runtime PRIVATE AnoCryptoC::AnoCryptoC)\n"
"set(BUILD_TESTING OFF CACHE BOOL \"\" FORCE)\n"
"set(ANOSECUREKIT_ENTERPRISE_CRYPTO_BACKEND anocrypto-c CACHE STRING \"\" FORCE)\n"
"set(ANOSECUREKIT_ENTERPRISE_ANOCRYPTO_C_PROVIDER_TARGET test_provider CACHE STRING \"\" FORCE)\n"
"set(ANOSECUREKIT_ENTERPRISE_ANOCRYPTO_C_RUNTIME_TARGET test_runtime CACHE STRING \"\" FORCE)\n"
"set(AnoCryptoC_DIR \"${_fake_prefix}/lib/cmake/AnoCryptoC\" CACHE PATH \"\" FORCE)\n"
"add_subdirectory(\"${ENTERPRISE_SOURCE_DIR}\" enterprise)\n")
  set(${name}_SOURCE "${_source}" PARENT_SCOPE)
endfunction()

function(build_and_run_fixture name)
  set(_source_var "${name}_SOURCE")
  set(_source "${${_source_var}}")
  set(_build "${ENTERPRISE_BINARY_ROOT}/${name}-build")
  execute_process(
    COMMAND "${CMAKE_COMMAND}" -S "${_source}" -B "${_build}" -G "${ENTERPRISE_GENERATOR}"
    RESULT_VARIABLE _configure_result OUTPUT_VARIABLE _configure_out ERROR_VARIABLE _configure_err)
  if(NOT _configure_result EQUAL 0)
    string(CONCAT _log "${_configure_out}" "${_configure_err}")
    message(FATAL_ERROR "${name}: configuration failed\n${_log}")
  endif()
  execute_process(
    COMMAND "${CMAKE_COMMAND}" --build "${_build}" --config Release --target anosecurekit_enterprise_info --parallel 4
    RESULT_VARIABLE _build_result OUTPUT_VARIABLE _build_out ERROR_VARIABLE _build_err)
  if(NOT _build_result EQUAL 0)
    string(CONCAT _log "${_build_out}" "${_build_err}")
    message(FATAL_ERROR "${name}: build failed\n${_log}")
  endif()

  set(_candidates
    "${_build}/enterprise/anosecurekit_enterprise_info${CMAKE_EXECUTABLE_SUFFIX}"
    "${_build}/enterprise/Release/anosecurekit_enterprise_info${CMAKE_EXECUTABLE_SUFFIX}")
  set(_executable "")
  foreach(_candidate IN LISTS _candidates)
    if(EXISTS "${_candidate}")
      set(_executable "${_candidate}")
      break()
    endif()
  endforeach()
  if(_executable STREQUAL "")
    message(FATAL_ERROR "${name}: info executable not found")
  endif()
  execute_process(
    COMMAND "${_executable}"
    RESULT_VARIABLE _run_result OUTPUT_VARIABLE _run_out ERROR_VARIABLE _run_err)
  if(NOT _run_result EQUAL 0)
    string(CONCAT _log "${_run_out}" "${_run_err}")
    message(FATAL_ERROR "${name}: info executable failed\n${_log}")
  endif()
  set(${name}_OUTPUT "${_run_out}" PARENT_SCOPE)
endfunction()

function(require_output name text)
  set(_output_var "${name}_OUTPUT")
  set(_output "${${_output_var}}")
  string(FIND "${_output}" "${text}" _found)
  if(_found EQUAL -1)
    message(FATAL_ERROR "${name}: expected output not found: ${text}\n${_output}")
  endif()
endfunction()

write_runtime_fixture(ready 1 ready ready operational passed "mock-0.1.0" "mock-build-ready")
build_and_run_fixture(ready)
require_output(ready "Crypto backend profile: anocrypto-c")
require_output(ready "Initialization: ready")
require_output(ready "Profile ready: yes")
require_output(ready "Backend module version: mock-0.1.0")
require_output(ready "Runtime status: ready")
require_output(ready "Module state: operational")
require_output(ready "Self-test status: passed")

write_runtime_fixture(shutdown 1 not_operational not_operational shutdown passed "mock-0.1.0" "mock-build-shutdown")
build_and_run_fixture(shutdown)
require_output(shutdown "Profile ready: no")
require_output(shutdown "Runtime status: not-operational")
require_output(shutdown "Module state: shutdown")

set(_ready_install "${ENTERPRISE_BINARY_ROOT}/ready-install")
execute_process(
  COMMAND "${CMAKE_COMMAND}" --install "${ENTERPRISE_BINARY_ROOT}/ready-build/enterprise"
    --config Release --prefix "${_ready_install}"
  RESULT_VARIABLE _ready_install_result
  OUTPUT_VARIABLE _ready_install_out
  ERROR_VARIABLE _ready_install_err)
if(NOT _ready_install_result EQUAL 0)
  string(CONCAT _ready_install_log "${_ready_install_out}" "${_ready_install_err}")
  message(FATAL_ERROR "ready: incomplete AnoCrypto-C profile install command failed unexpectedly
${_ready_install_log}")
endif()
file(GLOB_RECURSE _ready_installed_files LIST_DIRECTORIES FALSE "${_ready_install}/*")
if(_ready_installed_files)
  list(JOIN _ready_installed_files "
" _ready_installed_files_text)
  message(FATAL_ERROR
    "ready: incomplete AnoCrypto-C profile must not produce installable customer files
${_ready_installed_files_text}")
endif()

execute_process(
  COMMAND "${CMAKE_COMMAND}" --build "${ENTERPRISE_BINARY_ROOT}/ready-build"
    --config Release --target enterprise-delivery-check --parallel 4
  RESULT_VARIABLE _ready_delivery_result
  OUTPUT_VARIABLE _ready_delivery_out
  ERROR_VARIABLE _ready_delivery_err)
if(_ready_delivery_result EQUAL 0)
  message(FATAL_ERROR
    "ready: incomplete AnoCrypto-C profile unexpectedly produced a customer-delivery package")
endif()

find_program(_enterprise_ldd_executable NAMES ldd)
if(_enterprise_ldd_executable)
  set(_ready_build "${ENTERPRISE_BINARY_ROOT}/ready-build")
  set(_ready_candidates
    "${_ready_build}/enterprise/anosecurekit_enterprise_info${CMAKE_EXECUTABLE_SUFFIX}"
    "${_ready_build}/enterprise/Release/anosecurekit_enterprise_info${CMAKE_EXECUTABLE_SUFFIX}")
  set(_ready_executable "")
  foreach(_candidate IN LISTS _ready_candidates)
    if(EXISTS "${_candidate}")
      set(_ready_executable "${_candidate}")
      break()
    endif()
  endforeach()
  execute_process(
    COMMAND "${_enterprise_ldd_executable}" "${_ready_executable}"
    RESULT_VARIABLE _ldd_result OUTPUT_VARIABLE _ldd_out ERROR_VARIABLE _ldd_err)
  if(NOT _ldd_result EQUAL 0)
    string(CONCAT _ldd_log "${_ldd_out}" "${_ldd_err}")
    message(FATAL_ERROR "ready: ldd inspection failed\n${_ldd_log}")
  endif()
  string(TOLOWER "${_ldd_out}" _ldd_lower)
  if(_ldd_lower MATCHES "libcrypto|libssl")
    message(FATAL_ERROR
      "ready: mock AnoCrypto-C profile unexpectedly links OpenSSL\n${_ldd_out}")
  endif()
endif()

write_runtime_fixture(self-test-failed 1 self_test_failed self_test_failed error failed "mock-0.1.0" "mock-build-failed")
build_and_run_fixture(self-test-failed)
require_output(self-test-failed "Initialization: self-test-failed")
require_output(self-test-failed "Profile ready: no")
require_output(self-test-failed "Runtime status: self-test-failed")
require_output(self-test-failed "Module state: error")
require_output(self-test-failed "Self-test status: failed")

write_runtime_fixture(bad-contract 2 ready ready operational passed "mock-0.1.0" "mock-build-bad-contract")
build_and_run_fixture(bad-contract)
require_output(bad-contract "Initialization: internal-error")
require_output(bad-contract "Profile ready: no")
require_output(bad-contract "Backend module: invalid-provider-contract")
require_output(bad-contract "Runtime status: internal-error")

message(STATUS "Enterprise runtime contract checks passed")
