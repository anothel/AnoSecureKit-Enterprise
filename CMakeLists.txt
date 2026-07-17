# SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary
cmake_minimum_required(VERSION 3.20)

project(
  anosecurekit_enterprise
  VERSION 0.1.0
  DESCRIPTION "AnoSecureKit Enterprise"
  LANGUAGES CXX)

include(CTest)
include(CMakePackageConfigHelpers)
include(GNUInstallDirs)

set(ANOSECUREKIT_ENTERPRISE_TEST_PARALLEL_LEVEL "4" CACHE STRING
  "Parallel CTest jobs used by Enterprise check and release-preflight targets")
if(NOT ANOSECUREKIT_ENTERPRISE_TEST_PARALLEL_LEVEL MATCHES "^[1-9][0-9]*$")
  message(FATAL_ERROR
    "ANOSECUREKIT_ENTERPRISE_TEST_PARALLEL_LEVEL must be a positive integer")
endif()
option(ANOSECUREKIT_ENTERPRISE_WARNINGS_AS_ERRORS
  "Treat warnings in Enterprise-owned targets as errors" OFF)
option(
  ANOSECUREKIT_ENTERPRISE_ENABLE_NATIVE_ANOCRYPTO_C_TESTS
  "Build tests against an externally installed AnoCrypto-C package"
  OFF
)
set(ANOSECUREKIT_ENTERPRISE_EXPECTED_ANOCRYPTO_C_RUNTIME_ID "" CACHE STRING
  "Expected AnoCrypto-C runtime identity for native lifecycle integration")
set(ANOSECUREKIT_ENTERPRISE_EXPECTED_ANOCRYPTO_C_COMMIT "" CACHE STRING
  "Expected AnoCrypto-C commit for native lifecycle integration")
option(ANOSECUREKIT_ENTERPRISE_ALLOW_UNKNOWN_ANOCRYPTO_C_COMMIT_FOR_TESTS
  "Development-only: allow native lifecycle tests against a package reporting an unknown commit"
  OFF)

if(ANOSECUREKIT_ENTERPRISE_ENABLE_NATIVE_ANOCRYPTO_C_TESTS)
  if(NOT BUILD_TESTING)
    message(FATAL_ERROR
      "ANOSECUREKIT_ENTERPRISE_ENABLE_NATIVE_ANOCRYPTO_C_TESTS requires BUILD_TESTING=ON")
  endif()
  if(ANOSECUREKIT_ENTERPRISE_EXPECTED_ANOCRYPTO_C_RUNTIME_ID STREQUAL "")
    message(FATAL_ERROR
      "ANOSECUREKIT_ENTERPRISE_EXPECTED_ANOCRYPTO_C_RUNTIME_ID is required when native AnoCrypto-C tests are enabled")
  endif()
  if(ANOSECUREKIT_ENTERPRISE_EXPECTED_ANOCRYPTO_C_COMMIT STREQUAL "")
    message(FATAL_ERROR
      "ANOSECUREKIT_ENTERPRISE_EXPECTED_ANOCRYPTO_C_COMMIT is required when native AnoCrypto-C tests are enabled")
  endif()
  find_package(AnoCryptoC 0.1.0 EXACT CONFIG REQUIRED)
  if(NOT TARGET AnoCryptoC::AnoCryptoC)
    message(FATAL_ERROR
      "Native AnoCrypto-C tests require imported target AnoCryptoC::AnoCryptoC")
  endif()
endif()

function(_anosecurekit_enterprise_apply_warnings target_name)
  if(MSVC)
    target_compile_options(${target_name} PRIVATE /W4)
    if(ANOSECUREKIT_ENTERPRISE_WARNINGS_AS_ERRORS)
      target_compile_options(${target_name} PRIVATE /WX)
    endif()
  else()
    target_compile_options(${target_name} PRIVATE -Wall -Wextra -Wpedantic)
    if(ANOSECUREKIT_ENTERPRISE_WARNINGS_AS_ERRORS)
      target_compile_options(${target_name} PRIVATE -Werror)
    endif()
  endif()
endfunction()

set(ANOSECUREKIT_ENTERPRISE_COMMUNITY_VERSION "0.4.0")

option(ANOSECUREKIT_ENTERPRISE_USE_BUNDLED_COMMUNITY "Use bundled Community source" ON)
option(ANOSECUREKIT_ENTERPRISE_INSTALL_INFO "Install the Enterprise diagnostic executable" ON)
set(ANOSECUREKIT_ENTERPRISE_RELEASE_AUTHORIZATION_RECORD
  "${CMAKE_CURRENT_SOURCE_DIR}/release/customer-release-authorization.json"
  CACHE FILEPATH "External customer release authorization record; defaults to deny")
set(ANOSECUREKIT_ENTERPRISE_TRUSTED_RELEASE_EVIDENCE_RECORD
  "${CMAKE_CURRENT_SOURCE_DIR}/release/customer-release-evidence.json"
  CACHE FILEPATH "External trusted release evidence record; defaults to unavailable")
set(ANOSECUREKIT_ENTERPRISE_RELEASE_EVIDENCE_VERIFIER "" CACHE FILEPATH
  "Explicit GitHub CLI executable for release attestation verification")
set(ANOSECUREKIT_ENTERPRISE_INSTALLED_RELEASE_EVIDENCE_VERIFIER "" CACHE FILEPATH
  "GitHub CLI executable supplied by deployment metadata")
set(ANOSECUREKIT_ENTERPRISE_ATTESTATION_BUNDLE "" CACHE FILEPATH
  "Optional local GitHub attestation bundle for offline verification")
set(ANOSECUREKIT_ENTERPRISE_CRYPTO_BACKEND "openssl" CACHE STRING
  "Enterprise crypto profile: openssl or anocrypto-c")
set_property(CACHE ANOSECUREKIT_ENTERPRISE_CRYPTO_BACKEND PROPERTY STRINGS openssl anocrypto-c)
if(DEFINED ANOSECUREKIT_ENTERPRISE_ENABLE_ANOCRYPTO)
  message(FATAL_ERROR
    "ANOSECUREKIT_ENTERPRISE_ENABLE_ANOCRYPTO is obsolete. Use "
    "-DANOSECUREKIT_ENTERPRISE_CRYPTO_BACKEND=openssl or anocrypto-c.")
endif()
set(ANOSECUREKIT_ENTERPRISE_ANOCRYPTO_C_PROVIDER_TARGET "" CACHE STRING
  "Existing non-imported OBJECT_LIBRARY implementing the AnoSecureKit crypto provider contract for AnoCrypto-C")
set(ANOSECUREKIT_ENTERPRISE_ANOCRYPTO_C_RUNTIME_TARGET "" CACHE STRING
  "Optional test runtime OBJECT_LIBRARY override; empty uses the Enterprise AnoCrypto-C lifecycle adapter")
set(_anosecurekit_enterprise_required_capabilities
  sha256
  hmac-sha256
  hkdf-sha256
  random
  scrypt
  aes256-gcm
  aes256-gcm-stream)
set(_anosecurekit_enterprise_builtin_partial_provider FALSE)

if(NOT ANOSECUREKIT_ENTERPRISE_CRYPTO_BACKEND STREQUAL "openssl"
   AND NOT ANOSECUREKIT_ENTERPRISE_CRYPTO_BACKEND STREQUAL "anocrypto-c")
  message(FATAL_ERROR
    "Unsupported ANOSECUREKIT_ENTERPRISE_CRYPTO_BACKEND='${ANOSECUREKIT_ENTERPRISE_CRYPTO_BACKEND}'. "
    "Expected 'openssl' or 'anocrypto-c'.")
endif()

