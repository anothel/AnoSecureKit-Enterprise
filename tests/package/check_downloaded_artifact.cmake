# SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary
cmake_minimum_required(VERSION 3.20)

foreach(_required IN ITEMS ENTERPRISE_SOURCE_DIR ARTIFACT_DIR WORK_DIR EXPECTED_SOURCE_REVISION)
  if(NOT DEFINED ${_required} OR "${${_required}}" STREQUAL "")
    message(FATAL_ERROR "${_required} is required")
  endif()
endforeach()
if(NOT IS_DIRECTORY "${ENTERPRISE_SOURCE_DIR}" OR NOT IS_DIRECTORY "${ARTIFACT_DIR}")
  message(FATAL_ERROR "ENTERPRISE_SOURCE_DIR and ARTIFACT_DIR must be existing directories")
endif()
string(LENGTH "${EXPECTED_SOURCE_REVISION}" _revision_length)
if(NOT _revision_length EQUAL 40 OR NOT EXPECTED_SOURCE_REVISION MATCHES "^[0-9a-f]+$")
  message(FATAL_ERROR "EXPECTED_SOURCE_REVISION must be a full lowercase Git SHA")
endif()

file(REAL_PATH "${ENTERPRISE_SOURCE_DIR}" _source)
file(REAL_PATH "${ARTIFACT_DIR}" _artifact)
file(MAKE_DIRECTORY "${WORK_DIR}")
file(REAL_PATH "${WORK_DIR}" _work)
if(_work STREQUAL _source OR _work STREQUAL _artifact)
  message(FATAL_ERROR "WORK_DIR must be separate from source and artifact directories")
endif()

execute_process(
  COMMAND "${CMAKE_COMMAND}" -DROOT=${_artifact}
    -P "${_source}/packaging/scripts/verify_sha256sums.cmake"
  RESULT_VARIABLE _checksum_result)
if(NOT _checksum_result EQUAL 0)
  message(FATAL_ERROR "Downloaded artifact checksum verification failed")
endif()

file(READ "${_artifact}/BUILD_METADATA.txt" _metadata)
string(REGEX MATCH
  "(^|\n);?source_revision=${EXPECTED_SOURCE_REVISION}(\r?\n|$)"
  _revision_line "${_metadata}")
if(NOT _revision_line)
  message(FATAL_ERROR "Artifact source revision does not match ${EXPECTED_SOURCE_REVISION}")
endif()
foreach(_metadata_term IN ITEMS
    "evidence_bundle=present"
    "structural_evidence=unavailable"
    "cryptographic_evidence=unavailable"
    "trusted_evidence=unavailable"
    "release_authorization=denied-or-unavailable"
    "customer_release_ready=false")
  string(FIND "${_metadata}" "${_metadata_term}" _metadata_position)
  if(_metadata_position EQUAL -1)
    message(FATAL_ERROR "Artifact metadata is missing ${_metadata_term}")
  endif()
endforeach()

file(STRINGS "${_artifact}/SHA256SUMS.txt" _checksum_lines)
file(GLOB _assets LIST_DIRECTORIES false RELATIVE "${_artifact}" "${_artifact}/*")
list(FILTER _assets EXCLUDE REGEX "^SHA256SUMS\\.txt$")
list(LENGTH _checksum_lines _checksum_count)
list(LENGTH _assets _asset_count)
if(NOT _checksum_count EQUAL _asset_count)
  message(FATAL_ERROR "SHA256SUMS.txt does not cover every downloaded asset")
endif()

file(GLOB _sbom_files LIST_DIRECTORIES false "${_artifact}/*.spdx.json")
list(LENGTH _sbom_files _sbom_count)
if(NOT _sbom_count EQUAL 1)
  message(FATAL_ERROR "Downloaded artifact must contain exactly one SPDX SBOM")
endif()
list(GET _sbom_files 0 _sbom_file)
file(READ "${_sbom_file}" _sbom)
string(JSON _spdx_version ERROR_VARIABLE _spdx_error GET "${_sbom}" spdxVersion)
if(_spdx_error OR NOT _spdx_version STREQUAL "SPDX-2.3")
  message(FATAL_ERROR "Downloaded SBOM is not valid SPDX 2.3 JSON: ${_spdx_error}")
endif()

set(_required_packages "AnoSecureKit Enterprise" "AnoSecureKit Community" "OpenSSL")
string(JSON _package_count ERROR_VARIABLE _package_error LENGTH "${_sbom}" packages)
if(_package_error OR NOT _package_count EQUAL 3)
  message(FATAL_ERROR "Downloaded SBOM package inventory is invalid")
