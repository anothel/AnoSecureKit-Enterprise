# SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary
cmake_minimum_required(VERSION 3.20)

if(NOT DEFINED ENTERPRISE_SOURCE_DIR OR ENTERPRISE_SOURCE_DIR STREQUAL "")
  message(FATAL_ERROR "ENTERPRISE_SOURCE_DIR is required")
endif()

set(_community_path "third_party/anosecurekit-community")
set(_expected_community_tree "9b498f5431f217ac71e8d2e2c92df9e8b0122626")

file(GLOB_RECURSE _enterprise_sources LIST_DIRECTORIES false
  "${ENTERPRISE_SOURCE_DIR}/src/*.c"
  "${ENTERPRISE_SOURCE_DIR}/src/*.cc"
  "${ENTERPRISE_SOURCE_DIR}/src/*.cpp"
  "${ENTERPRISE_SOURCE_DIR}/src/*.h"
  "${ENTERPRISE_SOURCE_DIR}/src/*.hpp"
  "${ENTERPRISE_SOURCE_DIR}/include/*.h"
  "${ENTERPRISE_SOURCE_DIR}/include/*.hpp"
  "${ENTERPRISE_SOURCE_DIR}/examples/*.c"
  "${ENTERPRISE_SOURCE_DIR}/examples/*.cc"
  "${ENTERPRISE_SOURCE_DIR}/examples/*.cpp"
  "${ENTERPRISE_SOURCE_DIR}/tests/*.c"
  "${ENTERPRISE_SOURCE_DIR}/tests/*.cc"
  "${ENTERPRISE_SOURCE_DIR}/tests/*.cpp"
  "${ENTERPRISE_SOURCE_DIR}/tests/*.h"
  "${ENTERPRISE_SOURCE_DIR}/tests/*.hpp")

foreach(_source IN LISTS _enterprise_sources)
  file(READ "${_source}" _content)
  if(_content MATCHES "#[ \t]*include[ \t]*[<\"]openssl/")
    message(FATAL_ERROR "Enterprise-owned source includes an OpenSSL header: ${_source}")
  endif()
  if(_content MATCHES "(^|[^A-Za-z0-9_])(EVP_|RAND_|OSSL_|OPENSSL_|SSL_|CRYPTO_|BIO_|ERR_|X509_|BN_|EC_|RSA_|AES_|SHA_|PKCS5_)[A-Za-z0-9_]*")
    message(FATAL_ERROR "Enterprise-owned source uses an OpenSSL cryptographic symbol: ${_source}")
  endif()
endforeach()

set(_enterprise_build_files
  "${ENTERPRISE_SOURCE_DIR}/CMakeLists.txt"
  "${ENTERPRISE_SOURCE_DIR}/cmake/anosecurekitEnterpriseConfig.cmake.in"
  "${ENTERPRISE_SOURCE_DIR}/packaging/cpack/CMakeLists.txt")
foreach(_build_file IN LISTS _enterprise_build_files)
  file(READ "${_build_file}" _content)
  string(FIND "${_content}" "OpenSSL::Crypto" _direct_link)
  if(NOT _direct_link EQUAL -1)
    message(FATAL_ERROR "Enterprise-owned build code links OpenSSL::Crypto directly: ${_build_file}")
  endif()
endforeach()

file(GLOB_RECURSE _duplicate_provider_files LIST_DIRECTORIES false
  "${ENTERPRISE_SOURCE_DIR}/src/*crypto_backend_openssl*"
  "${ENTERPRISE_SOURCE_DIR}/include/*crypto_backend_openssl*")
if(_duplicate_provider_files)
  message(FATAL_ERROR
    "Enterprise-owned source contains a duplicate OpenSSL provider: ${_duplicate_provider_files}")
endif()

find_program(_git_executable NAMES git)
if(NOT _git_executable)
  message(FATAL_ERROR "git is required to verify the bundled Community subtree")
endif()
execute_process(
  COMMAND "${_git_executable}" rev-parse "HEAD:${_community_path}"
  WORKING_DIRECTORY "${ENTERPRISE_SOURCE_DIR}"
  RESULT_VARIABLE _tree_result
  OUTPUT_VARIABLE _community_tree
  OUTPUT_STRIP_TRAILING_WHITESPACE
  ERROR_VARIABLE _tree_error)
if(NOT _tree_result EQUAL 0)
  message(FATAL_ERROR "Could not read bundled Community Git tree: ${_tree_error}")
endif()
if(NOT _community_tree STREQUAL _expected_community_tree)
  message(FATAL_ERROR
    "Bundled Community tree changed: expected ${_expected_community_tree}, got ${_community_tree}")
endif()

execute_process(
  COMMAND "${_git_executable}" -c core.autocrlf=true status
    --porcelain --untracked-files=all -- "${_community_path}"
  WORKING_DIRECTORY "${ENTERPRISE_SOURCE_DIR}"
  RESULT_VARIABLE _status_result
  OUTPUT_VARIABLE _community_status
  OUTPUT_STRIP_TRAILING_WHITESPACE
  ERROR_VARIABLE _status_error)
if(NOT _status_result EQUAL 0)
  message(FATAL_ERROR "Could not inspect bundled Community worktree: ${_status_error}")
endif()
if(NOT _community_status STREQUAL "")
  message(FATAL_ERROR "Bundled Community worktree is modified:\n${_community_status}")
endif()

message(STATUS
  "Enterprise OpenSSL boundary passed; Community tree ${_community_tree} is unchanged")