if(ANOSECUREKIT_ENTERPRISE_CRYPTO_BACKEND STREQUAL "anocrypto-c")
  if(NOT TARGET AnoCryptoC::AnoCryptoC)
    find_package(AnoCryptoC 0.1.0 EXACT CONFIG REQUIRED)
  endif()
  if(NOT TARGET AnoCryptoC::AnoCryptoC)
    message(FATAL_ERROR
      "AnoCrypto-C profile requires imported target AnoCryptoC::AnoCryptoC")
  endif()
  if(ANOSECUREKIT_ENTERPRISE_ANOCRYPTO_C_PROVIDER_TARGET STREQUAL "")
    if(NOT ANOSECUREKIT_ENTERPRISE_ENABLE_NATIVE_ANOCRYPTO_C_TESTS)
      message(FATAL_ERROR
        "AnoCrypto-C profile is fail-closed until a complete Enterprise provider adapter is supplied. "
        "Set ANOSECUREKIT_ENTERPRISE_ANOCRYPTO_C_PROVIDER_TARGET to an existing non-imported "
        "OBJECT_LIBRARY that implements the full AnoSecureKit provider contract.")
    endif()
    add_library(anosecurekit_enterprise_anocrypto_c_provider OBJECT
      src/providers/anocrypto_c/crypto_adapter.cpp
      src/providers/anocrypto_c/status_mapping.cpp)
    set_property(TARGET anosecurekit_enterprise_anocrypto_c_provider PROPERTY
      ANOSECUREKIT_ENTERPRISE_PROVIDER_BACKEND_ID "anocrypto-c")
    set_property(TARGET anosecurekit_enterprise_anocrypto_c_provider PROPERTY
      ANOSECUREKIT_ENTERPRISE_PROVIDER_CAPABILITIES "sha256;hmac-sha256;random")
    target_include_directories(anosecurekit_enterprise_anocrypto_c_provider PRIVATE
      "${CMAKE_CURRENT_SOURCE_DIR}/include"
      "${CMAKE_CURRENT_SOURCE_DIR}/src/providers/anocrypto_c"
      "${CMAKE_CURRENT_SOURCE_DIR}/third_party/anosecurekit-community/include"
      "${CMAKE_CURRENT_SOURCE_DIR}/third_party/anosecurekit-community/src")
    target_compile_features(anosecurekit_enterprise_anocrypto_c_provider PRIVATE cxx_std_20)
    target_link_libraries(anosecurekit_enterprise_anocrypto_c_provider PRIVATE
      AnoCryptoC::AnoCryptoC)
    _anosecurekit_enterprise_apply_warnings(anosecurekit_enterprise_anocrypto_c_provider)
    set(ANOSECUREKIT_ENTERPRISE_ANOCRYPTO_C_PROVIDER_TARGET
      anosecurekit_enterprise_anocrypto_c_provider)
    set(_anosecurekit_enterprise_builtin_partial_provider TRUE)
  endif()
  if(NOT TARGET "${ANOSECUREKIT_ENTERPRISE_ANOCRYPTO_C_PROVIDER_TARGET}")
    message(FATAL_ERROR
      "ANOSECUREKIT_ENTERPRISE_ANOCRYPTO_C_PROVIDER_TARGET does not name an existing target")
  endif()
  get_target_property(_enterprise_provider_imported
    "${ANOSECUREKIT_ENTERPRISE_ANOCRYPTO_C_PROVIDER_TARGET}" IMPORTED)
  get_target_property(_enterprise_provider_type
    "${ANOSECUREKIT_ENTERPRISE_ANOCRYPTO_C_PROVIDER_TARGET}" TYPE)
  if(_enterprise_provider_imported OR NOT _enterprise_provider_type STREQUAL "OBJECT_LIBRARY")
    message(FATAL_ERROR
      "AnoCrypto-C provider target must be a non-imported OBJECT_LIBRARY adapter, not AnoCryptoC::AnoCryptoC itself")
  endif()

  get_target_property(_enterprise_provider_backend_id
    "${ANOSECUREKIT_ENTERPRISE_ANOCRYPTO_C_PROVIDER_TARGET}"
    ANOSECUREKIT_ENTERPRISE_PROVIDER_BACKEND_ID)
  if(NOT _enterprise_provider_backend_id STREQUAL "anocrypto-c")
    message(FATAL_ERROR
      "AnoCrypto-C provider target must set target property "
      "ANOSECUREKIT_ENTERPRISE_PROVIDER_BACKEND_ID to 'anocrypto-c'")
  endif()

  get_target_property(_enterprise_provider_capabilities
    "${ANOSECUREKIT_ENTERPRISE_ANOCRYPTO_C_PROVIDER_TARGET}"
    ANOSECUREKIT_ENTERPRISE_PROVIDER_CAPABILITIES)
  if(NOT _enterprise_provider_capabilities
     OR _enterprise_provider_capabilities STREQUAL "_enterprise_provider_capabilities-NOTFOUND")
    message(FATAL_ERROR
      "AnoCrypto-C provider target must declare "
      "ANOSECUREKIT_ENTERPRISE_PROVIDER_CAPABILITIES")
  endif()

  set(_enterprise_missing_capabilities "")
  foreach(_required_capability IN LISTS _anosecurekit_enterprise_required_capabilities)
    if(NOT _required_capability IN_LIST _enterprise_provider_capabilities)
      list(APPEND _enterprise_missing_capabilities "${_required_capability}")
    endif()
  endforeach()
  if(_enterprise_missing_capabilities)
    list(JOIN _enterprise_missing_capabilities ", " _enterprise_missing_capabilities_text)
    if(_anosecurekit_enterprise_builtin_partial_provider)
      message(STATUS
        "AnoCrypto-C SHA-256/HMAC-SHA-256/random development provider enabled; full production profile remains blocked. "
        "Missing required capabilities: ${_enterprise_missing_capabilities_text}. "
        "No OpenSSL fallback is permitted.")
    else()
      message(FATAL_ERROR
        "AnoCrypto-C provider is incomplete for the Enterprise production profile. "
        "Missing required capabilities: ${_enterprise_missing_capabilities_text}. "
        "No OpenSSL fallback is permitted.")
    endif()
  endif()

  get_target_property(_enterprise_provider_link_libraries
    "${ANOSECUREKIT_ENTERPRISE_ANOCRYPTO_C_PROVIDER_TARGET}" LINK_LIBRARIES)
  if(NOT _enterprise_provider_link_libraries
     OR _enterprise_provider_link_libraries STREQUAL "_enterprise_provider_link_libraries-NOTFOUND")
    set(_enterprise_provider_link_libraries "")
  endif()
  if(NOT "AnoCryptoC::AnoCryptoC" IN_LIST _enterprise_provider_link_libraries)
    message(FATAL_ERROR
      "AnoCrypto-C provider target must link AnoCryptoC::AnoCryptoC directly")
  endif()

  if(ANOSECUREKIT_ENTERPRISE_ANOCRYPTO_C_RUNTIME_TARGET STREQUAL "")
    if(ANOSECUREKIT_ENTERPRISE_EXPECTED_ANOCRYPTO_C_RUNTIME_ID STREQUAL "")
      message(FATAL_ERROR
        "ANOSECUREKIT_ENTERPRISE_EXPECTED_ANOCRYPTO_C_RUNTIME_ID is required for the production AnoCrypto-C lifecycle adapter")
    endif()
    if(ANOSECUREKIT_ENTERPRISE_EXPECTED_ANOCRYPTO_C_COMMIT STREQUAL "")
      message(FATAL_ERROR
        "ANOSECUREKIT_ENTERPRISE_EXPECTED_ANOCRYPTO_C_COMMIT is required for the production AnoCrypto-C lifecycle adapter")
    endif()

    add_library(anosecurekit_enterprise_anocrypto_c_runtime OBJECT
      src/providers/anocrypto_c/runtime_adapter.cpp)
    set_property(TARGET anosecurekit_enterprise_anocrypto_c_runtime PROPERTY
      ANOSECUREKIT_ENTERPRISE_PROVIDER_BACKEND_ID "anocrypto-c")
    set_property(TARGET anosecurekit_enterprise_anocrypto_c_runtime PROPERTY
      ANOSECUREKIT_ENTERPRISE_RUNTIME_CONTRACT_VERSION "1")
    target_include_directories(anosecurekit_enterprise_anocrypto_c_runtime PRIVATE
      "${CMAKE_CURRENT_SOURCE_DIR}/include"
      "${CMAKE_CURRENT_SOURCE_DIR}/src/providers/anocrypto_c")
    target_compile_features(anosecurekit_enterprise_anocrypto_c_runtime PRIVATE cxx_std_20)
    target_compile_definitions(anosecurekit_enterprise_anocrypto_c_runtime PRIVATE
      ANOSECUREKIT_ENTERPRISE_EXPECTED_ANOCRYPTO_C_RUNTIME_ID_VALUE="${ANOSECUREKIT_ENTERPRISE_EXPECTED_ANOCRYPTO_C_RUNTIME_ID}"
      ANOSECUREKIT_ENTERPRISE_EXPECTED_ANOCRYPTO_C_COMMIT_VALUE="${ANOSECUREKIT_ENTERPRISE_EXPECTED_ANOCRYPTO_C_COMMIT}")
    if(ANOSECUREKIT_ENTERPRISE_ALLOW_UNKNOWN_ANOCRYPTO_C_COMMIT_FOR_TESTS)
      target_compile_definitions(anosecurekit_enterprise_anocrypto_c_runtime PRIVATE
        ANOSECUREKIT_ENTERPRISE_ALLOW_UNKNOWN_ANOCRYPTO_C_COMMIT_VALUE=1)
    endif()
    target_link_libraries(anosecurekit_enterprise_anocrypto_c_runtime PRIVATE
      AnoCryptoC::AnoCryptoC)
    if(BUILD_SHARED_LIBS)
      set_property(TARGET anosecurekit_enterprise_anocrypto_c_runtime PROPERTY
        POSITION_INDEPENDENT_CODE ON)
    endif()
    _anosecurekit_enterprise_apply_warnings(anosecurekit_enterprise_anocrypto_c_runtime)
    set(_anosecurekit_enterprise_anocrypto_c_runtime_target
      anosecurekit_enterprise_anocrypto_c_runtime)
  else()
    set(_anosecurekit_enterprise_anocrypto_c_runtime_target
      "${ANOSECUREKIT_ENTERPRISE_ANOCRYPTO_C_RUNTIME_TARGET}")
  endif()
  if(NOT TARGET "${_anosecurekit_enterprise_anocrypto_c_runtime_target}")
    message(FATAL_ERROR
      "ANOSECUREKIT_ENTERPRISE_ANOCRYPTO_C_RUNTIME_TARGET does not name an existing target")
  endif()
  get_target_property(_enterprise_runtime_imported
    "${_anosecurekit_enterprise_anocrypto_c_runtime_target}" IMPORTED)
  get_target_property(_enterprise_runtime_type
    "${_anosecurekit_enterprise_anocrypto_c_runtime_target}" TYPE)
  if(_enterprise_runtime_imported OR NOT _enterprise_runtime_type STREQUAL "OBJECT_LIBRARY")
    message(FATAL_ERROR
      "AnoCrypto-C runtime target must be a non-imported OBJECT_LIBRARY adapter")
  endif()
  get_target_property(_enterprise_runtime_backend_id
    "${_anosecurekit_enterprise_anocrypto_c_runtime_target}"
    ANOSECUREKIT_ENTERPRISE_PROVIDER_BACKEND_ID)
  if(NOT _enterprise_runtime_backend_id STREQUAL "anocrypto-c")
    message(FATAL_ERROR
      "AnoCrypto-C runtime target must set target property "
      "ANOSECUREKIT_ENTERPRISE_PROVIDER_BACKEND_ID to 'anocrypto-c'")
  endif()
  get_target_property(_enterprise_runtime_contract_version
    "${_anosecurekit_enterprise_anocrypto_c_runtime_target}"
    ANOSECUREKIT_ENTERPRISE_RUNTIME_CONTRACT_VERSION)
  if(NOT _enterprise_runtime_contract_version STREQUAL "1")
    message(FATAL_ERROR
      "AnoCrypto-C runtime target must declare "
      "ANOSECUREKIT_ENTERPRISE_RUNTIME_CONTRACT_VERSION=1")
  endif()
  get_target_property(_enterprise_runtime_link_libraries
    "${_anosecurekit_enterprise_anocrypto_c_runtime_target}" LINK_LIBRARIES)
  if(NOT _enterprise_runtime_link_libraries
     OR _enterprise_runtime_link_libraries STREQUAL "_enterprise_runtime_link_libraries-NOTFOUND")
    set(_enterprise_runtime_link_libraries "")
  endif()
  if(NOT "AnoCryptoC::AnoCryptoC" IN_LIST _enterprise_runtime_link_libraries)
    message(FATAL_ERROR
      "AnoCrypto-C runtime target must link AnoCryptoC::AnoCryptoC directly")
  endif()
