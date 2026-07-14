# SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary
cmake_minimum_required(VERSION 3.20)

foreach(_required IN ITEMS
    ENTERPRISE_SOURCE_DIR
    ENTERPRISE_BUILD_DIR
    ENTERPRISE_DELIVERY_ROOT
    ENTERPRISE_PROJECT_VERSION
    ENTERPRISE_COMMUNITY_VERSION
    ENTERPRISE_CPACK_COMMAND)
  if(NOT DEFINED ${_required} OR "${${_required}}" STREQUAL "")
    message(FATAL_ERROR "${_required} is required")
  endif()
endforeach()
if(NOT EXISTS "${ENTERPRISE_BUILD_DIR}/cmake_install.cmake")
  message(FATAL_ERROR "ENTERPRISE_BUILD_DIR is not a configured Enterprise build")
endif()
if(NOT EXISTS "${ENTERPRISE_CPACK_COMMAND}")
  message(FATAL_ERROR "ENTERPRISE_CPACK_COMMAND does not exist: ${ENTERPRISE_CPACK_COMMAND}")
endif()

foreach(_optional IN ITEMS
    ENTERPRISE_BUILD_CONFIG
    ENTERPRISE_DEFAULT_BUILD_TYPE
    ENTERPRISE_GENERATOR
    ENTERPRISE_CMAKE_MAKE_PROGRAM
    ENTERPRISE_CXX_COMPILER
    ENTERPRISE_COMPILER_ID
    ENTERPRISE_COMPILER_VERSION
    ENTERPRISE_SYSTEM_NAME
    ENTERPRISE_SYSTEM_PROCESSOR
    ENTERPRISE_SOURCE_REVISION)
  if(NOT DEFINED ${_optional} OR "${${_optional}}" STREQUAL "")
    set(${_optional} "not-recorded")
  endif()
endforeach()
if(ENTERPRISE_SYSTEM_NAME STREQUAL "not-recorded")
  set(ENTERPRISE_SYSTEM_NAME "UnknownSystem")
endif()
if(ENTERPRISE_SYSTEM_PROCESSOR STREQUAL "not-recorded")
  set(ENTERPRISE_SYSTEM_PROCESSOR "unknown-processor")
endif()

file(REMOVE_RECURSE "${ENTERPRISE_DELIVERY_ROOT}")
file(MAKE_DIRECTORY "${ENTERPRISE_DELIVERY_ROOT}")
set(_stage "${ENTERPRISE_DELIVERY_ROOT}/stage")
set(_cpack_build "${ENTERPRISE_DELIVERY_ROOT}/cpack-build")
set(_package_output "${ENTERPRISE_DELIVERY_ROOT}/packages")
set(_delivery "${ENTERPRISE_DELIVERY_ROOT}/delivery")
set(_extract_root "${ENTERPRISE_DELIVERY_ROOT}/extract")
file(MAKE_DIRECTORY "${_stage}" "${_package_output}" "${_delivery}" "${_extract_root}")

set(_config_args "")
if(NOT ENTERPRISE_BUILD_CONFIG STREQUAL "not-recorded")
  list(APPEND _config_args --config "${ENTERPRISE_BUILD_CONFIG}")
endif()
execute_process(
  COMMAND "${CMAKE_COMMAND}" --install "${ENTERPRISE_BUILD_DIR}"
    ${_config_args} --prefix "${_stage}"
  RESULT_VARIABLE _install_result
  OUTPUT_VARIABLE _install_out
  ERROR_VARIABLE _install_err)
if(NOT _install_result EQUAL 0)
  string(CONCAT _log "${_install_out}" "${_install_err}")
  message(FATAL_ERROR "Delivery staged install failed\n${_log}")
endif()

set(_enterprise_share "${_stage}/share/anosecurekit-enterprise")
file(MAKE_DIRECTORY "${_enterprise_share}")
file(COPY "${ENTERPRISE_BUILD_DIR}/DELIVERY_README.md"
  DESTINATION "${_enterprise_share}")
execute_process(
  COMMAND "${CMAKE_COMMAND}"
    -DOUTPUT=${_enterprise_share}/BUILD_METADATA.txt
    -DENTERPRISE_VERSION=${ENTERPRISE_PROJECT_VERSION}
    -DCOMMUNITY_VERSION=${ENTERPRISE_COMMUNITY_VERSION}
    -DPROFILE=openssl
    -DBUILD_CONFIG=${ENTERPRISE_BUILD_CONFIG}
    -DSYSTEM_NAME=${ENTERPRISE_SYSTEM_NAME}
    -DSYSTEM_PROCESSOR=${ENTERPRISE_SYSTEM_PROCESSOR}
    -DCOMPILER_ID=${ENTERPRISE_COMPILER_ID}
    -DCOMPILER_VERSION=${ENTERPRISE_COMPILER_VERSION}
    -DSOURCE_REVISION=${ENTERPRISE_SOURCE_REVISION}
    -P "${ENTERPRISE_SOURCE_DIR}/packaging/scripts/generate_build_metadata.cmake"
  RESULT_VARIABLE _metadata_result)
