# SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary
cmake_minimum_required(VERSION 3.20)

project(
  anosecurekit_enterprise
  VERSION 0.1.0
  DESCRIPTION "AnoSecureKit Enterprise scaffold"
  LANGUAGES CXX)

include(GNUInstallDirs)

option(ANOSECUREKIT_ENTERPRISE_USE_BUNDLED_COMMUNITY "Use bundled Community source" ON)
option(ANOSECUREKIT_ENTERPRISE_ENABLE_ANOCRYPTO "Enable private AnoCrypto backend integration" OFF)

if(ANOSECUREKIT_ENTERPRISE_USE_BUNDLED_COMMUNITY)
  set(ANOSECUREKIT_BUILD_TESTS OFF CACHE BOOL "" FORCE)
  set(ANOSECUREKIT_BUILD_CLI OFF CACHE BOOL "" FORCE)
  set(ANOSECUREKIT_INSTALL_CLI OFF CACHE BOOL "" FORCE)
  set(ANOSECUREKIT_BUILD_FUZZ OFF CACHE BOOL "" FORCE)
  add_subdirectory(third_party/anosecurekit-community EXCLUDE_FROM_ALL)
else()
  find_package(anosecurekit CONFIG REQUIRED)
endif()

if(ANOSECUREKIT_ENTERPRISE_ENABLE_ANOCRYPTO)
  if(DEFINED ANOCRYPTO_ROOT AND EXISTS "${ANOCRYPTO_ROOT}/CMakeLists.txt")
    add_subdirectory("${ANOCRYPTO_ROOT}" anocrypto-build EXCLUDE_FROM_ALL)
  elseif(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/third_party/anocrypto/CMakeLists.txt")
    add_subdirectory(third_party/anocrypto EXCLUDE_FROM_ALL)
  else()
    find_package(anocrypto CONFIG REQUIRED)
  endif()
endif()

add_library(anosecurekit_enterprise
  src/enterprise.cpp)

add_library(anosecurekit::enterprise ALIAS anosecurekit_enterprise)

target_compile_features(anosecurekit_enterprise PUBLIC cxx_std_20)

target_include_directories(anosecurekit_enterprise
  PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>)

target_link_libraries(anosecurekit_enterprise
  PUBLIC anosecurekit::anosecurekit)

if(ANOSECUREKIT_ENTERPRISE_ENABLE_ANOCRYPTO)
  target_compile_definitions(anosecurekit_enterprise PUBLIC ANOSECUREKIT_ENTERPRISE_HAS_ANOCRYPTO=1)
  if(TARGET anocrypto::anocrypto)
    target_link_libraries(anosecurekit_enterprise PUBLIC anocrypto::anocrypto)
  elseif(TARGET anocrypto)
    target_link_libraries(anosecurekit_enterprise PUBLIC anocrypto)
  endif()
endif()

add_executable(anosecurekit_enterprise_info
  examples/info/main.cpp)
target_link_libraries(anosecurekit_enterprise_info PRIVATE anosecurekit::enterprise)
target_compile_features(anosecurekit_enterprise_info PRIVATE cxx_std_20)

install(TARGETS anosecurekit_enterprise
  EXPORT anosecurekitEnterpriseTargets
  RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
  LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
  ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR})

install(DIRECTORY include/anosecurekit_enterprise
  DESTINATION ${CMAKE_INSTALL_INCLUDEDIR})
