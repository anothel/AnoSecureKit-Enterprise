# SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary
cmake_minimum_required(VERSION 3.20)

if(NOT DEFINED ROOT OR ROOT STREQUAL "" OR NOT IS_DIRECTORY "${ROOT}")
  message(FATAL_ERROR "ROOT must name an existing delivery directory")
endif()

file(REAL_PATH "${ROOT}" _root)
set(_manifest "${_root}/MANIFEST.sha256")

file(GLOB_RECURSE _files
  LIST_DIRECTORIES false
  RELATIVE "${_root}"
  "${_root}/*")

set(_included)
foreach(_path IN LISTS _files)
  string(REPLACE "\\" "/" _path "${_path}")
  if(_path STREQUAL "MANIFEST.sha256"
      OR _path MATCHES "(^|/)\\.git(/|$)"
      OR _path MATCHES "(^|/)(build[^/]*|cmake-build-[^/]*)(/|$)"
      OR _path MATCHES "(^|/)(\\.idea|\\.vscode|\\.vs)(/|$)"
      OR _path MATCHES "(^|/)(\\.DS_Store|Thumbs\\.db|desktop\\.ini)$"
      OR _path MATCHES "(^|/)[^/]+\\.(tmp|temp|swp|swo|user|suo)$"
      OR _path MATCHES "~$")
    continue()
  endif()
  list(APPEND _included "${_path}")
endforeach()

if(NOT _included)
  message(FATAL_ERROR "No delivery files found under ${_root}")
endif()

list(SORT _included)
set(_content "")
foreach(_path IN LISTS _included)
  set(_file "${_root}/${_path}")
  if(NOT EXISTS "${_file}" OR IS_DIRECTORY "${_file}")
    message(FATAL_ERROR "Delivery file is missing or unreadable: ${_path}")
  endif()
  file(SHA256 "${_file}" _hash)
  string(APPEND _content "${_hash}  ${_path}\n")
endforeach()

file(WRITE "${_manifest}.tmp" "${_content}")
file(RENAME "${_manifest}.tmp" "${_manifest}")
message(STATUS "Generated ${_manifest}")