endif()

if(ANOSECUREKIT_ENTERPRISE_USE_BUNDLED_COMMUNITY)
  set(ANOSECUREKIT_BUILD_TESTS OFF CACHE BOOL "" FORCE)
  set(ANOSECUREKIT_BUILD_CLI OFF CACHE BOOL "" FORCE)
  set(ANOSECUREKIT_INSTALL_CLI OFF CACHE BOOL "" FORCE)
  set(ANOSECUREKIT_BUILD_FUZZ OFF CACHE BOOL "" FORCE)
  if(ANOSECUREKIT_ENTERPRISE_CRYPTO_BACKEND STREQUAL "openssl")
    set(ANOSECUREKIT_CRYPTO_BACKEND openssl CACHE STRING "" FORCE)
    set(ANOSECUREKIT_EXTERNAL_BACKEND_TARGET "" CACHE STRING "" FORCE)
  else()
    set(ANOSECUREKIT_CRYPTO_BACKEND external CACHE STRING "" FORCE)
    set(ANOSECUREKIT_EXTERNAL_BACKEND_TARGET
      "${ANOSECUREKIT_ENTERPRISE_ANOCRYPTO_C_PROVIDER_TARGET}" CACHE STRING "" FORCE)
  endif()
  if(ANOSECUREKIT_ENTERPRISE_CRYPTO_BACKEND STREQUAL "openssl")
    # The OpenSSL delivery profile installs the verified Community package and
    # the Enterprise package together. The AnoCrypto-C build-tree profile remains
    # non-installable until its real adapter and full capability parity exist.
    add_subdirectory(third_party/anosecurekit-community)
  else()
    add_subdirectory(third_party/anosecurekit-community EXCLUDE_FROM_ALL)
  endif()
else()
  if(NOT ANOSECUREKIT_ENTERPRISE_CRYPTO_BACKEND STREQUAL "openssl")
    message(FATAL_ERROR
      "Non-bundled Community package mode currently supports only the openssl Enterprise profile. "
      "The AnoCrypto-C profile requires Community's build-tree external provider hook.")
  endif()
  find_package(anosecurekit 0.4 CONFIG REQUIRED)
endif()

add_library(anosecurekit_enterprise
  src/enterprise.cpp
  src/provider_runtime.cpp)
add_library(anosecurekit::enterprise ALIAS anosecurekit_enterprise)
set_target_properties(anosecurekit_enterprise PROPERTIES EXPORT_NAME enterprise)
if(WIN32 AND BUILD_SHARED_LIBS)
  set_property(TARGET anosecurekit_enterprise PROPERTY WINDOWS_EXPORT_ALL_SYMBOLS ON)
endif()
target_compile_features(anosecurekit_enterprise PUBLIC cxx_std_20)
target_include_directories(anosecurekit_enterprise
  PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>)
target_link_libraries(anosecurekit_enterprise PUBLIC anosecurekit::anosecurekit)
if(WIN32 AND BUILD_SHARED_LIBS)
  add_custom_command(TARGET anosecurekit_enterprise POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
      "$<TARGET_FILE:anosecurekit::anosecurekit>"
      "$<TARGET_FILE_DIR:anosecurekit_enterprise>")
endif()
_anosecurekit_enterprise_apply_warnings(anosecurekit_enterprise)

if(ANOSECUREKIT_ENTERPRISE_CRYPTO_BACKEND STREQUAL "openssl")
  target_sources(anosecurekit_enterprise PRIVATE src/provider_runtime_openssl.cpp)
  target_compile_definitions(anosecurekit_enterprise PUBLIC
    ANOSECUREKIT_ENTERPRISE_BACKEND_OPENSSL=1)
