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

option(ANOSECUREKIT_ENTERPRISE_USE_BUNDLED_COMMUNITY "Use bundled Community source" ON)
option(ANOSECUREKIT_ENTERPRISE_INSTALL_INFO "Install the Enterprise diagnostic executable" ON)
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
  "Existing non-imported OBJECT_LIBRARY implementing the Enterprise AnoCrypto-C lifecycle/diagnostic contract")
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

  if(ANOSECUREKIT_ENTERPRISE_ANOCRYPTO_C_RUNTIME_TARGET STREQUAL "")
    message(FATAL_ERROR
      "AnoCrypto-C profile requires a lifecycle/diagnostic adapter target. "
      "Set ANOSECUREKIT_ENTERPRISE_ANOCRYPTO_C_RUNTIME_TARGET to an existing non-imported "
      "OBJECT_LIBRARY implementing the Enterprise provider runtime contract.")
  endif()
  if(NOT TARGET "${ANOSECUREKIT_ENTERPRISE_ANOCRYPTO_C_RUNTIME_TARGET}")
    message(FATAL_ERROR
      "ANOSECUREKIT_ENTERPRISE_ANOCRYPTO_C_RUNTIME_TARGET does not name an existing target")
  endif()
  get_target_property(_enterprise_runtime_imported
    "${ANOSECUREKIT_ENTERPRISE_ANOCRYPTO_C_RUNTIME_TARGET}" IMPORTED)
  get_target_property(_enterprise_runtime_type
    "${ANOSECUREKIT_ENTERPRISE_ANOCRYPTO_C_RUNTIME_TARGET}" TYPE)
  if(_enterprise_runtime_imported OR NOT _enterprise_runtime_type STREQUAL "OBJECT_LIBRARY")
    message(FATAL_ERROR
      "AnoCrypto-C runtime target must be a non-imported OBJECT_LIBRARY adapter")
  endif()
  get_target_property(_enterprise_runtime_backend_id
    "${ANOSECUREKIT_ENTERPRISE_ANOCRYPTO_C_RUNTIME_TARGET}"
    ANOSECUREKIT_ENTERPRISE_PROVIDER_BACKEND_ID)
  if(NOT _enterprise_runtime_backend_id STREQUAL "anocrypto-c")
    message(FATAL_ERROR
      "AnoCrypto-C runtime target must set target property "
      "ANOSECUREKIT_ENTERPRISE_PROVIDER_BACKEND_ID to 'anocrypto-c'")
  endif()
  get_target_property(_enterprise_runtime_contract_version
    "${ANOSECUREKIT_ENTERPRISE_ANOCRYPTO_C_RUNTIME_TARGET}"
    ANOSECUREKIT_ENTERPRISE_RUNTIME_CONTRACT_VERSION)
  if(NOT _enterprise_runtime_contract_version STREQUAL "1")
    message(FATAL_ERROR
      "AnoCrypto-C runtime target must declare "
      "ANOSECUREKIT_ENTERPRISE_RUNTIME_CONTRACT_VERSION=1")
  endif()
  get_target_property(_enterprise_runtime_link_libraries
    "${ANOSECUREKIT_ENTERPRISE_ANOCRYPTO_C_RUNTIME_TARGET}" LINK_LIBRARIES)
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
target_compile_features(anosecurekit_enterprise PUBLIC cxx_std_20)
target_include_directories(anosecurekit_enterprise
  PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>)
target_link_libraries(anosecurekit_enterprise PUBLIC anosecurekit::anosecurekit)

if(ANOSECUREKIT_ENTERPRISE_CRYPTO_BACKEND STREQUAL "openssl")
  target_sources(anosecurekit_enterprise PRIVATE src/provider_runtime_openssl.cpp)
  target_compile_definitions(anosecurekit_enterprise PUBLIC
    ANOSECUREKIT_ENTERPRISE_BACKEND_OPENSSL=1)
else()
  target_include_directories("${ANOSECUREKIT_ENTERPRISE_ANOCRYPTO_C_RUNTIME_TARGET}"
    PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/include")
  target_compile_features("${ANOSECUREKIT_ENTERPRISE_ANOCRYPTO_C_RUNTIME_TARGET}" PRIVATE cxx_std_20)
  target_sources(anosecurekit_enterprise PRIVATE
    $<TARGET_OBJECTS:${ANOSECUREKIT_ENTERPRISE_ANOCRYPTO_C_RUNTIME_TARGET}>)
  target_compile_definitions(anosecurekit_enterprise PUBLIC
    ANOSECUREKIT_ENTERPRISE_BACKEND_ANOCRYPTO_C=1)
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

  add_custom_target(enterprise-runtime-contract-check
    COMMAND ${CMAKE_COMMAND}
      -DENTERPRISE_SOURCE_DIR=${CMAKE_CURRENT_SOURCE_DIR}
      -DENTERPRISE_BINARY_ROOT=${CMAKE_CURRENT_BINARY_DIR}/runtime-contract-check
      -DENTERPRISE_GENERATOR=${CMAKE_GENERATOR}
      -P ${CMAKE_CURRENT_SOURCE_DIR}/tests/check_runtime_contract.cmake
    USES_TERMINAL)

  add_executable(anosecurekit_enterprise_profile_test tests/profile_test.cpp)
  target_link_libraries(anosecurekit_enterprise_profile_test PRIVATE anosecurekit::enterprise)
  target_compile_features(anosecurekit_enterprise_profile_test PRIVATE cxx_std_20)
  add_test(NAME enterprise.profile COMMAND anosecurekit_enterprise_profile_test)
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
    docs/INSTALLATION.md
    docs/PRODUCT_BOUNDARY.md
    docs/PROVIDER_CAPABILITY_CONTRACT.md
    docs/PROVIDER_RUNTIME_CONTRACT.md
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
        -DENTERPRISE_CMAKE_MAKE_PROGRAM=${CMAKE_MAKE_PROGRAM}
        -DENTERPRISE_CXX_COMPILER=${CMAKE_CXX_COMPILER}
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
        -DENTERPRISE_CMAKE_MAKE_PROGRAM=${CMAKE_MAKE_PROGRAM}
        -DENTERPRISE_CXX_COMPILER=${CMAKE_CXX_COMPILER}
        -P ${CMAKE_CURRENT_SOURCE_DIR}/tests/package/check_installed_consumer.cmake)
    set_tests_properties(enterprise.installed-consumer PROPERTIES LABELS "package;consumer")
  else()
    add_custom_target(enterprise-package-check
      COMMAND ${CMAKE_COMMAND} -E echo
        "enterprise-package-check requires the bundled Community OpenSSL delivery profile"
      COMMAND ${CMAKE_COMMAND} -E false
      USES_TERMINAL)
  endif()
endif()
