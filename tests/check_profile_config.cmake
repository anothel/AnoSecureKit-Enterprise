# SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary
if(NOT DEFINED ENTERPRISE_SOURCE_DIR OR NOT DEFINED ENTERPRISE_BINARY_ROOT)
  message(FATAL_ERROR "ENTERPRISE_SOURCE_DIR and ENTERPRISE_BINARY_ROOT are required")
endif()
file(REMOVE_RECURSE "${ENTERPRISE_BINARY_ROOT}")
file(MAKE_DIRECTORY "${ENTERPRISE_BINARY_ROOT}")

set(_generator_args -G "${ENTERPRISE_GENERATOR}")
if(DEFINED ENTERPRISE_GENERATOR_PLATFORM AND NOT ENTERPRISE_GENERATOR_PLATFORM STREQUAL "")
  list(APPEND _generator_args -A "${ENTERPRISE_GENERATOR_PLATFORM}")
endif()
if(DEFINED ENTERPRISE_GENERATOR_TOOLSET AND NOT ENTERPRISE_GENERATOR_TOOLSET STREQUAL "")
  list(APPEND _generator_args -T "${ENTERPRISE_GENERATOR_TOOLSET}")
endif()

function(expect_configure_failure name expected)
  set(_build "${ENTERPRISE_BINARY_ROOT}/${name}")
  execute_process(
    COMMAND "${CMAKE_COMMAND}" -S "${ENTERPRISE_SOURCE_DIR}" -B "${_build}"
      ${_generator_args} ${ARGN}
    RESULT_VARIABLE _result OUTPUT_VARIABLE _out ERROR_VARIABLE _err)
  string(CONCAT _log "${_out}" "${_err}")
  if(_result EQUAL 0)
    message(FATAL_ERROR "${name}: configuration unexpectedly succeeded")
  endif()
  string(FIND "${_log}" "${expected}" _found)
  if(_found EQUAL -1)
    message(FATAL_ERROR "${name}: expected text not found: ${expected}\n${_log}")
  endif()
endfunction()

expect_configure_failure(invalid-profile "Unsupported ANOSECUREKIT_ENTERPRISE_CRYPTO_BACKEND"
  -DANOSECUREKIT_ENTERPRISE_CRYPTO_BACKEND=invalid)
expect_configure_failure(obsolete-option "ANOSECUREKIT_ENTERPRISE_ENABLE_ANOCRYPTO is obsolete"
  -DANOSECUREKIT_ENTERPRISE_ENABLE_ANOCRYPTO=ON)

set(_fake_prefix "${ENTERPRISE_BINARY_ROOT}/fake-prefix")
file(MAKE_DIRECTORY "${_fake_prefix}/lib/cmake/AnoCryptoC")
file(WRITE "${_fake_prefix}/lib/cmake/AnoCryptoC/AnoCryptoCConfig.cmake"
  "if(NOT TARGET AnoCryptoC::AnoCryptoC)\n  add_library(AnoCryptoC::AnoCryptoC INTERFACE IMPORTED)\nendif()\n")
file(WRITE "${_fake_prefix}/lib/cmake/AnoCryptoC/AnoCryptoCConfigVersion.cmake"
  "set(PACKAGE_VERSION \"0.1.0\")\nset(PACKAGE_VERSION_COMPATIBLE TRUE)\nset(PACKAGE_VERSION_EXACT TRUE)\n")
expect_configure_failure(native-missing-runtime-id
  "ANOSECUREKIT_ENTERPRISE_EXPECTED_ANOCRYPTO_C_RUNTIME_ID is required"
  -DANOSECUREKIT_ENTERPRISE_ENABLE_NATIVE_ANOCRYPTO_C_TESTS=ON
  -DANOSECUREKIT_ENTERPRISE_EXPECTED_ANOCRYPTO_C_COMMIT=test-commit
  -DCMAKE_PREFIX_PATH=${_fake_prefix})