if(NOT _metadata_result EQUAL 0)
  message(FATAL_ERROR "Failed to generate delivery build metadata")
endif()

execute_process(
  COMMAND "${CMAKE_COMMAND}" -DROOT=${_stage}
    -P "${ENTERPRISE_SOURCE_DIR}/packaging/scripts/generate_manifest.cmake"
  RESULT_VARIABLE _manifest_result)
if(NOT _manifest_result EQUAL 0)
  message(FATAL_ERROR "Failed to generate staged delivery manifest")
endif()
execute_process(
  COMMAND "${CMAKE_COMMAND}" -DROOT=${_stage}
    -P "${ENTERPRISE_SOURCE_DIR}/packaging/scripts/verify_manifest.cmake"
  RESULT_VARIABLE _manifest_verify_result)
if(NOT _manifest_verify_result EQUAL 0)
  message(FATAL_ERROR "Failed to verify staged delivery manifest")
endif()

set(_cpack_configure
  "${CMAKE_COMMAND}"
  -S "${ENTERPRISE_SOURCE_DIR}/packaging/cpack"
  -B "${_cpack_build}"
  "-DDELIVERY_ROOT=${_stage}"
  "-DENTERPRISE_VERSION=${ENTERPRISE_PROJECT_VERSION}"
  "-DBACKEND_PROFILE=openssl"
  "-DDELIVERY_SYSTEM_NAME=${ENTERPRISE_SYSTEM_NAME}"
  "-DDELIVERY_SYSTEM_PROCESSOR=${ENTERPRISE_SYSTEM_PROCESSOR}")
if(NOT ENTERPRISE_GENERATOR STREQUAL "not-recorded")
  list(APPEND _cpack_configure -G "${ENTERPRISE_GENERATOR}")
endif()
if(NOT ENTERPRISE_CMAKE_MAKE_PROGRAM STREQUAL "not-recorded")
  list(APPEND _cpack_configure
    "-DCMAKE_MAKE_PROGRAM=${ENTERPRISE_CMAKE_MAKE_PROGRAM}")
endif()
execute_process(
  COMMAND ${_cpack_configure}
  RESULT_VARIABLE _cpack_configure_result
  OUTPUT_VARIABLE _cpack_configure_out
  ERROR_VARIABLE _cpack_configure_err)
if(NOT _cpack_configure_result EQUAL 0)
  string(CONCAT _log "${_cpack_configure_out}" "${_cpack_configure_err}")
  message(FATAL_ERROR "Delivery CPack project configuration failed\n${_log}")
endif()

foreach(_generator IN ITEMS ZIP TGZ)
  execute_process(
    COMMAND "${ENTERPRISE_CPACK_COMMAND}" -G "${_generator}"
      --config "${_cpack_build}/CPackConfig.cmake"
      -B "${_package_output}"
    RESULT_VARIABLE _cpack_result
    OUTPUT_VARIABLE _cpack_out
    ERROR_VARIABLE _cpack_err)
  if(NOT _cpack_result EQUAL 0)
    string(CONCAT _log "${_cpack_out}" "${_cpack_err}")
    message(FATAL_ERROR "CPack ${_generator} delivery generation failed\n${_log}")
  endif()
endforeach()

file(GLOB _binary_archives LIST_DIRECTORIES false
  "${_package_output}/anosecurekit-enterprise-${ENTERPRISE_PROJECT_VERSION}-openssl-*.zip"
  "${_package_output}/anosecurekit-enterprise-${ENTERPRISE_PROJECT_VERSION}-openssl-*.tar.gz")
list(LENGTH _binary_archives _binary_archive_count)
if(NOT _binary_archive_count EQUAL 2)
  message(FATAL_ERROR
    "Expected exactly two Enterprise binary archives, found ${_binary_archive_count}: ${_binary_archives}")
endif()
foreach(_archive IN LISTS _binary_archives)
  file(COPY "${_archive}" DESTINATION "${_delivery}")
endforeach()

set(_community_source_stage "${ENTERPRISE_DELIVERY_ROOT}/community-source")
set(_community_source_dir
  "${_community_source_stage}/anosecurekit-community-${ENTERPRISE_COMMUNITY_VERSION}")
