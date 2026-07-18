# SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary
cmake_minimum_required(VERSION 3.20)

if(NOT DEFINED ENTERPRISE_SOURCE_DIR OR ENTERPRISE_SOURCE_DIR STREQUAL "")
  message(FATAL_ERROR "ENTERPRISE_SOURCE_DIR is required")
endif()

set(_documents
  SECURITY.md
  docs/SUPPORT_LIFECYCLE_POLICY.md
  docs/VULNERABILITY_RESPONSE_POLICY.md
  docs/SECURITY_RELEASE_AND_REVOCATION_POLICY.md)
set(_all_content "")
foreach(_document IN LISTS _documents)
  set(_path "${ENTERPRISE_SOURCE_DIR}/${_document}")
  if(NOT EXISTS "${_path}" OR IS_DIRECTORY "${_path}")
    message(FATAL_ERROR "Required support policy document is missing: ${_document}")
  endif()
  file(READ "${_path}" _content)
  string(APPEND _all_content "\n${_content}")
endforeach()

file(READ "${ENTERPRISE_SOURCE_DIR}/README.md" _readme)
foreach(_link IN ITEMS
    "[Security policy](SECURITY.md)"
    "[Support lifecycle policy](docs/SUPPORT_LIFECYCLE_POLICY.md)"
    "[Vulnerability response policy](docs/VULNERABILITY_RESPONSE_POLICY.md)"
    "[Security release and revocation policy](docs/SECURITY_RELEASE_AND_REVOCATION_POLICY.md)")
  string(FIND "${_readme}" "${_link}" _position)
  if(_position EQUAL -1)
    message(FATAL_ERROR "README document index is missing: ${_link}")
  endif()
endforeach()
string(REGEX MATCHALL "\\[[^]]+\\]\\([^)\r\n]+\\)" _readme_links "${_readme}")
foreach(_link IN LISTS _readme_links)
  string(REGEX REPLACE "^.*\\]\\(([^)#]+)(#[^)]*)?\\)$" "\\1" _target "${_link}")
  if(NOT _target MATCHES "^[A-Za-z][A-Za-z0-9+.-]*:"
     AND NOT EXISTS "${ENTERPRISE_SOURCE_DIR}/${_target}")
    message(FATAL_ERROR "README local link target is missing: ${_target}")
  endif()
endforeach()

set(_required_terms
  "lifecycle_status: unsupported"
  "release_stage: pre-release/internal qualification"
  "active_customer_support: false"
  "generally_available: false"
  "production_release: false"
  "customer_release_ready: false"
  "security contact: not yet published"
  "public disclosure channel: not yet activated"
  "supported"
  "maintenance"
  "security-fixes-only"
  "end-of-support"
  "unsupported"
  "critical"
  "high"
  "medium"
  "low"
  "internal operating targets"
  "not a contractual SLA"
  "| OpenSSL provider defect | AnoSecureKit Community |"
  "| Common public API or v1 format defect | AnoSecureKit Community |"
  "| Generic provider seam defect | AnoSecureKit Community |"
  "| Enterprise policy/diagnostics/package/release defect | AnoSecureKit Enterprise |"
  "| AnoCrypto-C adapter defect | AnoSecureKit Enterprise |"
  "| AnoCrypto-C primitive/API/ABI/package defect | AnoCrypto-C |"
  "| Algorithm requirement incompatible with existing v1 formats | Cross-repository format/version review |"
  "release_authorization: denied-or-unavailable"
  "trusted_evidence: unavailable or rejected"
  "Internal delivery artifacts are not customer releases"
  "Enterprise does not patch AnoCrypto-C source"
  "the bundled Community subtree"
  "No KCMVP or FIPS validation is claimed")
foreach(_term IN LISTS _required_terms)
  string(FIND "${_all_content}" "${_term}" _position)
  if(_position EQUAL -1)
    message(FATAL_ERROR "Support policy contract is missing: ${_term}")
  endif()
endforeach()

string(TOLOWER "${_all_content}" _lower_content)
foreach(_claim IN ITEMS
    "customer_release_ready: true"
    "active_customer_support: true"
    "generally_available: true"
    "production_release: true"
    "kcmvp validation: passed"
    "fips validation: passed"
    "is kcmvp validated"
    "is fips validated"
    "contractual sla applies"
    "mailto:")
  string(FIND "${_lower_content}" "${_claim}" _position)
  if(NOT _position EQUAL -1)
    message(FATAL_ERROR "Unsupported support/security claim is forbidden: ${_claim}")
  endif()
endforeach()
if(_all_content MATCHES "[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z][A-Za-z]+")
  message(FATAL_ERROR "Support policy must not invent a security email address")
endif()

message(STATUS "AnoSecureKit Enterprise support policy check passed")
