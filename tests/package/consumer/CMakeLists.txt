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

add_executable(anosecurekit_enterprise_installed_consumer main.cpp)
target_link_libraries(anosecurekit_enterprise_installed_consumer PRIVATE anosecurekit::enterprise)
target_compile_features(anosecurekit_enterprise_installed_consumer PRIVATE cxx_std_20)
