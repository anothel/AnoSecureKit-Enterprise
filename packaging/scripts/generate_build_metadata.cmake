# SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary
cmake_minimum_required(VERSION 3.20)

foreach(_required IN ITEMS OUTPUT ENTERPRISE_VERSION COMMUNITY_VERSION PROFILE)
  if(NOT DEFINED ${_required} OR "${${_required}}" STREQUAL "")
    message(FATAL_ERROR "${_required} is required")
  endif()
endforeach()

get_filename_component(_output_dir "${OUTPUT}" DIRECTORY)
file(MAKE_DIRECTORY "${_output_dir}")

foreach(_optional IN ITEMS BUILD_CONFIG SYSTEM_NAME SYSTEM_PROCESSOR COMPILER_ID COMPILER_VERSION SOURCE_REVISION)
  if(NOT DEFINED ${_optional} OR "${${_optional}}" STREQUAL "")
    set(${_optional} "not-recorded")
  endif()
endforeach()

set(_content
"AnoSecureKit Enterprise delivery metadata\n"
"enterprise_version=${ENTERPRISE_VERSION}\n"
"community_version=${COMMUNITY_VERSION}\n"
"backend_profile=${PROFILE}\n"
"build_config=${BUILD_CONFIG}\n"
"system_name=${SYSTEM_NAME}\n"
"system_processor=${SYSTEM_PROCESSOR}\n"
"compiler_id=${COMPILER_ID}\n"
"compiler_version=${COMPILER_VERSION}\n"
"source_revision=${SOURCE_REVISION}\n"
"authenticity_note=Checksums and this metadata do not authenticate the publisher.\n")
file(WRITE "${OUTPUT}.tmp" "${_content}")
file(RENAME "${OUTPUT}.tmp" "${OUTPUT}")
message(STATUS "Generated ${OUTPUT}")
