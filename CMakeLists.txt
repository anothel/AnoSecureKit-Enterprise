# SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary
cmake_minimum_required(VERSION 3.20)

project(
  anosecurekit_enterprise
  VERSION 0.1.0
  DESCRIPTION "AnoSecureKit Enterprise"
  LANGUAGES CXX)

include(CTest)
include(GNUInstallDirs)

option(ANOSECUREKIT_ENTERPRISE_USE_BUNDLED_COMMUNITY "Use bundled Community source" ON)
set(ANOSECUREKIT_ENTERPRISE_CRYPTO_BACKEND "openssl" CACHE STRING
  "Enterprise crypto profile: openssl or anocrypto-c")
set_property(CACHE ANOSECUREKIT_ENTERPRISE_CRYPTO_BACKEND PROPERTY STRINGS openssl anocrypto-c)
if(DEFINED ANOSECUREKIT_ENTERPRISE_ENABLE_ANOCRYPTO)
  message(FATAL_ERROR
    "ANOSECUREKIT_ENTERPRISE_ENABLE_ANOCRYPTO is obsolete. Use "
    "-DANOSECUREKIT_ENTERPRISE_CRYPTO_BACKEND=openssl or anocrypto-c.")
endif()
set(ANOSECUREKIT_ENTERPRISE_ANOCRYPTO_C_PROVIDER_TARGET "" CACHE STRING
  "Existing non-imported OBJECT_LIBRARY implementing the AnoSecureKit provider contract for AnoCrypto-C")
set(_anosecurekit_enterprise_required_capabilities
  sha256
  hmac-sha256
  hkdf-sha256
  random
  scrypt
  aes256-gcm
  aes256-gcm-stream)

if(NOT ANOSECUREKIT_ENTERPRISE_CRYPTO_BACKEND STREQUAL "openssl"
   AND NOT ANOSECUREKIT_ENTERPRISE_CRYPTO_BACKEND STREQUAL "anocrypto-c")
  message(FATAL_ERROR
    "Unsupported ANOSECUREKIT_ENTERPRISE_CRYPTO_BACKEND='${ANOSECUREKIT_ENTERPRISE_CRYPTO_BACKEND}'. "
    "Expected 'openssl' or 'anocrypto-c'.")
endif()

if(ANOSECUREKIT_ENTERPRISE_CRYPTO_BACKEND STREQUAL "anocrypto-c")
  find_package(AnoCryptoC CONFIG REQUIRED)
  if(NOT TARGET AnoCryptoC::AnoCryptoC)
    message(FATAL_ERROR
      "AnoCrypto-C profile requires imported target AnoCryptoC::AnoCryptoC")
  endif()
  if(ANOSECUREKIT_ENTERPRISE_ANOCRYPTO_C_PROVIDER_TARGET STREQUAL "")
    message(FATAL_ERROR
      "AnoCrypto-C profile is fail-closed until a complete Enterprise provider adapter is supplied. "
      "Set ANOSECUREKIT_ENTERPRISE_ANOCRYPTO_C_PROVIDER_TARGET to an existing non-imported "
      "OBJECT_LIBRARY that implements the full AnoSecureKit provider contract.")
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
    message(FATAL_ERROR
      "AnoCrypto-C provider is incomplete for the Enterprise production profile. "
      "Missing required capabilities: ${_enterprise_missing_capabilities_text}. "
      "No OpenSSL fallback is permitted.")
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
  add_subdirectory(third_party/anosecurekit-community EXCLUDE_FROM_ALL)
else()
  if(NOT ANOSECUREKIT_ENTERPRISE_CRYPTO_BACKEND STREQUAL "openssl")
    message(FATAL_ERROR
      "Non-bundled Community package mode currently supports only the openssl Enterprise profile. "
      "The AnoCrypto-C profile requires Community's build-tree external provider hook.")
  endif()
  find_package(anosecurekit 0.4 CONFIG REQUIRED)
endif()

add_library(anosecurekit_enterprise src/enterprise.cpp)
add_library(anosecurekit::enterprise ALIAS anosecurekit_enterprise)
target_compile_features(anosecurekit_enterprise PUBLIC cxx_std_20)
target_include_directories(anosecurekit_enterprise
  PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>)
target_link_libraries(anosecurekit_enterprise PUBLIC anosecurekit::anosecurekit)

if(ANOSECUREKIT_ENTERPRISE_CRYPTO_BACKEND STREQUAL "openssl")
  target_compile_definitions(anosecurekit_enterprise PUBLIC
    ANOSECUREKIT_ENTERPRISE_BACKEND_OPENSSL=1)
else()
  target_compile_definitions(anosecurekit_enterprise PUBLIC
    ANOSECUREKIT_ENTERPRISE_BACKEND_ANOCRYPTO_C=1
    ANOSECUREKIT_ENTERPRISE_BACKEND_CAPABILITY_COMPLETE=1)
  target_link_libraries(anosecurekit_enterprise PRIVATE AnoCryptoC::AnoCryptoC)
endif()

add_executable(anosecurekit_enterprise_info examples/info/main.cpp)
target_link_libraries(anosecurekit_enterprise_info PRIVATE anosecurekit::enterprise)
target_compile_features(anosecurekit_enterprise_info PRIVATE cxx_std_20)

if(BUILD_TESTING)
  add_custom_target(enterprise-profile-config-check
    COMMAND ${CMAKE_COMMAND}
      -DENTERPRISE_SOURCE_DIR=${CMAKE_CURRENT_SOURCE_DIR}
      -DENTERPRISE_BINARY_ROOT=${CMAKE_CURRENT_BINARY_DIR}/profile-config-check
      -DENTERPRISE_GENERATOR=${CMAKE_GENERATOR}
      -P ${CMAKE_CURRENT_SOURCE_DIR}/tests/check_profile_config.cmake
    USES_TERMINAL)

  add_executable(anosecurekit_enterprise_profile_test tests/profile_test.cpp)
  target_link_libraries(anosecurekit_enterprise_profile_test PRIVATE anosecurekit::enterprise)
  target_compile_features(anosecurekit_enterprise_profile_test PRIVATE cxx_std_20)
  add_test(NAME enterprise.profile COMMAND anosecurekit_enterprise_profile_test)
endif()

install(TARGETS anosecurekit_enterprise
  EXPORT anosecurekitEnterpriseTargets
  RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
  LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
  ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR})
install(DIRECTORY include/anosecurekit_enterprise DESTINATION ${CMAKE_INSTALL_INCLUDEDIR})
