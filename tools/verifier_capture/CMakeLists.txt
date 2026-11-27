# SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary
cmake_minimum_required(VERSION 3.20)

if(CMAKE_CURRENT_SOURCE_DIR STREQUAL CMAKE_SOURCE_DIR)
  project(anosecurekit_verifier_capture LANGUAGES CXX)
endif()

if(WIN32)
  set(_platform windows.cpp)
elseif(CMAKE_SYSTEM_NAME MATCHES "^(Linux|Darwin)$")
  set(_platform posix.cpp)
else()
  message(FATAL_ERROR "No supported verifier capture implementation for ${CMAKE_SYSTEM_NAME}")
endif()

add_executable(anosecurekit-verifier-capture main.cpp ${_platform})
target_compile_features(anosecurekit-verifier-capture PRIVATE cxx_std_17)
if(COMMAND _anosecurekit_enterprise_apply_warnings)
  _anosecurekit_enterprise_apply_warnings(anosecurekit-verifier-capture)
endif()
set(_receipt "${CMAKE_CURRENT_BINARY_DIR}/receipt-$<CONFIG>.sha256")
if(NOT CMAKE_CURRENT_SOURCE_DIR STREQUAL CMAKE_SOURCE_DIR)
  set(_enterprise_capture_receipt "${_receipt}" PARENT_SCOPE)
endif()
add_custom_command(TARGET anosecurekit-verifier-capture POST_BUILD
  BYPRODUCTS "${_receipt}"
  COMMAND "${CMAKE_COMMAND}" "-DCAPTURE=$<TARGET_FILE:anosecurekit-verifier-capture>"
    "-DRECEIPT=${_receipt}"
    -P "${CMAKE_CURRENT_SOURCE_DIR}/manifest.cmake"
  VERBATIM)
