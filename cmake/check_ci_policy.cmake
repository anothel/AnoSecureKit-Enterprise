# SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary

if(NOT DEFINED ENTERPRISE_SOURCE_DIR OR ENTERPRISE_SOURCE_DIR STREQUAL "")
  message(FATAL_ERROR "ENTERPRISE_SOURCE_DIR is required")
endif()

set(_workflow "${ENTERPRISE_SOURCE_DIR}/.github/workflows/anosecurekit-enterprise-ci.yml")
if(NOT EXISTS "${_workflow}")
  message(FATAL_ERROR "Enterprise CI workflow is missing: ${_workflow}")
endif()

file(READ "${_workflow}" _content)

set(_required_terms
  "name: AnoSecureKit Enterprise CI"
  "permissions:"
  "contents: read"
  "ubuntu-latest"
  "windows-latest"
  "macos-latest"
  "compiler: gcc"
  "compiler: clang"
  "compiler: msvc"
  "compiler: appleclang"
  "shared: 'OFF'"
  "shared: 'ON'"
  "fail-fast: false"
  "-DBUILD_SHARED_LIBS="
  "enterprise-release-preflight"
  "enterprise-check"
  "enterprise-sanitizer-check"
  "enterprise-delivery-check"
  "non-bundled-consumer"
  "actions/upload-artifact@v7"
  "artifact-validation:"
  "actions/download-artifact@v8"
  "check_downloaded_artifact.cmake"
  "codeql:"
  "ANOSECUREKIT_ENABLE_CODEQL == 'true'"
  "github/codeql-action/init@v4"
  "github/codeql-action/analyze@v4"
  "security-events: write"
  "retention-days: 14")

foreach(_term IN LISTS _required_terms)
  string(FIND "${_content}" "${_term}" _position)
  if(_position EQUAL -1)
    message(FATAL_ERROR "Enterprise CI workflow is missing required term: ${_term}")
  endif()
endforeach()

set(_forbidden_terms
  "softprops/action-gh-release"
  "gh release create"
  "gh release upload"
  "contents: write"
  "id-token: write"
  "pull_request_target"
  "secrets.")
foreach(_term IN LISTS _forbidden_terms)
  string(FIND "${_content}" "${_term}" _position)
  if(NOT _position EQUAL -1)
    message(FATAL_ERROR
      "Enterprise CI must not publish releases or request write permission yet: ${_term}")
  endif()
endforeach()

message(STATUS "AnoSecureKit Enterprise CI policy check passed")