endif()
math(EXPR _package_last "${_package_count} - 1")
set(_packages)
foreach(_index RANGE 0 ${_package_last})
  string(JSON _package_name GET "${_sbom}" packages ${_index} name)
  list(APPEND _packages "${_package_name}")
endforeach()
foreach(_required_package IN LISTS _required_packages)
  if(NOT _required_package IN_LIST _packages)
    message(FATAL_ERROR "Downloaded SBOM omits ${_required_package}")
  endif()
endforeach()

string(JSON _file_count ERROR_VARIABLE _file_error LENGTH "${_sbom}" files)
if(_file_error OR _file_count LESS 1)
  message(FATAL_ERROR "Downloaded SBOM file inventory is invalid")
endif()
math(EXPR _file_last "${_file_count} - 1")
set(_sbom_paths)
foreach(_index RANGE 0 ${_file_last})
  string(JSON _path GET "${_sbom}" files ${_index} fileName)
  string(JSON _algorithm GET "${_sbom}" files ${_index} checksums 0 algorithm)
  string(JSON _expected_hash GET "${_sbom}" files ${_index} checksums 0 checksumValue)
  if(NOT _path MATCHES "^\\./" OR _path MATCHES "(^|/)\\.\\.(/|$)"
     OR _path MATCHES "\\\\"
     OR NOT _algorithm STREQUAL "SHA256")
    message(FATAL_ERROR "Downloaded SBOM contains an unsafe path or checksum: ${_path}")
  endif()
  string(REGEX REPLACE "^\\./" "" _path "${_path}")
  if(_path IN_LIST _sbom_paths OR NOT EXISTS "${_artifact}/${_path}")
    message(FATAL_ERROR "Downloaded SBOM path is duplicate or missing: ${_path}")
  endif()
  list(APPEND _sbom_paths "${_path}")
  file(SHA256 "${_artifact}/${_path}" _actual_hash)
  if(NOT _actual_hash STREQUAL _expected_hash)
    message(FATAL_ERROR "Downloaded SBOM checksum mismatch: ${_path}")
  endif()
endforeach()

file(GLOB _binary_archives LIST_DIRECTORIES false
  "${_artifact}/anosecurekit-enterprise-*-openssl-*.zip"
  "${_artifact}/anosecurekit-enterprise-*-openssl-*.tar.gz")
list(LENGTH _binary_archives _archive_count)
if(NOT _archive_count EQUAL 2)
  message(FATAL_ERROR "Downloaded artifact must contain ZIP and TGZ Enterprise archives")
endif()
foreach(_archive IN LISTS _binary_archives)
  get_filename_component(_archive_name "${_archive}" NAME)
  execute_process(
    COMMAND "${CMAKE_COMMAND}" -E tar tf "${_archive}"
    RESULT_VARIABLE _list_result
    OUTPUT_VARIABLE _archive_entries)
  if(NOT _list_result EQUAL 0)
    message(FATAL_ERROR "Could not list downloaded archive: ${_archive_name}")
  endif()
  string(REPLACE "\r" "" _archive_entries "${_archive_entries}")
  string(REPLACE "\n" ";" _archive_entries "${_archive_entries}")
  foreach(_entry IN LISTS _archive_entries)
    if(_entry MATCHES "^/" OR _entry MATCHES "^[A-Za-z]:"
       OR _entry MATCHES "(^|/)\\.\\.(/|$)" OR _entry MATCHES "\\\\")
      message(FATAL_ERROR "Downloaded archive contains an unsafe path: ${_entry}")
    endif()
  endforeach()
  set(_extract "${_work}/${_archive_name}")
  file(MAKE_DIRECTORY "${_extract}")
  execute_process(
    COMMAND "${CMAKE_COMMAND}" -E tar xf "${_archive}"
    WORKING_DIRECTORY "${_extract}"
    RESULT_VARIABLE _extract_result)
  if(NOT _extract_result EQUAL 0)
    message(FATAL_ERROR "Could not extract downloaded archive: ${_archive_name}")
  endif()
  file(GLOB_RECURSE _manifests LIST_DIRECTORIES false "${_extract}/*/MANIFEST.sha256")
  list(LENGTH _manifests _manifest_count)
  if(NOT _manifest_count EQUAL 1)
    message(FATAL_ERROR "Downloaded archive must contain exactly one manifest: ${_archive_name}")
  endif()
  list(GET _manifests 0 _manifest)
  get_filename_component(_manifest_root "${_manifest}" DIRECTORY)
  execute_process(
    COMMAND "${CMAKE_COMMAND}" -DROOT=${_manifest_root}
      -P "${_source}/packaging/scripts/verify_manifest.cmake"
    RESULT_VARIABLE _manifest_result)
  if(NOT _manifest_result EQUAL 0)
    message(FATAL_ERROR "Downloaded archive manifest verification failed: ${_archive_name}")
  endif()
  file(STRINGS "${_manifest}" _manifest_lines)
  file(GLOB_RECURSE _installed_files LIST_DIRECTORIES false
    RELATIVE "${_manifest_root}" "${_manifest_root}/*")
  list(FILTER _installed_files EXCLUDE REGEX "^MANIFEST\\.sha256$")
  list(LENGTH _manifest_lines _manifest_entry_count)
  list(LENGTH _installed_files _installed_file_count)
  if(NOT _manifest_entry_count EQUAL _installed_file_count)
    message(FATAL_ERROR "Downloaded archive manifest does not cover every file: ${_archive_name}")
  endif()
