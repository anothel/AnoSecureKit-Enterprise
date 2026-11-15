# SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary
cmake_minimum_required(VERSION 3.20)
include(CMakePackageConfigHelpers)
if(NOT DEFINED ENTERPRISE_SOURCE_DIR OR NOT DEFINED TEST_ROOT)
  message(FATAL_ERROR "ENTERPRISE_SOURCE_DIR and TEST_ROOT are required")
endif()
file(REMOVE_RECURSE "${TEST_ROOT}")

# Exercise discovery with standard CMake version files, both when building
# Enterprise and when loading its installed config. No crypto is mocked here.
foreach(_version IN ITEMS 0.4.0 0.4.1 0.5.0)
  set(_prefix "${TEST_ROOT}/${_version}/prefix")
  set(_package "${_prefix}/lib/cmake/anosecurekit")
  file(MAKE_DIRECTORY "${_package}")
  file(WRITE "${_package}/anosecurekitConfig.cmake"
    "add_library(anosecurekit::anosecurekit INTERFACE IMPORTED)\n")
  write_basic_package_version_file("${_package}/anosecurekitConfigVersion.cmake"
    VERSION "${_version}" COMPATIBILITY SameMajorVersion)

  set(PROJECT_VERSION 0.1.0)
  set(ANOSECUREKIT_ENTERPRISE_COMMUNITY_VERSION 0.4.0)
  set(ANOSECUREKIT_ENTERPRISE_CRYPTO_BACKEND openssl)
  set(_enterprise_package "${_prefix}/lib/cmake/anosecurekitEnterprise")
  configure_package_config_file(
    "${ENTERPRISE_SOURCE_DIR}/cmake/anosecurekitEnterpriseConfig.cmake.in"
    "${_enterprise_package}/anosecurekitEnterpriseConfig.cmake"
    INSTALL_DESTINATION lib/cmake/anosecurekitEnterprise)
  file(WRITE "${_enterprise_package}/anosecurekitEnterpriseTargets.cmake" "")
  set(_consumer "${TEST_ROOT}/${_version}/consumer")
  file(MAKE_DIRECTORY "${_consumer}")
  file(WRITE "${_consumer}/CMakeLists.txt"
    "cmake_minimum_required(VERSION 3.20)\nproject(version_consumer LANGUAGES CXX)\nfind_package(anosecurekitEnterprise CONFIG REQUIRED)\n")

  foreach(_mode IN ITEMS build installed)
    if(_mode STREQUAL "build")
      set(_source "${ENTERPRISE_SOURCE_DIR}")
    else()
      set(_source "${_consumer}")
    endif()
    execute_process(COMMAND "${CMAKE_COMMAND}" -S "${_source}"
      -B "${TEST_ROOT}/${_version}/${_mode}-build"
      -DCMAKE_PREFIX_PATH=${_prefix}
      -DANOSECUREKIT_ENTERPRISE_USE_BUNDLED_COMMUNITY=OFF
      -DBUILD_TESTING=OFF
      RESULT_VARIABLE _result OUTPUT_VARIABLE _out ERROR_VARIABLE _err)
    if(_version STREQUAL "0.4.0")
      if(NOT _result EQUAL 0)
        message(FATAL_ERROR "${_mode}: exact baseline rejected\n${_out}\n${_err}")
      endif()
    else()
      if(_result EQUAL 0)
        message(FATAL_ERROR "${_mode}: unqualified Community ${_version} accepted")
      endif()
      if(NOT "${_out}${_err}" MATCHES "anosecurekit")
        message(FATAL_ERROR "${_mode}: unrelated failure\n${_out}\n${_err}")
      endif()
    endif()
  endforeach()
endforeach()
message(STATUS "Community exact baseline discovery checks passed")