else()
  target_include_directories("${_anosecurekit_enterprise_anocrypto_c_runtime_target}"
    PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/include")
  target_compile_features("${_anosecurekit_enterprise_anocrypto_c_runtime_target}" PRIVATE cxx_std_20)
  target_sources(anosecurekit_enterprise PRIVATE
    $<TARGET_OBJECTS:${_anosecurekit_enterprise_anocrypto_c_runtime_target}>)
  target_compile_definitions(anosecurekit_enterprise PUBLIC
    ANOSECUREKIT_ENTERPRISE_BACKEND_ANOCRYPTO_C=1)
  target_link_libraries(anosecurekit_enterprise PRIVATE AnoCryptoC::AnoCryptoC)
endif()

add_executable(anosecurekit_enterprise_info examples/info/main.cpp)
target_link_libraries(anosecurekit_enterprise_info PRIVATE anosecurekit::enterprise)
target_compile_features(anosecurekit_enterprise_info PRIVATE cxx_std_20)
_anosecurekit_enterprise_apply_warnings(anosecurekit_enterprise_info)

find_package(Git QUIET)
set(_anosecurekit_enterprise_source_revision "not-recorded")
set(_anosecurekit_enterprise_community_tree "not-recorded")
if(Git_FOUND AND EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/.git")
  execute_process(
    COMMAND "${GIT_EXECUTABLE}" rev-parse HEAD
    WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
    RESULT_VARIABLE _enterprise_git_result
    OUTPUT_VARIABLE _enterprise_git_revision
    OUTPUT_STRIP_TRAILING_WHITESPACE
    ERROR_QUIET)
  if(_enterprise_git_result EQUAL 0 AND NOT _enterprise_git_revision STREQUAL "")
    set(_anosecurekit_enterprise_source_revision "${_enterprise_git_revision}")
  endif()
  execute_process(
    COMMAND "${GIT_EXECUTABLE}" rev-parse HEAD:third_party/anosecurekit-community
    WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
    RESULT_VARIABLE _enterprise_community_tree_result
    OUTPUT_VARIABLE _enterprise_community_tree
    OUTPUT_STRIP_TRAILING_WHITESPACE
    ERROR_QUIET)
  if(NOT _enterprise_community_tree_result EQUAL 0
     OR _enterprise_community_tree STREQUAL "")
    set(_enterprise_community_tree "not-recorded")
  endif()
  set(_anosecurekit_enterprise_community_tree "${_enterprise_community_tree}")
endif()

configure_file(
  packaging/DELIVERY_README.md.in
  ${CMAKE_CURRENT_BINARY_DIR}/DELIVERY_README.md
  @ONLY)

if(BUILD_TESTING)
  add_custom_target(enterprise-release-evidence-verifier-check
    COMMAND ${CMAKE_COMMAND}
      "-DVERIFIER_EXECUTABLE=${ANOSECUREKIT_ENTERPRISE_RELEASE_EVIDENCE_VERIFIER}"
      "-DINSTALLED_VERIFIER_EXECUTABLE=${ANOSECUREKIT_ENTERPRISE_INSTALLED_RELEASE_EVIDENCE_VERIFIER}"
      -DPROBE_ONLY=ON
      -DATTESTATION_GENERATION_STATUS=configured
      -P ${CMAKE_CURRENT_SOURCE_DIR}/cmake/check_release_evidence_verifier.cmake
    COMMAND ${CMAKE_COMMAND}
      -DENTERPRISE_SOURCE_DIR=${CMAKE_CURRENT_SOURCE_DIR}
      -DTEST_ROOT=${CMAKE_CURRENT_BINARY_DIR}/release-evidence-verifier-contract-check
      -P ${CMAKE_CURRENT_SOURCE_DIR}/tests/check_release_evidence_verifier_contract.cmake
    USES_TERMINAL)

  add_test(NAME enterprise.release-evidence-verifier
    COMMAND ${CMAKE_COMMAND}
      -DENTERPRISE_SOURCE_DIR=${CMAKE_CURRENT_SOURCE_DIR}
      -DTEST_ROOT=${CMAKE_CURRENT_BINARY_DIR}/release-evidence-verifier-contract-test
      -P ${CMAKE_CURRENT_SOURCE_DIR}/tests/check_release_evidence_verifier_contract.cmake)
  set_tests_properties(enterprise.release-evidence-verifier
    PROPERTIES LABELS "policy;release-evidence;cryptographic-adapter")

  add_custom_target(enterprise-trusted-release-evidence-check
    COMMAND ${CMAKE_COMMAND}
      -DENTERPRISE_SOURCE_DIR=${CMAKE_CURRENT_SOURCE_DIR}
      -DTEST_ROOT=${CMAKE_CURRENT_BINARY_DIR}/trusted-release-evidence-contract-check
      -DDEFAULT_EVIDENCE_RECORD=${CMAKE_CURRENT_SOURCE_DIR}/release/customer-release-evidence.json
      -P ${CMAKE_CURRENT_SOURCE_DIR}/tests/check_trusted_release_evidence_contract.cmake
    USES_TERMINAL)

  add_test(NAME enterprise.trusted-release-evidence
    COMMAND ${CMAKE_COMMAND}
      -DENTERPRISE_SOURCE_DIR=${CMAKE_CURRENT_SOURCE_DIR}
      -DTEST_ROOT=${CMAKE_CURRENT_BINARY_DIR}/trusted-release-evidence-contract-test
      -DDEFAULT_EVIDENCE_RECORD=${CMAKE_CURRENT_SOURCE_DIR}/release/customer-release-evidence.json
      -P ${CMAKE_CURRENT_SOURCE_DIR}/tests/check_trusted_release_evidence_contract.cmake)
  set_tests_properties(enterprise.trusted-release-evidence
    PROPERTIES LABELS "policy;release-evidence")

  add_custom_target(enterprise-release-authorization-contract-check
    COMMAND ${CMAKE_COMMAND}
      -DENTERPRISE_SOURCE_DIR=${CMAKE_CURRENT_SOURCE_DIR}
      -DTEST_ROOT=${CMAKE_CURRENT_BINARY_DIR}/release-authorization-contract-check
      -DDEFAULT_AUTHORIZATION_RECORD=${CMAKE_CURRENT_SOURCE_DIR}/release/customer-release-authorization.json
      -P ${CMAKE_CURRENT_SOURCE_DIR}/tests/check_release_authorization_contract.cmake
    USES_TERMINAL)

  add_custom_target(enterprise-profile-config-check
    COMMAND ${CMAKE_COMMAND}
      -DENTERPRISE_SOURCE_DIR=${CMAKE_CURRENT_SOURCE_DIR}
      -DENTERPRISE_BINARY_ROOT=${CMAKE_CURRENT_BINARY_DIR}/profile-config-check
      -DENTERPRISE_GENERATOR=${CMAKE_GENERATOR}
      -DENTERPRISE_GENERATOR_PLATFORM=${CMAKE_GENERATOR_PLATFORM}
      -DENTERPRISE_GENERATOR_TOOLSET=${CMAKE_GENERATOR_TOOLSET}
      -P ${CMAKE_CURRENT_SOURCE_DIR}/tests/check_profile_config.cmake
    USES_TERMINAL)

  add_custom_target(enterprise-runtime-contract-check
    COMMAND ${CMAKE_COMMAND}
      -DENTERPRISE_SOURCE_DIR=${CMAKE_CURRENT_SOURCE_DIR}
      -DENTERPRISE_BINARY_ROOT=${CMAKE_CURRENT_BINARY_DIR}/runtime-contract-check
      -DENTERPRISE_GENERATOR=${CMAKE_GENERATOR}
      -DENTERPRISE_GENERATOR_PLATFORM=${CMAKE_GENERATOR_PLATFORM}
      -DENTERPRISE_GENERATOR_TOOLSET=${CMAKE_GENERATOR_TOOLSET}
      -P ${CMAKE_CURRENT_SOURCE_DIR}/tests/check_runtime_contract.cmake
    USES_TERMINAL)

  add_custom_target(enterprise-ci-policy-check
    COMMAND ${CMAKE_COMMAND}
      -DENTERPRISE_SOURCE_DIR=${CMAKE_CURRENT_SOURCE_DIR}
      -P ${CMAKE_CURRENT_SOURCE_DIR}/cmake/check_ci_policy.cmake
    USES_TERMINAL)

  add_test(NAME enterprise.ci-policy
    COMMAND ${CMAKE_COMMAND}
      -DENTERPRISE_SOURCE_DIR=${CMAKE_CURRENT_SOURCE_DIR}
      -P ${CMAKE_CURRENT_SOURCE_DIR}/cmake/check_ci_policy.cmake)
  set_tests_properties(enterprise.ci-policy PROPERTIES LABELS "policy;ci")

  if(ANOSECUREKIT_ENTERPRISE_CRYPTO_BACKEND STREQUAL "openssl")
    add_custom_target(enterprise-openssl-boundary-check
      COMMAND ${CMAKE_COMMAND}
        -DENTERPRISE_SOURCE_DIR=${CMAKE_CURRENT_SOURCE_DIR}
        -P ${CMAKE_CURRENT_SOURCE_DIR}/tests/check_openssl_boundary.cmake
      USES_TERMINAL)
    add_custom_target(enterprise-openssl-profile-policy-check
      COMMAND ${CMAKE_COMMAND}
        -DENTERPRISE_SOURCE_DIR=${CMAKE_CURRENT_SOURCE_DIR}
        -DINFO_EXECUTABLE=$<TARGET_FILE:anosecurekit_enterprise_info>
        -P ${CMAKE_CURRENT_SOURCE_DIR}/tests/check_openssl_diagnostics.cmake
      DEPENDS
        anosecurekit_enterprise_info
        enterprise-openssl-boundary-check
      USES_TERMINAL)

    add_test(NAME enterprise.openssl-boundary
      COMMAND ${CMAKE_COMMAND}
        -DENTERPRISE_SOURCE_DIR=${CMAKE_CURRENT_SOURCE_DIR}
        -P ${CMAKE_CURRENT_SOURCE_DIR}/tests/check_openssl_boundary.cmake)
    add_test(NAME enterprise.openssl-diagnostics
      COMMAND ${CMAKE_COMMAND}
        -DENTERPRISE_SOURCE_DIR=${CMAKE_CURRENT_SOURCE_DIR}
        -DINFO_EXECUTABLE=$<TARGET_FILE:anosecurekit_enterprise_info>
        -P ${CMAKE_CURRENT_SOURCE_DIR}/tests/check_openssl_diagnostics.cmake)
    set_tests_properties(
      enterprise.openssl-boundary
      enterprise.openssl-diagnostics
      PROPERTIES LABELS "openssl;openssl-policy;policy")
  endif()

  add_executable(anosecurekit_enterprise_profile_test tests/profile_test.cpp)
  target_link_libraries(anosecurekit_enterprise_profile_test PRIVATE anosecurekit::enterprise)
  target_compile_features(anosecurekit_enterprise_profile_test PRIVATE cxx_std_20)
  _anosecurekit_enterprise_apply_warnings(anosecurekit_enterprise_profile_test)
  add_test(NAME enterprise.profile COMMAND anosecurekit_enterprise_profile_test)
  set_tests_properties(enterprise.profile PROPERTIES LABELS "profile;runtime")

  add_executable(anosecurekit_enterprise_sha256_test tests/sha256_test.cpp)
  target_link_libraries(anosecurekit_enterprise_sha256_test PRIVATE anosecurekit::enterprise)
  target_compile_features(anosecurekit_enterprise_sha256_test PRIVATE cxx_std_20)
  if(ANOSECUREKIT_ENTERPRISE_CRYPTO_BACKEND STREQUAL "anocrypto-c")
    target_include_directories(anosecurekit_enterprise_sha256_test PRIVATE
      "${CMAKE_CURRENT_SOURCE_DIR}/src/providers/anocrypto_c")
    target_link_libraries(anosecurekit_enterprise_sha256_test PRIVATE AnoCryptoC::AnoCryptoC)
  endif()
  _anosecurekit_enterprise_apply_warnings(anosecurekit_enterprise_sha256_test)
  add_test(NAME enterprise.sha256 COMMAND anosecurekit_enterprise_sha256_test)
  if(ANOSECUREKIT_ENTERPRISE_CRYPTO_BACKEND STREQUAL "anocrypto-c")
    set_tests_properties(enterprise.sha256 PROPERTIES LABELS "native-anocrypto-c;sha256")
  else()
    set_tests_properties(enterprise.sha256 PROPERTIES LABELS "openssl;sha256")
  endif()

  add_executable(anosecurekit_enterprise_hmac_sha256_test tests/hmac_sha256_test.cpp)
  target_link_libraries(anosecurekit_enterprise_hmac_sha256_test PRIVATE
    anosecurekit::enterprise)
  target_compile_features(anosecurekit_enterprise_hmac_sha256_test PRIVATE cxx_std_20)
  if(ANOSECUREKIT_ENTERPRISE_CRYPTO_BACKEND STREQUAL "anocrypto-c")
    target_include_directories(anosecurekit_enterprise_hmac_sha256_test PRIVATE
      "${CMAKE_CURRENT_SOURCE_DIR}/src/providers/anocrypto_c")
    target_link_libraries(anosecurekit_enterprise_hmac_sha256_test PRIVATE
      AnoCryptoC::AnoCryptoC)
  endif()
  _anosecurekit_enterprise_apply_warnings(anosecurekit_enterprise_hmac_sha256_test)
  add_test(NAME enterprise.hmac-sha256
    COMMAND anosecurekit_enterprise_hmac_sha256_test)
  if(ANOSECUREKIT_ENTERPRISE_CRYPTO_BACKEND STREQUAL "anocrypto-c")
    set_tests_properties(enterprise.hmac-sha256 PROPERTIES
      LABELS "native-anocrypto-c;hmac-sha256")
  else()
    set_tests_properties(enterprise.hmac-sha256 PROPERTIES LABELS "openssl;hmac-sha256")
  endif()

  add_executable(anosecurekit_enterprise_random_test tests/random_test.cpp)
  target_link_libraries(anosecurekit_enterprise_random_test PRIVATE
    anosecurekit::enterprise)
  target_compile_features(anosecurekit_enterprise_random_test PRIVATE cxx_std_20)
  if(ANOSECUREKIT_ENTERPRISE_CRYPTO_BACKEND STREQUAL "anocrypto-c")
    target_include_directories(anosecurekit_enterprise_random_test PRIVATE
      "${CMAKE_CURRENT_SOURCE_DIR}/src/providers/anocrypto_c")
    target_link_libraries(anosecurekit_enterprise_random_test PRIVATE
      AnoCryptoC::AnoCryptoC)
  endif()
  _anosecurekit_enterprise_apply_warnings(anosecurekit_enterprise_random_test)
  add_test(NAME enterprise.random COMMAND anosecurekit_enterprise_random_test)
  if(ANOSECUREKIT_ENTERPRISE_CRYPTO_BACKEND STREQUAL "anocrypto-c")
    set_tests_properties(enterprise.random PROPERTIES
      LABELS "native-anocrypto-c;random")
  else()
    set_tests_properties(enterprise.random PROPERTIES LABELS "openssl;random")
  endif()

  if(ANOSECUREKIT_ENTERPRISE_ENABLE_NATIVE_ANOCRYPTO_C_TESTS)
    add_executable(anosecurekit_enterprise_native_anocrypto_c_lifecycle_test
      tests/native_anocrypto_c/native_lifecycle_test.cpp
      src/providers/anocrypto_c/runtime_adapter.cpp
      src/enterprise.cpp
      src/provider_runtime.cpp)
    target_include_directories(anosecurekit_enterprise_native_anocrypto_c_lifecycle_test
      PRIVATE
        "${CMAKE_CURRENT_SOURCE_DIR}/include"
        "${CMAKE_CURRENT_SOURCE_DIR}/src/providers/anocrypto_c"
        "${CMAKE_CURRENT_SOURCE_DIR}/third_party/anosecurekit-community/include")
    target_compile_features(anosecurekit_enterprise_native_anocrypto_c_lifecycle_test
      PRIVATE cxx_std_20)
    target_compile_definitions(anosecurekit_enterprise_native_anocrypto_c_lifecycle_test
      PRIVATE
        ANOSECUREKIT_ENTERPRISE_BACKEND_ANOCRYPTO_C=1
        ANOSECUREKIT_ENTERPRISE_EXPECTED_ANOCRYPTO_C_RUNTIME_ID_VALUE="${ANOSECUREKIT_ENTERPRISE_EXPECTED_ANOCRYPTO_C_RUNTIME_ID}"
        ANOSECUREKIT_ENTERPRISE_EXPECTED_ANOCRYPTO_C_COMMIT_VALUE="${ANOSECUREKIT_ENTERPRISE_EXPECTED_ANOCRYPTO_C_COMMIT}")
    if(ANOSECUREKIT_ENTERPRISE_ALLOW_UNKNOWN_ANOCRYPTO_C_COMMIT_FOR_TESTS)
      target_compile_definitions(anosecurekit_enterprise_native_anocrypto_c_lifecycle_test
        PRIVATE ANOSECUREKIT_ENTERPRISE_ALLOW_UNKNOWN_ANOCRYPTO_C_COMMIT_VALUE=1)
    endif()
    target_link_libraries(anosecurekit_enterprise_native_anocrypto_c_lifecycle_test
      PRIVATE AnoCryptoC::AnoCryptoC)
    _anosecurekit_enterprise_apply_warnings(
      anosecurekit_enterprise_native_anocrypto_c_lifecycle_test)

    add_executable(anosecurekit_enterprise_native_anocrypto_c_status_mapping_test
      tests/native_anocrypto_c/status_mapping_test.cpp
      src/providers/anocrypto_c/status_mapping.cpp)
    target_include_directories(anosecurekit_enterprise_native_anocrypto_c_status_mapping_test
      PRIVATE
        "${CMAKE_CURRENT_SOURCE_DIR}/include"
        "${CMAKE_CURRENT_SOURCE_DIR}/src/providers/anocrypto_c"
        "$<TARGET_PROPERTY:AnoCryptoC::AnoCryptoC,INTERFACE_INCLUDE_DIRECTORIES>")
    target_compile_features(anosecurekit_enterprise_native_anocrypto_c_status_mapping_test
      PRIVATE cxx_std_20)
    target_link_libraries(anosecurekit_enterprise_native_anocrypto_c_status_mapping_test
      PRIVATE anosecurekit::enterprise)
    _anosecurekit_enterprise_apply_warnings(
      anosecurekit_enterprise_native_anocrypto_c_status_mapping_test)

    add_test(NAME enterprise.native-anocrypto-c-lifecycle
      COMMAND anosecurekit_enterprise_native_anocrypto_c_lifecycle_test)
    set_tests_properties(enterprise.native-anocrypto-c-lifecycle PROPERTIES
      LABELS "native-anocrypto-c;lifecycle")

    add_test(NAME enterprise.native-anocrypto-c-status-mapping
      COMMAND anosecurekit_enterprise_native_anocrypto_c_status_mapping_test)
    set_tests_properties(enterprise.native-anocrypto-c-status-mapping PROPERTIES
      LABELS "native-anocrypto-c;status")

    set(_anosecurekit_enterprise_native_sha256_dependency_arg "")
    set(_anosecurekit_enterprise_native_hmac_sha256_dependency_arg "")
    set(_anosecurekit_enterprise_native_random_dependency_arg "")
    set(_anosecurekit_enterprise_native_unsupported_dependency_arg "")
    if(ANOSECUREKIT_ENTERPRISE_CRYPTO_BACKEND STREQUAL "anocrypto-c")
      set(_anosecurekit_enterprise_native_sha256_dependency_arg
        -DNATIVE_SHA256_EXECUTABLE=$<TARGET_FILE:anosecurekit_enterprise_sha256_test>)
      set(_anosecurekit_enterprise_native_hmac_sha256_dependency_arg
        -DNATIVE_HMAC_SHA256_EXECUTABLE=$<TARGET_FILE:anosecurekit_enterprise_hmac_sha256_test>)
      set(_anosecurekit_enterprise_native_random_dependency_arg
        -DNATIVE_RANDOM_EXECUTABLE=$<TARGET_FILE:anosecurekit_enterprise_random_test>)
      set(_anosecurekit_enterprise_native_unsupported_dependency_arg
        -DNATIVE_UNSUPPORTED_EXECUTABLE=$<TARGET_FILE:anosecurekit_enterprise_anocrypto_c_partial_profile_test>)
    endif()
    add_test(NAME enterprise.native-anocrypto-c-dependencies
      COMMAND ${CMAKE_COMMAND}
        -DNATIVE_TEST_EXECUTABLE=$<TARGET_FILE:anosecurekit_enterprise_native_anocrypto_c_lifecycle_test>
        -DANOCRYPTO_C_LIBRARY=$<TARGET_FILE:AnoCryptoC::AnoCryptoC>
        ${_anosecurekit_enterprise_native_sha256_dependency_arg}
        ${_anosecurekit_enterprise_native_hmac_sha256_dependency_arg}
        ${_anosecurekit_enterprise_native_random_dependency_arg}
        ${_anosecurekit_enterprise_native_unsupported_dependency_arg}
        -P ${CMAKE_CURRENT_SOURCE_DIR}/tests/native_anocrypto_c/check_dependencies.cmake)
    set_tests_properties(enterprise.native-anocrypto-c-dependencies PROPERTIES
      LABELS "native-anocrypto-c;dependency")

    add_custom_target(enterprise-native-anocrypto-c-lifecycle-check
      COMMAND $<TARGET_FILE:anosecurekit_enterprise_native_anocrypto_c_lifecycle_test>
      COMMAND ${CMAKE_COMMAND}
        -DNATIVE_TEST_EXECUTABLE=$<TARGET_FILE:anosecurekit_enterprise_native_anocrypto_c_lifecycle_test>
        -DANOCRYPTO_C_LIBRARY=$<TARGET_FILE:AnoCryptoC::AnoCryptoC>
        -P ${CMAKE_CURRENT_SOURCE_DIR}/tests/native_anocrypto_c/check_dependencies.cmake
      DEPENDS anosecurekit_enterprise_native_anocrypto_c_lifecycle_test
      USES_TERMINAL)

    add_custom_target(enterprise-native-anocrypto-c-status-mapping-check
      COMMAND $<TARGET_FILE:anosecurekit_enterprise_native_anocrypto_c_status_mapping_test>
      DEPENDS anosecurekit_enterprise_native_anocrypto_c_status_mapping_test
      USES_TERMINAL)

    if(ANOSECUREKIT_ENTERPRISE_CRYPTO_BACKEND STREQUAL "anocrypto-c")
      add_executable(anosecurekit_enterprise_anocrypto_c_partial_profile_test
        tests/native_anocrypto_c/partial_profile_test.cpp)
      target_link_libraries(anosecurekit_enterprise_anocrypto_c_partial_profile_test
        PRIVATE anosecurekit::enterprise)
      target_compile_features(anosecurekit_enterprise_anocrypto_c_partial_profile_test
        PRIVATE cxx_std_20)
      _anosecurekit_enterprise_apply_warnings(
        anosecurekit_enterprise_anocrypto_c_partial_profile_test)

      add_test(NAME enterprise.native-anocrypto-c-partial-profile
        COMMAND anosecurekit_enterprise_anocrypto_c_partial_profile_test
          ${CMAKE_CURRENT_BINARY_DIR})
      set_tests_properties(enterprise.native-anocrypto-c-partial-profile PROPERTIES
        LABELS "native-anocrypto-c;profile-boundary;unsupported-services")

      add_test(NAME enterprise.native-anocrypto-c-source-and-package-boundary
        COMMAND ${CMAKE_COMMAND}
          -DENTERPRISE_SOURCE_DIR=${CMAKE_CURRENT_SOURCE_DIR}
          -DENTERPRISE_BINARY_DIR=${CMAKE_CURRENT_BINARY_DIR}
          -P ${CMAKE_CURRENT_SOURCE_DIR}/tests/native_anocrypto_c/check_partial_profile_boundary.cmake)
      set_tests_properties(
        enterprise.native-anocrypto-c-source-and-package-boundary PROPERTIES
        LABELS "native-anocrypto-c;dependency;package-boundary")

      add_custom_target(enterprise-native-anocrypto-c-sha256-check
        COMMAND $<TARGET_FILE:anosecurekit_enterprise_sha256_test>
        COMMAND ${CMAKE_COMMAND}
          -DNATIVE_TEST_EXECUTABLE=$<TARGET_FILE:anosecurekit_enterprise_native_anocrypto_c_lifecycle_test>
          -DNATIVE_SHA256_EXECUTABLE=$<TARGET_FILE:anosecurekit_enterprise_sha256_test>
          -DANOCRYPTO_C_LIBRARY=$<TARGET_FILE:AnoCryptoC::AnoCryptoC>
          -P ${CMAKE_CURRENT_SOURCE_DIR}/tests/native_anocrypto_c/check_dependencies.cmake
        DEPENDS
          anosecurekit_enterprise_sha256_test
          anosecurekit_enterprise_native_anocrypto_c_lifecycle_test
        USES_TERMINAL)

      add_custom_target(enterprise-native-anocrypto-c-hmac-sha256-check
        COMMAND $<TARGET_FILE:anosecurekit_enterprise_hmac_sha256_test>
        COMMAND ${CMAKE_COMMAND}
          -DNATIVE_TEST_EXECUTABLE=$<TARGET_FILE:anosecurekit_enterprise_native_anocrypto_c_lifecycle_test>
          -DNATIVE_HMAC_SHA256_EXECUTABLE=$<TARGET_FILE:anosecurekit_enterprise_hmac_sha256_test>
          -DANOCRYPTO_C_LIBRARY=$<TARGET_FILE:AnoCryptoC::AnoCryptoC>
          -P ${CMAKE_CURRENT_SOURCE_DIR}/tests/native_anocrypto_c/check_dependencies.cmake
        DEPENDS
          anosecurekit_enterprise_hmac_sha256_test
          anosecurekit_enterprise_native_anocrypto_c_lifecycle_test
        USES_TERMINAL)

      add_custom_target(enterprise-native-anocrypto-c-random-check
        COMMAND $<TARGET_FILE:anosecurekit_enterprise_random_test>
        COMMAND ${CMAKE_COMMAND}
          -DNATIVE_TEST_EXECUTABLE=$<TARGET_FILE:anosecurekit_enterprise_native_anocrypto_c_lifecycle_test>
          -DNATIVE_RANDOM_EXECUTABLE=$<TARGET_FILE:anosecurekit_enterprise_random_test>
          -DANOCRYPTO_C_LIBRARY=$<TARGET_FILE:AnoCryptoC::AnoCryptoC>
          -P ${CMAKE_CURRENT_SOURCE_DIR}/tests/native_anocrypto_c/check_dependencies.cmake
        DEPENDS
          anosecurekit_enterprise_random_test
          anosecurekit_enterprise_native_anocrypto_c_lifecycle_test
        USES_TERMINAL)

      add_custom_target(enterprise-anocrypto-c-partial-profile-check
        COMMAND ${CMAKE_CTEST_COMMAND}
          --test-dir ${CMAKE_CURRENT_BINARY_DIR}
          --build-config $<CONFIG>
          --output-on-failure
          --label-regex native-anocrypto-c
        DEPENDS
          anosecurekit_enterprise_profile_test
          anosecurekit_enterprise_sha256_test
          anosecurekit_enterprise_hmac_sha256_test
          anosecurekit_enterprise_random_test
          anosecurekit_enterprise_native_anocrypto_c_lifecycle_test
          anosecurekit_enterprise_native_anocrypto_c_status_mapping_test
          anosecurekit_enterprise_anocrypto_c_partial_profile_test
        USES_TERMINAL)
    endif()
  endif()
endif()

if(ANOSECUREKIT_ENTERPRISE_CRYPTO_BACKEND STREQUAL "openssl")
  set(_anosecurekit_enterprise_cmake_install_dir
    "${CMAKE_INSTALL_LIBDIR}/cmake/anosecurekitEnterprise")

  install(TARGETS anosecurekit_enterprise
    EXPORT anosecurekitEnterpriseTargets
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR})
  install(FILES
    include/anosecurekit_enterprise/enterprise.hpp
    include/anosecurekit_enterprise/provider_runtime.hpp
    DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/anosecurekit_enterprise)
  install(FILES
    LICENSE
    THIRD_PARTY_NOTICES.md
    README.md
    docs/BACKEND_PROFILES.md
    docs/CI_AND_RELEASE_GATE.md
    docs/COMMUNITY_DEPENDENCY.md
    docs/DEFERRED_CI_STATUS.md
    docs/INSTALLATION.md
    docs/OPENSSL_PROFILE_SUPPORT_POLICY.md
    docs/PRODUCT_BOUNDARY.md
    docs/PROVIDER_CAPABILITY_CONTRACT.md
    docs/PROVIDER_RUNTIME_CONTRACT.md
    docs/DELIVERY_VERIFICATION.md
    docs/RELEASE_AUTHORIZATION_POLICY.md
    docs/RELEASE_EVIDENCE_VERIFIER_POLICY.md
    docs/SUPPORTED_CONFIGURATION_MATRIX.md
    docs/TRUSTED_RELEASE_EVIDENCE_POLICY.md
    DESTINATION ${CMAKE_INSTALL_DATADIR}/anosecurekit-enterprise)
  install(FILES
    release/customer-release-evidence.json
    DESTINATION ${CMAKE_INSTALL_DATADIR}/anosecurekit-enterprise)

  if(ANOSECUREKIT_ENTERPRISE_INSTALL_INFO)
    install(TARGETS anosecurekit_enterprise_info
      RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})
  endif()

  install(EXPORT anosecurekitEnterpriseTargets
    FILE anosecurekitEnterpriseTargets.cmake
    NAMESPACE anosecurekit::
    DESTINATION ${_anosecurekit_enterprise_cmake_install_dir})

  configure_package_config_file(
    cmake/anosecurekitEnterpriseConfig.cmake.in
    ${CMAKE_CURRENT_BINARY_DIR}/anosecurekitEnterpriseConfig.cmake
    INSTALL_DESTINATION ${_anosecurekit_enterprise_cmake_install_dir})
  write_basic_package_version_file(
    ${CMAKE_CURRENT_BINARY_DIR}/anosecurekitEnterpriseConfigVersion.cmake
    VERSION ${PROJECT_VERSION}
    COMPATIBILITY SameMajorVersion)
  install(FILES
    ${CMAKE_CURRENT_BINARY_DIR}/anosecurekitEnterpriseConfig.cmake
    ${CMAKE_CURRENT_BINARY_DIR}/anosecurekitEnterpriseConfigVersion.cmake
    cmake/check_release_evidence_verifier.cmake
    DESTINATION ${_anosecurekit_enterprise_cmake_install_dir})