file(MAKE_DIRECTORY "${_community_source_dir}")
file(COPY "${ENTERPRISE_SOURCE_DIR}/third_party/anosecurekit-community/"
  DESTINATION "${_community_source_dir}")
set(_community_offer_name
  "anosecurekit-community-${ENTERPRISE_COMMUNITY_VERSION}-source-offer.zip")
execute_process(
  COMMAND "${CMAKE_COMMAND}" -E tar cf
    "${_delivery}/${_community_offer_name}" --format=zip
    "anosecurekit-community-${ENTERPRISE_COMMUNITY_VERSION}"
  WORKING_DIRECTORY "${_community_source_stage}"
  RESULT_VARIABLE _source_offer_result
  OUTPUT_VARIABLE _source_offer_out
  ERROR_VARIABLE _source_offer_err)
if(NOT _source_offer_result EQUAL 0)
  string(CONCAT _log "${_source_offer_out}" "${_source_offer_err}")
  message(FATAL_ERROR "Community source-offer archive generation failed\n${_log}")
endif()

file(COPY
  "${ENTERPRISE_SOURCE_DIR}/LICENSE"
  "${ENTERPRISE_SOURCE_DIR}/THIRD_PARTY_NOTICES.md"
  "${ENTERPRISE_SOURCE_DIR}/docs/COMMUNITY_DEPENDENCY.md"
  "${ENTERPRISE_BUILD_DIR}/DELIVERY_README.md"
  "${_enterprise_share}/BUILD_METADATA.txt"
  DESTINATION "${_delivery}")

set(_sbom_name
  "anosecurekit-enterprise-${ENTERPRISE_PROJECT_VERSION}-openssl-delivery.spdx.json")
execute_process(
  COMMAND "${CMAKE_COMMAND}"
    -DROOT=${_delivery}
    -DOUTPUT=${_delivery}/${_sbom_name}
    -DENTERPRISE_VERSION=${ENTERPRISE_PROJECT_VERSION}
    -DCOMMUNITY_VERSION=${ENTERPRISE_COMMUNITY_VERSION}
    -DPROFILE=openssl
    -P "${ENTERPRISE_SOURCE_DIR}/packaging/scripts/generate_delivery_sbom.cmake"
  RESULT_VARIABLE _sbom_result)
if(NOT _sbom_result EQUAL 0)
  message(FATAL_ERROR "Delivery SPDX SBOM generation failed")
endif()

execute_process(
  COMMAND "${CMAKE_COMMAND}" -DROOT=${_delivery}
    -P "${ENTERPRISE_SOURCE_DIR}/packaging/scripts/generate_sha256sums.cmake"
  RESULT_VARIABLE _checksums_result)
if(NOT _checksums_result EQUAL 0)
  message(FATAL_ERROR "Delivery checksum generation failed")
endif()
execute_process(
  COMMAND "${CMAKE_COMMAND}" -DROOT=${_delivery}
    -P "${ENTERPRISE_SOURCE_DIR}/packaging/scripts/verify_sha256sums.cmake"
  RESULT_VARIABLE _checksums_verify_result)
if(NOT _checksums_verify_result EQUAL 0)
  message(FATAL_ERROR "Delivery checksum verification failed")
endif()

file(READ "${_delivery}/${_sbom_name}" _sbom_json)
string(JSON _spdx_version ERROR_VARIABLE _sbom_error GET "${_sbom_json}" spdxVersion)
if(_sbom_error OR NOT _spdx_version STREQUAL "SPDX-2.3")
  message(FATAL_ERROR "Generated delivery SBOM is not valid SPDX 2.3 JSON: ${_sbom_error}")
endif()
string(JSON _namespace ERROR_VARIABLE _namespace_error GET "${_sbom_json}" documentNamespace)
if(_namespace_error OR NOT _namespace MATCHES "^urn:uuid:")
  message(FATAL_ERROR "Generated delivery SBOM namespace is invalid: ${_namespace_error}")
endif()
string(JSON _package_count ERROR_VARIABLE _package_count_error LENGTH "${_sbom_json}" packages)
if(_package_count_error OR NOT _package_count EQUAL 3)
  message(FATAL_ERROR "Generated delivery SBOM must describe Enterprise, Community, and OpenSSL")
endif()
string(JSON _enterprise_package_name ERROR_VARIABLE _enterprise_package_error
  GET "${_sbom_json}" packages 0 name)
string(JSON _community_package_name ERROR_VARIABLE _community_package_error
  GET "${_sbom_json}" packages 1 name)
