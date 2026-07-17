# SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary

if(NOT DEFINED ENTERPRISE_SOURCE_DIR OR NOT DEFINED ENTERPRISE_BINARY_DIR)
  message(FATAL_ERROR "ENTERPRISE_SOURCE_DIR and ENTERPRISE_BINARY_DIR are required")
endif()

file(GLOB_RECURSE _provider_sources
  "${ENTERPRISE_SOURCE_DIR}/src/providers/anocrypto_c/*.cpp"
  "${ENTERPRISE_SOURCE_DIR}/src/providers/anocrypto_c/*.hpp")
foreach(_source IN LISTS _provider_sources)
  file(READ "${_source}" _contents)
  if(_contents MATCHES "#[ \t]*include[ \t]*[<\"]openssl/"
     OR _contents MATCHES "(^|[^A-Za-z0-9_])(EVP_|OSSL_|RAND_|OPENSSL_|SSL_|CRYPTO_)")
    message(FATAL_ERROR "OpenSSL header or symbol found in AnoCrypto-C provider: ${_source}")
  endif()
endforeach()

set(_install_script "${ENTERPRISE_BINARY_DIR}/cmake_install.cmake")
if(NOT EXISTS "${_install_script}")
  message(FATAL_ERROR "Native install script was not generated")
endif()
file(READ "${_install_script}" _install_contents)
if(_install_contents MATCHES "file\\(INSTALL"
   OR _install_contents MATCHES "anosecurekitEnterpriseTargets"
   OR _install_contents MATCHES "third_party/anosecurekit-community/cmake_install")
  message(FATAL_ERROR "Partial AnoCrypto-C profile exposes install or CMake export content")
endif()

if(EXISTS "${ENTERPRISE_BINARY_DIR}/CPackConfig.cmake"
   OR EXISTS "${ENTERPRISE_BINARY_DIR}/CPackSourceConfig.cmake")
  message(FATAL_ERROR "Partial AnoCrypto-C profile exposes CPack configuration")
endif()

message(STATUS "AnoCrypto-C source, install, export, and CPack boundary passed")