else()
  message(STATUS
    "AnoSecureKit Enterprise installation/export is disabled for the incomplete "
    "AnoCrypto-C profile. No customer package may be produced until the real "
    "adapter satisfies full capability and release gates.")
endif()

if(BUILD_TESTING)
  if(ANOSECUREKIT_ENTERPRISE_CRYPTO_BACKEND STREQUAL "openssl"
     AND ANOSECUREKIT_ENTERPRISE_USE_BUNDLED_COMMUNITY)
    add_custom_target(enterprise-package-check
      COMMAND ${CMAKE_COMMAND}
        -DENTERPRISE_SOURCE_DIR=${CMAKE_CURRENT_SOURCE_DIR}
        -DENTERPRISE_BUILD_DIR=${CMAKE_CURRENT_BINARY_DIR}
        -DENTERPRISE_PACKAGE_CHECK_ROOT=${CMAKE_CURRENT_BINARY_DIR}/enterprise-package-check
        -DENTERPRISE_BUILD_CONFIG=$<CONFIG>
        -DENTERPRISE_DEFAULT_BUILD_TYPE=${CMAKE_BUILD_TYPE}
        -DENTERPRISE_GENERATOR=${CMAKE_GENERATOR}
        -DENTERPRISE_GENERATOR_PLATFORM=${CMAKE_GENERATOR_PLATFORM}
        -DENTERPRISE_GENERATOR_TOOLSET=${CMAKE_GENERATOR_TOOLSET}
        -DENTERPRISE_CMAKE_MAKE_PROGRAM=${CMAKE_MAKE_PROGRAM}
        -DENTERPRISE_CXX_COMPILER=${CMAKE_CXX_COMPILER}
        "-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}"
        "-DVCPKG_TARGET_TRIPLET=${VCPKG_TARGET_TRIPLET}"
        "-DOPENSSL_ROOT_DIR=${OPENSSL_ROOT_DIR}"
        "-DENTERPRISE_OPENSSL_RUNTIME_DIR=${ANOSECUREKIT_OPENSSL_RUNTIME_DIR}"
        -P ${CMAKE_CURRENT_SOURCE_DIR}/tests/package/check_installed_consumer.cmake
      DEPENDS anosecurekit_enterprise anosecurekit_enterprise_info
      USES_TERMINAL)
    add_test(NAME enterprise.installed-consumer
      COMMAND ${CMAKE_COMMAND}
        -DENTERPRISE_SOURCE_DIR=${CMAKE_CURRENT_SOURCE_DIR}
        -DENTERPRISE_BUILD_DIR=${CMAKE_CURRENT_BINARY_DIR}
        -DENTERPRISE_PACKAGE_CHECK_ROOT=${CMAKE_CURRENT_BINARY_DIR}/enterprise-installed-consumer-test
        -DENTERPRISE_BUILD_CONFIG=$<CONFIG>
        -DENTERPRISE_DEFAULT_BUILD_TYPE=${CMAKE_BUILD_TYPE}
        -DENTERPRISE_GENERATOR=${CMAKE_GENERATOR}
        -DENTERPRISE_GENERATOR_PLATFORM=${CMAKE_GENERATOR_PLATFORM}
        -DENTERPRISE_GENERATOR_TOOLSET=${CMAKE_GENERATOR_TOOLSET}
        -DENTERPRISE_CMAKE_MAKE_PROGRAM=${CMAKE_MAKE_PROGRAM}
        -DENTERPRISE_CXX_COMPILER=${CMAKE_CXX_COMPILER}
        "-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}"
        "-DVCPKG_TARGET_TRIPLET=${VCPKG_TARGET_TRIPLET}"
        "-DOPENSSL_ROOT_DIR=${OPENSSL_ROOT_DIR}"
        "-DENTERPRISE_OPENSSL_RUNTIME_DIR=${ANOSECUREKIT_OPENSSL_RUNTIME_DIR}"
        -P ${CMAKE_CURRENT_SOURCE_DIR}/tests/package/check_installed_consumer.cmake)
    set_tests_properties(enterprise.installed-consumer PROPERTIES LABELS "package;consumer")

    add_custom_target(enterprise-delivery-check
      COMMAND ${CMAKE_COMMAND}
        -DENTERPRISE_SOURCE_DIR=${CMAKE_CURRENT_SOURCE_DIR}
        -DENTERPRISE_BUILD_DIR=${CMAKE_CURRENT_BINARY_DIR}
        -DENTERPRISE_DELIVERY_ROOT=${CMAKE_CURRENT_BINARY_DIR}/enterprise-delivery-check
        -DENTERPRISE_BUILD_CONFIG=$<CONFIG>
        -DENTERPRISE_DEFAULT_BUILD_TYPE=${CMAKE_BUILD_TYPE}
        -DENTERPRISE_GENERATOR=${CMAKE_GENERATOR}
        -DENTERPRISE_GENERATOR_PLATFORM=${CMAKE_GENERATOR_PLATFORM}
        -DENTERPRISE_GENERATOR_TOOLSET=${CMAKE_GENERATOR_TOOLSET}
        -DENTERPRISE_CMAKE_MAKE_PROGRAM=${CMAKE_MAKE_PROGRAM}
        -DENTERPRISE_CXX_COMPILER=${CMAKE_CXX_COMPILER}
        -DENTERPRISE_COMPILER_ID=${CMAKE_CXX_COMPILER_ID}
        -DENTERPRISE_COMPILER_VERSION=${CMAKE_CXX_COMPILER_VERSION}
        -DENTERPRISE_SYSTEM_NAME=${CMAKE_SYSTEM_NAME}
        -DENTERPRISE_SYSTEM_PROCESSOR=${CMAKE_SYSTEM_PROCESSOR}
        -DENTERPRISE_PROJECT_VERSION=${PROJECT_VERSION}
        -DENTERPRISE_COMMUNITY_VERSION=${ANOSECUREKIT_ENTERPRISE_COMMUNITY_VERSION}
        -DENTERPRISE_SOURCE_REVISION=${_anosecurekit_enterprise_source_revision}
        -DENTERPRISE_CPACK_COMMAND=${CMAKE_CPACK_COMMAND}
        -P ${CMAKE_CURRENT_SOURCE_DIR}/tests/package/check_delivery_package.cmake
      DEPENDS anosecurekit_enterprise anosecurekit_enterprise_info
      USES_TERMINAL)
    add_test(NAME enterprise.delivery-package
      COMMAND ${CMAKE_COMMAND}
        -DENTERPRISE_SOURCE_DIR=${CMAKE_CURRENT_SOURCE_DIR}
        -DENTERPRISE_BUILD_DIR=${CMAKE_CURRENT_BINARY_DIR}
        -DENTERPRISE_DELIVERY_ROOT=${CMAKE_CURRENT_BINARY_DIR}/enterprise-delivery-test
        -DENTERPRISE_BUILD_CONFIG=$<CONFIG>
        -DENTERPRISE_DEFAULT_BUILD_TYPE=${CMAKE_BUILD_TYPE}
        -DENTERPRISE_GENERATOR=${CMAKE_GENERATOR}
        -DENTERPRISE_GENERATOR_PLATFORM=${CMAKE_GENERATOR_PLATFORM}
        -DENTERPRISE_GENERATOR_TOOLSET=${CMAKE_GENERATOR_TOOLSET}
        -DENTERPRISE_CMAKE_MAKE_PROGRAM=${CMAKE_MAKE_PROGRAM}
        -DENTERPRISE_CXX_COMPILER=${CMAKE_CXX_COMPILER}
        -DENTERPRISE_COMPILER_ID=${CMAKE_CXX_COMPILER_ID}
        -DENTERPRISE_COMPILER_VERSION=${CMAKE_CXX_COMPILER_VERSION}
        -DENTERPRISE_SYSTEM_NAME=${CMAKE_SYSTEM_NAME}
        -DENTERPRISE_SYSTEM_PROCESSOR=${CMAKE_SYSTEM_PROCESSOR}
        -DENTERPRISE_PROJECT_VERSION=${PROJECT_VERSION}
        -DENTERPRISE_COMMUNITY_VERSION=${ANOSECUREKIT_ENTERPRISE_COMMUNITY_VERSION}
        -DENTERPRISE_SOURCE_REVISION=${_anosecurekit_enterprise_source_revision}
        -DENTERPRISE_CPACK_COMMAND=${CMAKE_CPACK_COMMAND}
        -P ${CMAKE_CURRENT_SOURCE_DIR}/tests/package/check_delivery_package.cmake)
    set_tests_properties(enterprise.delivery-package PROPERTIES LABELS "package;delivery")
  else()
    add_custom_target(enterprise-package-check
      COMMAND ${CMAKE_COMMAND} -E echo
        "enterprise-package-check requires the bundled Community OpenSSL delivery profile"
      COMMAND ${CMAKE_COMMAND} -E false
      USES_TERMINAL)

    add_custom_target(enterprise-delivery-check
      COMMAND ${CMAKE_COMMAND} -E echo
        "enterprise-delivery-check requires the bundled Community OpenSSL delivery profile"
      COMMAND ${CMAKE_COMMAND} -E false
      USES_TERMINAL)
  endif()