string(JSON _openssl_package_name ERROR_VARIABLE _openssl_package_error
  GET "${_sbom_json}" packages 2 name)
if(_enterprise_package_error OR _community_package_error OR _openssl_package_error
   OR NOT _enterprise_package_name STREQUAL "AnoSecureKit Enterprise"
   OR NOT _community_package_name STREQUAL "AnoSecureKit Community"
   OR NOT _openssl_package_name STREQUAL "OpenSSL")
  message(FATAL_ERROR "Generated delivery SBOM package inventory is invalid")
endif()

foreach(_archive IN LISTS _binary_archives)
  get_filename_component(_archive_name "${_archive}" NAME)
  set(_extract_dir "${_extract_root}/${_archive_name}")
  file(MAKE_DIRECTORY "${_extract_dir}")
  execute_process(
    COMMAND "${CMAKE_COMMAND}" -E tar xf "${_delivery}/${_archive_name}"
    WORKING_DIRECTORY "${_extract_dir}"
    RESULT_VARIABLE _extract_result
    OUTPUT_VARIABLE _extract_out
    ERROR_VARIABLE _extract_err)
  if(NOT _extract_result EQUAL 0)
    string(CONCAT _log "${_extract_out}" "${_extract_err}")
    message(FATAL_ERROR "Failed to extract Enterprise archive ${_archive_name}\n${_log}")
  endif()

  file(GLOB_RECURSE _required_enterprise_header
    "${_extract_dir}/*/include/anosecurekit_enterprise/enterprise.hpp")
  file(GLOB_RECURSE _required_community_header
    "${_extract_dir}/*/include/anosecurekit/anosecurekit.hpp")
  file(GLOB_RECURSE _required_enterprise_config
    "${_extract_dir}/*/anosecurekitEnterpriseConfig.cmake")
  file(GLOB_RECURSE _required_community_config
    "${_extract_dir}/*/anosecurekitConfig.cmake")
  file(GLOB_RECURSE _required_manifest
    "${_extract_dir}/*/MANIFEST.sha256")
  file(GLOB_RECURSE _required_metadata
    "${_extract_dir}/*/share/anosecurekit-enterprise/BUILD_METADATA.txt")
  file(GLOB_RECURSE _required_delivery_readme
    "${_extract_dir}/*/share/anosecurekit-enterprise/DELIVERY_README.md")
  foreach(_found IN ITEMS
      _required_enterprise_header
      _required_community_header
      _required_enterprise_config
      _required_community_config
      _required_manifest
      _required_metadata
      _required_delivery_readme)
    if(NOT ${_found})
      message(FATAL_ERROR "Extracted Enterprise archive ${_archive_name} is missing ${_found}")
    endif()
  endforeach()

  list(GET _required_manifest 0 _manifest_path)
  get_filename_component(_manifest_root "${_manifest_path}" DIRECTORY)
  execute_process(
    COMMAND "${CMAKE_COMMAND}" -DROOT=${_manifest_root}
      -P "${ENTERPRISE_SOURCE_DIR}/packaging/scripts/verify_manifest.cmake"
    RESULT_VARIABLE _archive_manifest_result)
  if(NOT _archive_manifest_result EQUAL 0)
    message(FATAL_ERROR "Extracted Enterprise archive manifest verification failed: ${_archive_name}")
  endif()

  file(GLOB_RECURSE _private_runtime_header
    "${_extract_dir}/*/include/anosecurekit_enterprise/detail/provider_runtime_contract.hpp")
  if(_private_runtime_header)
    message(FATAL_ERROR "Customer archive exposes private provider runtime contract header")
  endif()
  file(GLOB_RECURSE _enterprise_sources
    "${_extract_dir}/*/src/*.cpp"
    "${_extract_dir}/*/src/*.c"
    "${_extract_dir}/*/tests/*.cpp")
  if(_enterprise_sources)
    message(FATAL_ERROR "Customer binary archive contains implementation/test sources: ${_enterprise_sources}")
  endif()
  file(GLOB_RECURSE _anocrypto_payload
    "${_extract_dir}/*/include/anocrypto/*"
    "${_extract_dir}/*/*anocrypto_c*"
    "${_extract_dir}/*/*AnoCryptoC*")
  if(_anocrypto_payload)
    message(FATAL_ERROR "OpenSSL delivery archive contains AnoCrypto-C payload: ${_anocrypto_payload}")
  endif()
endforeach()

