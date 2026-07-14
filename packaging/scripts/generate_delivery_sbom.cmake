# SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary
cmake_minimum_required(VERSION 3.20)

foreach(_required IN ITEMS ROOT OUTPUT ENTERPRISE_VERSION COMMUNITY_VERSION PROFILE)
  if(NOT DEFINED ${_required} OR "${${_required}}" STREQUAL "")
    message(FATAL_ERROR "${_required} is required")
  endif()
endforeach()
if(NOT IS_DIRECTORY "${ROOT}")
  message(FATAL_ERROR "ROOT must name an existing delivery asset directory")
endif()

function(_json_escape _input _output)
  set(_value "${_input}")
  string(REPLACE "\\" "\\\\" _value "${_value}")
  string(REPLACE "\"" "\\\"" _value "${_value}")
  string(REPLACE "\n" "\\n" _value "${_value}")
  string(REPLACE "\r" "\\r" _value "${_value}")
  string(REPLACE "\t" "\\t" _value "${_value}")
  set(${_output} "${_value}" PARENT_SCOPE)
endfunction()

file(REAL_PATH "${ROOT}" _root)
get_filename_component(_output_name "${OUTPUT}" NAME)
file(GLOB _assets LIST_DIRECTORIES false RELATIVE "${_root}" "${_root}/*")
list(FILTER _assets EXCLUDE REGEX "^${_output_name}$")
list(FILTER _assets EXCLUDE REGEX "^SHA256SUMS\\.txt$")
if(NOT _assets)
  message(FATAL_ERROR "No delivery assets found for SBOM generation")
endif()
list(SORT _assets)

set(_identity "${ENTERPRISE_VERSION}|${COMMUNITY_VERSION}|${PROFILE}")
foreach(_path IN LISTS _assets)
  file(SHA256 "${_root}/${_path}" _hash)
  string(APPEND _identity "|${_path}:${_hash}")
endforeach()
string(UUID _uuid
  NAMESPACE "13e7283a-4cc4-4a32-909d-64cb20de9a50"
  NAME "${_identity}" TYPE SHA1)
string(TIMESTAMP _created "%Y-%m-%dT%H:%M:%SZ" UTC)

set(_files_json "")
string(CONCAT _relationships_json
"    {\"spdxElementId\":\"SPDXRef-DOCUMENT\",\"relationshipType\":\"DESCRIBES\",\"relatedSpdxElement\":\"SPDXRef-Package-Enterprise\"},\n"
"    {\"spdxElementId\":\"SPDXRef-Package-Enterprise\",\"relationshipType\":\"DEPENDS_ON\",\"relatedSpdxElement\":\"SPDXRef-Package-Community\"},\n"
"    {\"spdxElementId\":\"SPDXRef-Package-Enterprise\",\"relationshipType\":\"DEPENDS_ON\",\"relatedSpdxElement\":\"SPDXRef-Package-OpenSSL\"}")
set(_first TRUE)
foreach(_path IN LISTS _assets)
  file(SHA256 "${_root}/${_path}" _hash)
  string(SHA256 _path_hash "${_path}")
  string(SUBSTRING "${_path_hash}" 0 20 _short_hash)
  set(_file_id "SPDXRef-File-${_short_hash}")
  _json_escape("./${_path}" _escaped_path)
  if(NOT _first)
    string(APPEND _files_json ",\n")
  endif()
  set(_first FALSE)
  string(APPEND _files_json
"    {\"fileName\":\"${_escaped_path}\",\"SPDXID\":\"${_file_id}\",\"checksums\":[{\"algorithm\":\"SHA256\",\"checksumValue\":\"${_hash}\"}],\"licenseConcluded\":\"NOASSERTION\",\"copyrightText\":\"NOASSERTION\"}")
  string(APPEND _relationships_json
",\n    {\"spdxElementId\":\"SPDXRef-Package-Enterprise\",\"relationshipType\":\"CONTAINS\",\"relatedSpdxElement\":\"${_file_id}\"}")
endforeach()

string(CONCAT _json
"{\n"
"  \"spdxVersion\": \"SPDX-2.3\",\n"
"  \"dataLicense\": \"CC0-1.0\",\n"
"  \"SPDXID\": \"SPDXRef-DOCUMENT\",\n"
"  \"name\": \"AnoSecureKit Enterprise ${ENTERPRISE_VERSION} ${PROFILE} delivery\",\n"
"  \"documentNamespace\": \"urn:uuid:${_uuid}\",\n"
"  \"creationInfo\": {\"created\":\"${_created}\",\"creators\":[\"Tool: AnoSecureKit Enterprise CMake delivery generator\"]},\n"
"  \"hasExtractedLicensingInfos\": [{\"licenseId\":\"LicenseRef-AnoSecureKit-Enterprise-Proprietary\",\"extractedText\":\"Proprietary commercial terms apply to Enterprise-owned files; see LICENSE in the delivery.\"}],\n"
"  \"packages\": [\n"
"    {\"name\":\"AnoSecureKit Enterprise\",\"SPDXID\":\"SPDXRef-Package-Enterprise\",\"versionInfo\":\"${ENTERPRISE_VERSION}\",\"downloadLocation\":\"NOASSERTION\",\"filesAnalyzed\":true,\"licenseConcluded\":\"LicenseRef-AnoSecureKit-Enterprise-Proprietary\",\"licenseDeclared\":\"LicenseRef-AnoSecureKit-Enterprise-Proprietary\",\"copyrightText\":\"NOASSERTION\"},\n"
"    {\"name\":\"AnoSecureKit Community\",\"SPDXID\":\"SPDXRef-Package-Community\",\"versionInfo\":\"${COMMUNITY_VERSION}\",\"downloadLocation\":\"NOASSERTION\",\"filesAnalyzed\":false,\"licenseConcluded\":\"MPL-2.0\",\"licenseDeclared\":\"MPL-2.0\",\"copyrightText\":\"NOASSERTION\"},\n"
"    {\"name\":\"OpenSSL\",\"SPDXID\":\"SPDXRef-Package-OpenSSL\",\"versionInfo\":\"NOASSERTION\",\"downloadLocation\":\"NOASSERTION\",\"filesAnalyzed\":false,\"licenseConcluded\":\"Apache-2.0\",\"licenseDeclared\":\"Apache-2.0\",\"copyrightText\":\"NOASSERTION\"}\n"
"  ],\n"
"  \"files\": [\n${_files_json}\n  ],\n"
"  \"relationships\": [\n${_relationships_json}\n  ]\n"
"}\n")

get_filename_component(_output_dir "${OUTPUT}" DIRECTORY)
file(MAKE_DIRECTORY "${_output_dir}")
file(WRITE "${OUTPUT}.tmp" "${_json}")
file(RENAME "${OUTPUT}.tmp" "${OUTPUT}")
message(STATUS "Generated ${OUTPUT}")
