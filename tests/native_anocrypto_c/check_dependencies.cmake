# SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary

if(NOT DEFINED NATIVE_TEST_EXECUTABLE OR NATIVE_TEST_EXECUTABLE STREQUAL ""
   OR NOT DEFINED ANOCRYPTO_C_LIBRARY OR ANOCRYPTO_C_LIBRARY STREQUAL "")
  message(FATAL_ERROR "NATIVE_TEST_EXECUTABLE and ANOCRYPTO_C_LIBRARY are required")
endif()

if(NOT CMAKE_HOST_SYSTEM_NAME STREQUAL "Linux")
  message(STATUS
    "AnoCrypto-C dependency purity inspection deferred on ${CMAKE_HOST_SYSTEM_NAME}")
  return()
endif()

find_program(_ldd_executable NAMES ldd REQUIRED)

set(_native_binaries "${NATIVE_TEST_EXECUTABLE}" "${ANOCRYPTO_C_LIBRARY}")
if(DEFINED NATIVE_SHA256_EXECUTABLE AND NOT NATIVE_SHA256_EXECUTABLE STREQUAL "")
  list(APPEND _native_binaries "${NATIVE_SHA256_EXECUTABLE}")
endif()
if(DEFINED NATIVE_HMAC_SHA256_EXECUTABLE
   AND NOT NATIVE_HMAC_SHA256_EXECUTABLE STREQUAL "")
  list(APPEND _native_binaries "${NATIVE_HMAC_SHA256_EXECUTABLE}")
endif()
if(DEFINED NATIVE_RANDOM_EXECUTABLE AND NOT NATIVE_RANDOM_EXECUTABLE STREQUAL "")
  list(APPEND _native_binaries "${NATIVE_RANDOM_EXECUTABLE}")
endif()
if(DEFINED NATIVE_UNSUPPORTED_EXECUTABLE
   AND NOT NATIVE_UNSUPPORTED_EXECUTABLE STREQUAL "")
  list(APPEND _native_binaries "${NATIVE_UNSUPPORTED_EXECUTABLE}")
endif()

foreach(_binary IN LISTS _native_binaries)
  if(NOT EXISTS "${_binary}")
    message(FATAL_ERROR "Dependency inspection input does not exist: ${_binary}")
  endif()

  execute_process(
    COMMAND "${_ldd_executable}" "${_binary}"
    RESULT_VARIABLE _ldd_result
    OUTPUT_VARIABLE _ldd_out
    ERROR_VARIABLE _ldd_err)
  if(NOT _ldd_result EQUAL 0)
    string(CONCAT _ldd_log "${_ldd_out}" "${_ldd_err}")
    message(FATAL_ERROR "ldd failed for ${_binary}\n${_ldd_log}")
  endif()

  string(TOLOWER "${_ldd_out}" _ldd_lower)
  if(_ldd_lower MATCHES "libcrypto|libssl")
    message(FATAL_ERROR
      "AnoCrypto-C native dependency purity failed for ${_binary}\n${_ldd_out}")
  endif()
  message(STATUS "No libcrypto/libssl dependency: ${_binary}")
endforeach()
