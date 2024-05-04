cmake_minimum_required(VERSION 3.21)

project(cupcake.cmake VERSION 1.0.2 LANGUAGES NONE)

include(CMakePackageConfigHelpers)
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}/cmake")
include(cupcake)

if(NOT PROJECT_IS_TOP_LEVEL)
  return()
endif()

cupcake_project()

install(
  DIRECTORY cmake/
  DESTINATION "${CMAKE_INSTALL_EXPORTDIR}/${PROJECT_NAME}/"
)

configure_package_config_file(
  config.cmake.in
  "${PROJECT_EXPORT_DIR}/${PROJECT_NAME}-config.cmake"
  INSTALL_DESTINATION "${CMAKE_INSTALL_EXPORTDIR}/${PROJECT_NAME}"
  NO_SET_AND_CHECK_MACRO
  NO_CHECK_REQUIRED_COMPONENTS_MACRO
)

set(PROJECT_COMPATIBILITY SameMajorVersion)
if(PROJECT_VERSION_MAJOR EQUAL 0)
  set(PROJECT_COMPATIBILITY SameMinorVersion)
endif()
write_basic_package_version_file(
  "${PROJECT_EXPORT_DIR}/${PROJECT_NAME}-config-version.cmake"
  VERSION ${PROJECT_VERSION}
  COMPATIBILITY ${PROJECT_COMPATIBILITY}
)

install(
  DIRECTORY "${PROJECT_EXPORT_DIR}"
  DESTINATION "${CMAKE_INSTALL_EXPORTDIR}"
)