set(_source_extract "${_extract_root}/community-source-offer")
file(MAKE_DIRECTORY "${_source_extract}")
execute_process(
  COMMAND "${CMAKE_COMMAND}" -E tar xf "${_delivery}/${_community_offer_name}"
  WORKING_DIRECTORY "${_source_extract}"
  RESULT_VARIABLE _source_extract_result
  OUTPUT_VARIABLE _source_extract_out
  ERROR_VARIABLE _source_extract_err)
if(NOT _source_extract_result EQUAL 0)
  string(CONCAT _log "${_source_extract_out}" "${_source_extract_err}")
  message(FATAL_ERROR "Community source-offer extraction failed\n${_log}")
endif()
set(_community_root
  "${_source_extract}/anosecurekit-community-${ENTERPRISE_COMMUNITY_VERSION}")
if(NOT EXISTS "${_community_root}/CMakeLists.txt"
   OR NOT EXISTS "${_community_root}/LICENSE"
   OR NOT EXISTS "${_community_root}/include/anosecurekit/anosecurekit.hpp")
  message(FATAL_ERROR "Community source-offer archive is incomplete")
endif()
file(READ "${_community_root}/CMakeLists.txt" _community_cmake)
if(NOT _community_cmake MATCHES "VERSION[ \t\r\n]+${ENTERPRISE_COMMUNITY_VERSION}")
  message(FATAL_ERROR "Community source-offer version does not match ${ENTERPRISE_COMMUNITY_VERSION}")
endif()
file(READ "${_community_root}/LICENSE" _community_license)
if(NOT _community_license MATCHES "Mozilla Public License")
  message(FATAL_ERROR "Community source-offer does not preserve the MPL-2.0 license")
endif()
file(GLOB_RECURSE _enterprise_in_source_offer
  "${_community_root}/*anosecurekit_enterprise*"
  "${_community_root}/*AnoSecureKit-Enterprise*")
if(_enterprise_in_source_offer)
  message(FATAL_ERROR "Community source-offer contains Enterprise-owned files")
endif()

file(GLOB_RECURSE _original_community_files
  LIST_DIRECTORIES false
  RELATIVE "${ENTERPRISE_SOURCE_DIR}/third_party/anosecurekit-community"
  "${ENTERPRISE_SOURCE_DIR}/third_party/anosecurekit-community/*")
file(GLOB_RECURSE _offered_community_files
  LIST_DIRECTORIES false
  RELATIVE "${_community_root}"
  "${_community_root}/*")
list(SORT _original_community_files)
list(SORT _offered_community_files)
if(NOT "${_original_community_files}" STREQUAL "${_offered_community_files}")
  message(FATAL_ERROR "Community source-offer file inventory differs from the bundled source tree")
endif()
foreach(_path IN LISTS _original_community_files)
  file(SHA256
    "${ENTERPRISE_SOURCE_DIR}/third_party/anosecurekit-community/${_path}"
    _original_hash)
  file(SHA256 "${_community_root}/${_path}" _offered_hash)
  if(NOT _original_hash STREQUAL _offered_hash)
    message(FATAL_ERROR "Community source-offer content mismatch: ${_path}")
  endif()
endforeach()

file(STRINGS "${_delivery}/SHA256SUMS.txt" _checksum_lines)
file(GLOB _delivery_assets LIST_DIRECTORIES false RELATIVE "${_delivery}" "${_delivery}/*")
list(FILTER _delivery_assets EXCLUDE REGEX "^SHA256SUMS\\.txt$")
list(LENGTH _checksum_lines _checksum_count)
list(LENGTH _delivery_assets _delivery_asset_count)
if(NOT _checksum_count EQUAL _delivery_asset_count)
  message(FATAL_ERROR
    "SHA256SUMS.txt count ${_checksum_count} does not match delivery asset count ${_delivery_asset_count}")
endif()

set(_tamper_root "${ENTERPRISE_DELIVERY_ROOT}/checksum-tamper")
file(COPY "${_delivery}/" DESTINATION "${_tamper_root}")
file(APPEND "${_tamper_root}/BUILD_METADATA.txt" "tampered=true\n")
execute_process(
  COMMAND "${CMAKE_COMMAND}" -DROOT=${_tamper_root}
    -P "${ENTERPRISE_SOURCE_DIR}/packaging/scripts/verify_sha256sums.cmake"
  RESULT_VARIABLE _tamper_verify_result
  OUTPUT_QUIET ERROR_QUIET)
if(_tamper_verify_result EQUAL 0)
  message(FATAL_ERROR "Checksum verification unexpectedly accepted a modified delivery asset")
endif()

message(STATUS "Enterprise OpenSSL customer-delivery package check passed")
message(STATUS "Delivery assets are staged under ${_delivery}")
