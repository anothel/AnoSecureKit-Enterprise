# SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary
cmake_minimum_required(VERSION 3.20)

foreach(_required IN ITEMS
    ENTERPRISE_SOURCE_DIR ENTERPRISE_DELIVERY_ROOT AUTHORIZATION_RECORD
    EXPECTED_ENTERPRISE_VERSION EXPECTED_COMMUNITY_VERSION EXPECTED_COMMUNITY_TREE
    EXPECTED_BACKEND_PROFILE EXPECTED_PROVIDER_FAMILY EXPECTED_SOURCE_REVISION
    EXPECTED_CODEQL_REQUIRED GIT_EXECUTABLE)
  if(NOT DEFINED ${_required} OR "${${_required}}" STREQUAL "")
    message(FATAL_ERROR "${_required} is required")
  endif()
endforeach()

execute_process(
  COMMAND "${GIT_EXECUTABLE}" status --porcelain=v1 --untracked-files=all
  WORKING_DIRECTORY "${ENTERPRISE_SOURCE_DIR}"
  RESULT_VARIABLE _git_status_result OUTPUT_VARIABLE _git_status
  ERROR_VARIABLE _git_status_error)
if(NOT _git_status_result EQUAL 0 OR NOT _git_status STREQUAL "")
  message(FATAL_ERROR
    "Customer release authorization requires a clean source worktree: ${_git_status_error}${_git_status}")
endif()
execute_process(
  COMMAND "${GIT_EXECUTABLE}" rev-parse HEAD
  WORKING_DIRECTORY "${ENTERPRISE_SOURCE_DIR}"
  RESULT_VARIABLE _head_result OUTPUT_VARIABLE _head
  OUTPUT_STRIP_TRAILING_WHITESPACE ERROR_QUIET)
execute_process(
  COMMAND "${GIT_EXECUTABLE}" rev-parse HEAD:third_party/anosecurekit-community
  WORKING_DIRECTORY "${ENTERPRISE_SOURCE_DIR}"
  RESULT_VARIABLE _tree_result OUTPUT_VARIABLE _community_tree
  OUTPUT_STRIP_TRAILING_WHITESPACE ERROR_QUIET)
if(NOT _head_result EQUAL 0 OR NOT _head STREQUAL EXPECTED_SOURCE_REVISION)
  message(FATAL_ERROR "Configured source revision does not match current HEAD")
endif()
if(NOT _tree_result EQUAL 0 OR NOT _community_tree STREQUAL EXPECTED_COMMUNITY_TREE)
  message(FATAL_ERROR "Configured Community tree does not match current HEAD")
endif()

set(_stage_manifest "${ENTERPRISE_DELIVERY_ROOT}/stage/MANIFEST.sha256")
set(_delivery "${ENTERPRISE_DELIVERY_ROOT}/delivery")
set(_artifact_manifest "${_delivery}/SHA256SUMS.txt")
if(NOT EXISTS "${_stage_manifest}" OR NOT EXISTS "${_artifact_manifest}")
  message(FATAL_ERROR
    "Verified internal delivery is missing; run enterprise-delivery-check before authorization")
endif()
execute_process(
  COMMAND "${CMAKE_COMMAND}" -DROOT=${_delivery}
    -P "${ENTERPRISE_SOURCE_DIR}/packaging/scripts/verify_sha256sums.cmake"
  RESULT_VARIABLE _verify_result)
if(NOT _verify_result EQUAL 0)
  message(FATAL_ERROR "Delivery artifact set failed checksum verification")
endif()
execute_process(
  COMMAND "${CMAKE_COMMAND}" -DROOT=${ENTERPRISE_DELIVERY_ROOT}/stage
    -P "${ENTERPRISE_SOURCE_DIR}/packaging/scripts/verify_manifest.cmake"
  RESULT_VARIABLE _manifest_verify_result)
if(NOT _manifest_verify_result EQUAL 0)
  message(FATAL_ERROR "Staged delivery manifest verification failed")
endif()
file(STRINGS "${_artifact_manifest}" _artifact_digest_lines ENCODING UTF-8)
file(GLOB _delivery_assets LIST_DIRECTORIES false RELATIVE "${_delivery}" "${_delivery}/*")
list(FILTER _delivery_assets EXCLUDE REGEX "^SHA256SUMS\\.txt$")
list(LENGTH _artifact_digest_lines _artifact_digest_count)
list(LENGTH _delivery_assets _delivery_asset_count)
if(NOT _artifact_digest_count EQUAL _delivery_asset_count)
  message(FATAL_ERROR "SHA256SUMS.txt does not bind the complete delivery artifact set")
endif()

file(SHA256 "${_stage_manifest}" _manifest_digest)
file(SHA256 "${_artifact_manifest}" _artifact_set_digest)
set(EXPECTED_ARTIFACT_MANIFEST_DIGEST "sha256:${_manifest_digest}")
set(EXPECTED_ARTIFACT_SET_DIGEST "sha256:${_artifact_set_digest}")
set(REQUIRE_ALLOW ON)
set(ALLOW_TEST_FIXTURE OFF)
include("${ENTERPRISE_SOURCE_DIR}/cmake/check_release_authorization.cmake")