endif()
if(BUILD_TESTING)
  if(ANOSECUREKIT_ENTERPRISE_CRYPTO_BACKEND STREQUAL "openssl"
     AND ANOSECUREKIT_ENTERPRISE_USE_BUNDLED_COMMUNITY)
    add_custom_target(enterprise-release-authorization-check
      COMMAND ${CMAKE_COMMAND}
        -DENTERPRISE_SOURCE_DIR=${CMAKE_CURRENT_SOURCE_DIR}
        -DENTERPRISE_DELIVERY_ROOT=${CMAKE_CURRENT_BINARY_DIR}/enterprise-delivery-check
        -DAUTHORIZATION_RECORD=${ANOSECUREKIT_ENTERPRISE_RELEASE_AUTHORIZATION_RECORD}
        -DEVIDENCE_RECORD=${ANOSECUREKIT_ENTERPRISE_TRUSTED_RELEASE_EVIDENCE_RECORD}
        -DEXPECTED_ENTERPRISE_VERSION=${PROJECT_VERSION}
        -DEXPECTED_COMMUNITY_VERSION=${ANOSECUREKIT_ENTERPRISE_COMMUNITY_VERSION}
        -DEXPECTED_COMMUNITY_TREE=${_anosecurekit_enterprise_community_tree}
        -DEXPECTED_BACKEND_PROFILE=openssl
        -DEXPECTED_PROVIDER_FAMILY=openssl
        -DEXPECTED_SOURCE_REVISION=${_anosecurekit_enterprise_source_revision}
        -DEXPECTED_CODEQL_REQUIRED=ON
        "-DVERIFIER_EXECUTABLE=${ANOSECUREKIT_ENTERPRISE_RELEASE_EVIDENCE_VERIFIER}"
        "-DINSTALLED_VERIFIER_EXECUTABLE=${ANOSECUREKIT_ENTERPRISE_INSTALLED_RELEASE_EVIDENCE_VERIFIER}"
        "-DATTESTATION_BUNDLE=${ANOSECUREKIT_ENTERPRISE_ATTESTATION_BUNDLE}"
        -DGIT_EXECUTABLE=${GIT_EXECUTABLE}
        -P ${CMAKE_CURRENT_SOURCE_DIR}/tests/check_customer_release_authorization.cmake
      USES_TERMINAL)
    add_custom_target(enterprise-customer-delivery-check
      COMMAND ${CMAKE_COMMAND} -E echo
        "AnoSecureKit Enterprise customer delivery authorization passed"
      DEPENDS enterprise-release-authorization-check
      USES_TERMINAL)
  else()
    add_custom_target(enterprise-release-authorization-check
      COMMAND ${CMAKE_COMMAND} -E echo
        "enterprise-release-authorization-check requires the bundled Community OpenSSL delivery profile"
      COMMAND ${CMAKE_COMMAND} -E false
      USES_TERMINAL)
    add_custom_target(enterprise-customer-delivery-check
      COMMAND ${CMAKE_COMMAND} -E echo
        "enterprise-customer-delivery-check requires an allowed release authorization"
      COMMAND ${CMAKE_COMMAND} -E false
      USES_TERMINAL)
  endif()