expect_configure_failure(native-missing-commit
  "ANOSECUREKIT_ENTERPRISE_EXPECTED_ANOCRYPTO_C_COMMIT is required"
  -DANOSECUREKIT_ENTERPRISE_ENABLE_NATIVE_ANOCRYPTO_C_TESTS=ON
  -DANOSECUREKIT_ENTERPRISE_EXPECTED_ANOCRYPTO_C_RUNTIME_ID=test-runtime
  -DCMAKE_PREFIX_PATH=${_fake_prefix})
expect_configure_failure(missing-adapter "AnoCrypto-C profile is fail-closed"
  -DANOSECUREKIT_ENTERPRISE_CRYPTO_BACKEND=anocrypto-c
  -DCMAKE_PREFIX_PATH=${_fake_prefix})



function(write_provider_fixture name backend_id capabilities link_anocrypto include_runtime runtime_backend_id runtime_contract_version runtime_link_anocrypto)
  set(_fixture "${ENTERPRISE_BINARY_ROOT}/${name}-source")
  file(MAKE_DIRECTORY "${_fixture}")
  file(WRITE "${_fixture}/provider.cpp" "int enterprise_provider_fixture_symbol = 0;\n")
  file(WRITE "${_fixture}/runtime.cpp" "int enterprise_runtime_fixture_symbol = 0;\n")
  set(_link_line "")
  if(link_anocrypto)
    set(_link_line "target_link_libraries(test_provider PRIVATE AnoCryptoC::AnoCryptoC)\n")
  endif()
  set(_runtime_block "")
  if(include_runtime)
    set(_runtime_link_line "")
    if(runtime_link_anocrypto)
      set(_runtime_link_line "target_link_libraries(test_runtime PRIVATE AnoCryptoC::AnoCryptoC)\n")
    endif()
    string(CONCAT _runtime_block
      "add_library(test_runtime OBJECT runtime.cpp)\n"
      "set_property(TARGET test_runtime PROPERTY ANOSECUREKIT_ENTERPRISE_PROVIDER_BACKEND_ID \"${runtime_backend_id}\")\n"
      "set_property(TARGET test_runtime PROPERTY ANOSECUREKIT_ENTERPRISE_RUNTIME_CONTRACT_VERSION \"${runtime_contract_version}\")\n"
      "${_runtime_link_line}"
      "set(ANOSECUREKIT_ENTERPRISE_ANOCRYPTO_C_RUNTIME_TARGET test_runtime CACHE STRING \"\" FORCE)\n")
  else()
    set(_runtime_block
      "set(ANOSECUREKIT_ENTERPRISE_EXPECTED_ANOCRYPTO_C_RUNTIME_ID test-runtime CACHE STRING \"\" FORCE)\nset(ANOSECUREKIT_ENTERPRISE_EXPECTED_ANOCRYPTO_C_COMMIT test-commit CACHE STRING \"\" FORCE)\n")
  endif()
  file(WRITE "${_fixture}/CMakeLists.txt"
"cmake_minimum_required(VERSION 3.20)\n"
"project(${name} LANGUAGES CXX)\n"
"add_library(AnoCryptoC::AnoCryptoC INTERFACE IMPORTED)\n"
"add_library(test_provider OBJECT provider.cpp)\n"
"set_property(TARGET test_provider PROPERTY ANOSECUREKIT_ENTERPRISE_PROVIDER_BACKEND_ID \"${backend_id}\")\n"
"set_property(TARGET test_provider PROPERTY ANOSECUREKIT_ENTERPRISE_PROVIDER_CAPABILITIES \"${capabilities}\")\n"
"${_link_line}"
"${_runtime_block}"
"set(ANOSECUREKIT_ENTERPRISE_CRYPTO_BACKEND anocrypto-c CACHE STRING \"\" FORCE)\n"
"set(ANOSECUREKIT_ENTERPRISE_ANOCRYPTO_C_PROVIDER_TARGET test_provider CACHE STRING \"\" FORCE)\n"
"set(AnoCryptoC_DIR \"${_fake_prefix}/lib/cmake/AnoCryptoC\" CACHE PATH \"\" FORCE)\n"
"add_subdirectory(\"${ENTERPRISE_SOURCE_DIR}\" enterprise)\n")
  set(${name}_SOURCE "${_fixture}" PARENT_SCOPE)