endforeach()

file(GLOB _source_offers LIST_DIRECTORIES false
  "${_artifact}/anosecurekit-community-*-source-offer.zip")
list(LENGTH _source_offers _offer_count)
if(NOT _offer_count EQUAL 1)
  message(FATAL_ERROR "Downloaded artifact must contain one Community source offer")
endif()
list(GET _source_offers 0 _source_offer)
set(_offer_extract "${_work}/community-source-offer")
file(MAKE_DIRECTORY "${_offer_extract}")
execute_process(
  COMMAND "${CMAKE_COMMAND}" -E tar tf "${_source_offer}"
  RESULT_VARIABLE _offer_list_result
  OUTPUT_VARIABLE _offer_entries)
if(NOT _offer_list_result EQUAL 0)
  message(FATAL_ERROR "Could not list downloaded Community source offer")
endif()
string(REPLACE "\r" "" _offer_entries "${_offer_entries}")
string(REPLACE "\n" ";" _offer_entries "${_offer_entries}")
foreach(_entry IN LISTS _offer_entries)
  if(_entry MATCHES "^/" OR _entry MATCHES "^[A-Za-z]:"
     OR _entry MATCHES "(^|/)\\.\\.(/|$)" OR _entry MATCHES "\\\\")
    message(FATAL_ERROR "Downloaded Community source offer contains an unsafe path: ${_entry}")
  endif()
endforeach()
execute_process(
  COMMAND "${CMAKE_COMMAND}" -E tar xf "${_source_offer}"
  WORKING_DIRECTORY "${_offer_extract}"
  RESULT_VARIABLE _offer_extract_result)
if(NOT _offer_extract_result EQUAL 0)
  message(FATAL_ERROR "Could not extract downloaded Community source offer")
endif()
file(GLOB _offer_roots LIST_DIRECTORIES true "${_offer_extract}/anosecurekit-community-*")
list(LENGTH _offer_roots _offer_root_count)
if(NOT _offer_root_count EQUAL 1 OR NOT IS_DIRECTORY "${_offer_roots}")
  message(FATAL_ERROR "Downloaded Community source offer root is invalid")
endif()
list(GET _offer_roots 0 _offer_root)
set(_community "${_source}/third_party/anosecurekit-community")
file(GLOB_RECURSE _community_files LIST_DIRECTORIES false RELATIVE "${_community}" "${_community}/*")
file(GLOB_RECURSE _offered_files LIST_DIRECTORIES false RELATIVE "${_offer_root}" "${_offer_root}/*")
list(SORT _community_files)
list(SORT _offered_files)
if(NOT "${_community_files}" STREQUAL "${_offered_files}")
  message(FATAL_ERROR "Downloaded Community source offer inventory differs from bundled subtree")
endif()
foreach(_path IN LISTS _community_files)
  file(SHA256 "${_community}/${_path}" _community_hash)
  file(SHA256 "${_offer_root}/${_path}" _offered_hash)
  if(NOT _community_hash STREQUAL _offered_hash)
    message(FATAL_ERROR "Downloaded Community source offer mismatch: ${_path}")
  endif()
endforeach()

message(STATUS
  "Downloaded artifact passed checksum, SBOM, manifest, revision, and Community subtree verification")