endif()
if(BUILD_TESTING)
  set(_anosecurekit_enterprise_check_dependencies
    anosecurekit_enterprise_profile_test
    anosecurekit_enterprise_sha256_test
    anosecurekit_enterprise_hmac_sha256_test
    anosecurekit_enterprise_random_test
    anosecurekit_enterprise_info)
  if(ANOSECUREKIT_ENTERPRISE_ENABLE_NATIVE_ANOCRYPTO_C_TESTS)
    list(APPEND _anosecurekit_enterprise_check_dependencies
      anosecurekit_enterprise_native_anocrypto_c_lifecycle_test
      anosecurekit_enterprise_native_anocrypto_c_status_mapping_test)
    if(ANOSECUREKIT_ENTERPRISE_CRYPTO_BACKEND STREQUAL "anocrypto-c")
      list(APPEND _anosecurekit_enterprise_check_dependencies
        anosecurekit_enterprise_anocrypto_c_partial_profile_test)
    endif()
  endif()
  add_custom_target(enterprise-check
    COMMAND ${CMAKE_CTEST_COMMAND}
      --test-dir ${CMAKE_CURRENT_BINARY_DIR}
      --build-config $<CONFIG>
      --output-on-failure
      --parallel ${ANOSECUREKIT_ENTERPRISE_TEST_PARALLEL_LEVEL}
      --label-exclude package
    DEPENDS ${_anosecurekit_enterprise_check_dependencies}
    USES_TERMINAL)

  add_custom_target(enterprise-sanitizer-check
    COMMAND ${CMAKE_CTEST_COMMAND}
      --test-dir ${CMAKE_CURRENT_BINARY_DIR}
      --build-config $<CONFIG>
      --output-on-failure
      --parallel ${ANOSECUREKIT_ENTERPRISE_TEST_PARALLEL_LEVEL}
      --label-regex runtime
    DEPENDS anosecurekit_enterprise_profile_test
    USES_TERMINAL)

  if(ANOSECUREKIT_ENTERPRISE_CRYPTO_BACKEND STREQUAL "openssl"
     AND ANOSECUREKIT_ENTERPRISE_USE_BUNDLED_COMMUNITY)
    add_custom_target(enterprise-release-preflight
      COMMAND ${CMAKE_COMMAND} -E echo
        "AnoSecureKit Enterprise OpenSSL release preflight passed"
      DEPENDS
        enterprise-check
        enterprise-profile-config-check
        enterprise-runtime-contract-check
        enterprise-ci-policy-check
        enterprise-release-evidence-verifier-check
        enterprise-trusted-release-evidence-check
        enterprise-release-authorization-contract-check
        enterprise-openssl-profile-policy-check
        enterprise-package-check
        enterprise-delivery-check
      USES_TERMINAL)
  else()
    add_custom_target(enterprise-release-preflight
      COMMAND ${CMAKE_COMMAND} -E echo
        "enterprise-release-preflight requires the bundled Community OpenSSL delivery profile"
      COMMAND ${CMAKE_COMMAND} -E false
      USES_TERMINAL)
  endif()
endif()