endfunction()

function(expect_fixture_success name)
  set(_source_var "${name}_SOURCE")
  set(_source "${${_source_var}}")
  set(_build "${ENTERPRISE_BINARY_ROOT}/${name}-build")
  execute_process(
    COMMAND "${CMAKE_COMMAND}" -S "${_source}" -B "${_build}" ${_generator_args}
    RESULT_VARIABLE _result OUTPUT_VARIABLE _out ERROR_VARIABLE _err)
  if(NOT _result EQUAL 0)
    string(CONCAT _log "${_out}" "${_err}")
    message(FATAL_ERROR "${name}: configuration failed unexpectedly\n${_log}")
  endif()
endfunction()

function(expect_fixture_failure name expected)
  set(_source_var "${name}_SOURCE")
  set(_source "${${_source_var}}")
  set(_build "${ENTERPRISE_BINARY_ROOT}/${name}-build")
  execute_process(
    COMMAND "${CMAKE_COMMAND}" -S "${_source}" -B "${_build}" ${_generator_args}
    RESULT_VARIABLE _result OUTPUT_VARIABLE _out ERROR_VARIABLE _err)
  string(CONCAT _log "${_out}" "${_err}")
  if(_result EQUAL 0)
    message(FATAL_ERROR "${name}: configuration unexpectedly succeeded")
  endif()
  string(FIND "${_log}" "${expected}" _found)
  if(_found EQUAL -1)
    message(FATAL_ERROR "${name}: expected text not found: ${expected}\n${_log}")
  endif()
endfunction()

set(_complete_capabilities "sha256;hmac-sha256;hkdf-sha256;random;scrypt;aes256-gcm;aes256-gcm-stream")

write_provider_fixture(wrong-backend-id "openssl" "${_complete_capabilities}" TRUE TRUE "anocrypto-c" "1" TRUE)
expect_fixture_failure(wrong-backend-id "PROVIDER_BACKEND_ID to 'anocrypto-c'")

write_provider_fixture(missing-capabilities "anocrypto-c" "sha256;hmac-sha256;random" TRUE TRUE "anocrypto-c" "1" TRUE)
expect_fixture_failure(missing-capabilities "Missing required capabilities: hkdf-sha256")

write_provider_fixture(missing-module-link "anocrypto-c" "${_complete_capabilities}" FALSE TRUE "anocrypto-c" "1" TRUE)
expect_fixture_failure(missing-module-link "provider target must link AnoCryptoC::AnoCryptoC directly")

write_provider_fixture(built-in-runtime-target "anocrypto-c" "${_complete_capabilities}" TRUE FALSE "" "" FALSE)
expect_fixture_success(built-in-runtime-target)

write_provider_fixture(wrong-runtime-backend "anocrypto-c" "${_complete_capabilities}" TRUE TRUE "openssl" "1" TRUE)
expect_fixture_failure(wrong-runtime-backend "runtime target must set target property")

write_provider_fixture(wrong-runtime-version "anocrypto-c" "${_complete_capabilities}" TRUE TRUE "anocrypto-c" "2" TRUE)
expect_fixture_failure(wrong-runtime-version "RUNTIME_CONTRACT_VERSION=1")

write_provider_fixture(missing-runtime-module-link "anocrypto-c" "${_complete_capabilities}" TRUE TRUE "anocrypto-c" "1" FALSE)
expect_fixture_failure(missing-runtime-module-link "runtime target must link AnoCryptoC::AnoCryptoC directly")

write_provider_fixture(complete-contract "anocrypto-c" "${_complete_capabilities}" TRUE TRUE "anocrypto-c" "1" TRUE)
expect_fixture_success(complete-contract)

message(STATUS "Enterprise profile configuration checks passed")
