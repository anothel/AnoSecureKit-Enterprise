# SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary
cmake_minimum_required(VERSION 3.20)
project(anosecurekit_enterprise_installed_consumer LANGUAGES CXX)

find_package(anosecurekit 0.4 CONFIG REQUIRED)
find_package(anosecurekitEnterprise 0.1 CONFIG REQUIRED)

if(NOT TARGET anosecurekit::anosecurekit)
  message(FATAL_ERROR "Installed Community target anosecurekit::anosecurekit is missing")
endif()
if(NOT TARGET anosecurekit::enterprise)
  message(FATAL_ERROR "Installed Enterprise target anosecurekit::enterprise is missing")
endif()
if(NOT ANOSECUREKIT_ENTERPRISE_PACKAGE_BACKEND_PROFILE STREQUAL "openssl")
  message(FATAL_ERROR "Installed Enterprise package must report openssl profile")
endif()
if(NOT ANOSECUREKIT_ENTERPRISE_PACKAGE_VERSION STREQUAL "0.1.0")
  message(FATAL_ERROR "Installed Enterprise package must report version 0.1.0")
endif()
if(NOT ANOSECUREKIT_ENTERPRISE_COMMUNITY_VERSION STREQUAL "0.4.0")
  message(FATAL_ERROR "Installed Enterprise package must report Community version 0.4.0")
endif()
if(NOT ANOSECUREKIT_ENTERPRISE_QUALIFICATION_STATUS STREQUAL
   "local-pass-remote-deferred")
  message(FATAL_ERROR "Installed Enterprise package qualification status is incorrect")
endif()
if(ANOSECUREKIT_ENTERPRISE_CUSTOMER_RELEASE_READY)
  message(FATAL_ERROR "Installed Enterprise package must keep customer release blocked")
endif()
if(NOT ANOSECUREKIT_ENTERPRISE_RELEASE_AUTHORIZATION_REQUIRED
   OR NOT ANOSECUREKIT_ENTERPRISE_RELEASE_AUTHORIZATION_STATUS STREQUAL
     "denied-or-unavailable")
  message(FATAL_ERROR "Installed Enterprise package authorization metadata is incorrect")
endif()

add_executable(anosecurekit_enterprise_installed_consumer main.cpp)
target_link_libraries(anosecurekit_enterprise_installed_consumer PRIVATE anosecurekit::enterprise)
target_compile_features(anosecurekit_enterprise_installed_consumer PRIVATE cxx_std_20)
file(GENERATE
  OUTPUT "anosecurekit-enterprise-consumer-$<CONFIG>.path"
  CONTENT "$<TARGET_FILE:anosecurekit_enterprise_installed_consumer>")
