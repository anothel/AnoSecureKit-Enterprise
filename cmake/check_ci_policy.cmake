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
  "actions/upload-artifact@043fb46d1a93c77aae656e7c1c64a875d1fc6a0a"
  "artifact-validation:"
  "actions/download-artifact@3e5f45b2cfb9172054b4087a40e8e0b5a5461e7c"
  "check_downloaded_artifact.cmake"
  "attestation:"
  "name: artifact-attestation"
  "needs: artifact-validation"
  "id-token: write"
  "attestations: write"
  "actions/attest@f7c74d28b9d84cb8768d0b8ca14a4bac6ef463e6"
  "subject-checksums: attestation-subjects.sha256"
  "attestation-reference:"
  "subject-list-digest:"
  "attestation-verification:"
  "check_release_evidence_verifier.cmake"
  "github.event_name == 'push' || github.event_name == 'workflow_dispatch'"
  "codeql:"
  "ANOSECUREKIT_ENABLE_CODEQL == 'true'"
  "github/codeql-action/init@7188fc363630916deb702c7fdcf4e481b751f97a"
  "github/codeql-action/analyze@7188fc363630916deb702c7fdcf4e481b751f97a"
  "security-events: write"
  "retention-days: 14")

foreach(_term IN LISTS _required_terms)
  string(FIND "${_content}" "${_term}" _position)
  if(_position EQUAL -1)
    message(FATAL_ERROR "Enterprise CI workflow is missing required term: ${_term}")
  endif()
endforeach()

string(REGEX MATCHALL "uses:[^\r\n]+@[A-Za-z0-9._/-]+" _action_uses "${_content}")
foreach(_use IN LISTS _action_uses)
  string(REGEX REPLACE "^.*@" "" _action_revision "${_use}")
  string(LENGTH "${_action_revision}" _action_revision_length)
  if(NOT _action_revision_length EQUAL 40
     OR NOT _action_revision MATCHES "^[0-9a-f]+$")
    message(FATAL_ERROR "Enterprise CI action is not pinned to a full commit SHA: ${_use}")
  endif()
endforeach()

foreach(_permission IN ITEMS "id-token: write" "attestations: write")
  string(REGEX MATCHALL "${_permission}" _permission_matches "${_content}")
  list(LENGTH _permission_matches _permission_count)
  if(NOT _permission_count EQUAL 1)
    message(FATAL_ERROR
      "Enterprise CI must grant '${_permission}' to exactly one job")
  endif()
endforeach()

set(_forbidden_terms
  "softprops/action-gh-release"
  "gh release create"
  "gh release upload"
  "contents: write"
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
