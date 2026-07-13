# SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary
if(NOT DEFINED ENTERPRISE_SOURCE_DIR OR NOT DEFINED ENTERPRISE_BINARY_ROOT)
  message(FATAL_ERROR "ENTERPRISE_SOURCE_DIR and ENTERPRISE_BINARY_ROOT are required")
endif()
file(REMOVE_RECURSE "${ENTERPRISE_BINARY_ROOT}")
file(MAKE_DIRECTORY "${ENTERPRISE_BINARY_ROOT}")

function(expect_configure_failure name expected)
  set(_build "${ENTERPRISE_BINARY_ROOT}/${name}")
  execute_process(
    COMMAND "${CMAKE_COMMAND}" -S "${ENTERPRISE_SOURCE_DIR}" -B "${_build}"
      -G "${ENTERPRISE_GENERATOR}" ${ARGN}
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
  "add_library(AnoCryptoC::AnoCryptoC INTERFACE IMPORTED)\n")
expect_configure_failure(missing-adapter "AnoCrypto-C profile is fail-closed"
  -DANOSECUREKIT_ENTERPRISE_CRYPTO_BACKEND=anocrypto-c
  -DCMAKE_PREFIX_PATH=${_fake_prefix})

message(STATUS "Enterprise profile configuration checks passed")
