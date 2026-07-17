# SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary
if(NOT DEFINED ENTERPRISE_SOURCE_DIR OR NOT DEFINED ENTERPRISE_BUILD_DIR
   OR NOT DEFINED ENTERPRISE_PACKAGE_CHECK_ROOT)
  message(FATAL_ERROR
    "ENTERPRISE_SOURCE_DIR, ENTERPRISE_BUILD_DIR, and ENTERPRISE_PACKAGE_CHECK_ROOT are required")
endif()

file(REMOVE_RECURSE "${ENTERPRISE_PACKAGE_CHECK_ROOT}")
file(MAKE_DIRECTORY "${ENTERPRISE_PACKAGE_CHECK_ROOT}")
set(_install_prefix "${ENTERPRISE_PACKAGE_CHECK_ROOT}/install")
set(_consumer_build "${ENTERPRISE_PACKAGE_CHECK_ROOT}/consumer-build")

set(_config_args "")
if(DEFINED ENTERPRISE_BUILD_CONFIG AND NOT ENTERPRISE_BUILD_CONFIG STREQUAL "")
  list(APPEND _config_args --config "${ENTERPRISE_BUILD_CONFIG}")
endif()

execute_process(
  COMMAND "${CMAKE_COMMAND}" --install "${ENTERPRISE_BUILD_DIR}"
    ${_config_args} --prefix "${_install_prefix}"
  RESULT_VARIABLE _install_result
  OUTPUT_VARIABLE _install_out
  ERROR_VARIABLE _install_err)
if(NOT _install_result EQUAL 0)
  string(CONCAT _log "${_install_out}" "${_install_err}")
  message(FATAL_ERROR "Enterprise staged install failed\n${_log}")
endif()

set(_required_paths
  "${_install_prefix}/include/anosecurekit/anosecurekit.hpp"
  "${_install_prefix}/include/anosecurekit_enterprise/enterprise.hpp"
  "${_install_prefix}/include/anosecurekit_enterprise/provider_runtime.hpp"
  "${_install_prefix}/share/anosecurekit-enterprise/LICENSE"
  "${_install_prefix}/share/anosecurekit-enterprise/THIRD_PARTY_NOTICES.md"
  "${_install_prefix}/share/anosecurekit-enterprise/BACKEND_PROFILES.md"
  "${_install_prefix}/share/anosecurekit-enterprise/COMMUNITY_DEPENDENCY.md"
  "${_install_prefix}/share/anosecurekit-enterprise/DEFERRED_CI_STATUS.md"
  "${_install_prefix}/share/anosecurekit-enterprise/OPENSSL_PROFILE_SUPPORT_POLICY.md"
  "${_install_prefix}/share/anosecurekit-enterprise/SUPPORTED_CONFIGURATION_MATRIX.md")
foreach(_path IN LISTS _required_paths)
  if(NOT EXISTS "${_path}")
    message(FATAL_ERROR "Installed package is missing required path: ${_path}")
  endif()
endforeach()

if(EXISTS "${_install_prefix}/include/anosecurekit_enterprise/detail/provider_runtime_contract.hpp")
  message(FATAL_ERROR
    "Installed package must not expose the private provider runtime contract header")
endif()

file(GLOB_RECURSE _community_configs
  "${_install_prefix}/*/cmake/anosecurekit/anosecurekitConfig.cmake")
file(GLOB_RECURSE _enterprise_configs
  "${_install_prefix}/*/cmake/anosecurekitEnterprise/anosecurekitEnterpriseConfig.cmake")
if(NOT _community_configs)
  message(FATAL_ERROR "Installed Community CMake package config is missing")
endif()
if(NOT _enterprise_configs)
  message(FATAL_ERROR "Installed Enterprise CMake package config is missing")
endif()

set(_configure_command
  "${CMAKE_COMMAND}"
  -S "${ENTERPRISE_SOURCE_DIR}/tests/package/consumer"
  -B "${_consumer_build}"
  -G "${ENTERPRISE_GENERATOR}"
  "-DCMAKE_PREFIX_PATH=${_install_prefix}")
if(DEFINED ENTERPRISE_CMAKE_MAKE_PROGRAM AND NOT ENTERPRISE_CMAKE_MAKE_PROGRAM STREQUAL "")
  list(APPEND _configure_command
    "-DCMAKE_MAKE_PROGRAM=${ENTERPRISE_CMAKE_MAKE_PROGRAM}")
endif()
if(DEFINED ENTERPRISE_CXX_COMPILER AND NOT ENTERPRISE_CXX_COMPILER STREQUAL "")
  list(APPEND _configure_command
    "-DCMAKE_CXX_COMPILER=${ENTERPRISE_CXX_COMPILER}")
endif()
if(DEFINED ENTERPRISE_DEFAULT_BUILD_TYPE AND NOT ENTERPRISE_DEFAULT_BUILD_TYPE STREQUAL "")
  list(APPEND _configure_command
    "-DCMAKE_BUILD_TYPE=${ENTERPRISE_DEFAULT_BUILD_TYPE}")
endif()

execute_process(
  COMMAND ${_configure_command}
  RESULT_VARIABLE _configure_result
  OUTPUT_VARIABLE _configure_out
  ERROR_VARIABLE _configure_err)
if(NOT _configure_result EQUAL 0)
  string(CONCAT _log "${_configure_out}" "${_configure_err}")
  message(FATAL_ERROR "Installed consumer configuration failed\n${_log}")
endif()

execute_process(
  COMMAND "${CMAKE_COMMAND}" --build "${_consumer_build}"
    ${_config_args} --parallel 4
  RESULT_VARIABLE _build_result
  OUTPUT_VARIABLE _build_out
  ERROR_VARIABLE _build_err)
if(NOT _build_result EQUAL 0)
  string(CONCAT _log "${_build_out}" "${_build_err}")
  message(FATAL_ERROR "Installed consumer build failed\n${_log}")
endif()

set(_consumer_candidates
  "${_consumer_build}/anosecurekit_enterprise_installed_consumer${CMAKE_EXECUTABLE_SUFFIX}"
  "${_consumer_build}/${ENTERPRISE_BUILD_CONFIG}/anosecurekit_enterprise_installed_consumer${CMAKE_EXECUTABLE_SUFFIX}")
set(_consumer_executable "")
foreach(_candidate IN LISTS _consumer_candidates)
  if(EXISTS "${_candidate}")
    set(_consumer_executable "${_candidate}")
    break()
  endif()
endforeach()
if(_consumer_executable STREQUAL "")
  message(FATAL_ERROR "Installed consumer executable was not found")
endif()

execute_process(
  COMMAND "${_consumer_executable}"
  RESULT_VARIABLE _run_result
  OUTPUT_VARIABLE _run_out
  ERROR_VARIABLE _run_err)
if(NOT _run_result EQUAL 0)
  string(CONCAT _log "${_run_out}" "${_run_err}")
  message(FATAL_ERROR "Installed consumer execution failed with ${_run_result}\n${_log}")
endif()

message(STATUS "Enterprise installed package/consumer check passed")
