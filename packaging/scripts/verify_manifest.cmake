# SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary
cmake_minimum_required(VERSION 3.20)

if(NOT DEFINED ROOT OR ROOT STREQUAL "" OR NOT IS_DIRECTORY "${ROOT}")
  message(FATAL_ERROR "ROOT must name an existing delivery directory")
endif()

file(REAL_PATH "${ROOT}" _root)
set(_manifest "${_root}/MANIFEST.sha256")
if(NOT EXISTS "${_manifest}")
  message(FATAL_ERROR "Missing manifest: ${_manifest}")
endif()

file(STRINGS "${_manifest}" _lines ENCODING UTF-8)
if(NOT _lines)
  message(FATAL_ERROR "Manifest is empty: ${_manifest}")
endif()

set(_paths)
foreach(_line IN LISTS _lines)
  string(REGEX MATCH "^([0-9a-f]+)  (.+)$" _match "${_line}")
  if(NOT _match)
    message(FATAL_ERROR "Malformed manifest entry: ${_line}")
  endif()

  set(_expected "${CMAKE_MATCH_1}")
  set(_path "${CMAKE_MATCH_2}")
  string(LENGTH "${_expected}" _hash_length)
  if(NOT _hash_length EQUAL 64)
    message(FATAL_ERROR "Invalid SHA-256 value for ${_path}")
  endif()
  if(_path STREQUAL "MANIFEST.sha256"
      OR _path MATCHES "\\\\"
      OR _path MATCHES "^/"
      OR _path MATCHES "^[A-Za-z]:"
      OR _path MATCHES "(^|/)\\.\\.(/|$)")
    message(FATAL_ERROR "Manifest path is not normalized and relative: ${_path}")
  endif()

  list(FIND _paths "${_path}" _duplicate)
  if(NOT _duplicate EQUAL -1)
    message(FATAL_ERROR "Duplicate manifest path: ${_path}")
  endif()
  list(APPEND _paths "${_path}")

  set(_file "${_root}/${_path}")
  if(NOT EXISTS "${_file}" OR IS_DIRECTORY "${_file}")
    message(FATAL_ERROR "Missing delivery file: ${_path}")
  endif()
  file(SHA256 "${_file}" _actual)
  if(NOT _actual STREQUAL _expected)
    message(FATAL_ERROR "Checksum mismatch: ${_path}")
  endif()
endforeach()

set(_sorted "${_paths}")
list(SORT _sorted)
if(NOT "${_paths}" STREQUAL "${_sorted}")
  message(FATAL_ERROR "Manifest entries are not sorted")
endif()

message(STATUS "Verified ${_manifest}")
