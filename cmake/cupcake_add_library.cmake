include_guard(GLOBAL)

include(cupcake_find_sources)
include(cupcake_generate_version_header)
include(cupcake_isolate_headers)
include(cupcake_project_properties)
include(GNUInstallDirs)

# add_library(<name> [PRIVATE] [<source>...])
function(cupcake_add_library name)
  cmake_parse_arguments(arg "PRIVATE" "" "" ${ARGN})

  # We add a "lib" prefix to library targets
  # so that libraries and executables can share the same name.
  # They will be distinguished in the filesystem by their filename prefix
  # and suffix, and within CMake by this prefix.
  set(target ${PROJECT_NAME}.libraries.${name})
  set(this ${target} PARENT_SCOPE)

  # If this is a header-only library, then it must have type INTERFACE.
  # Otherwise, let the builder choose its linkage with BUILD_SHARED_LIBS.
  if(
      EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/src/lib${name}" OR
      EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/src/lib${name}.cpp" OR
      EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/src/lib${name}.c"
  )
    unset(type)
    set(public PUBLIC)
  else()
    set(type INTERFACE)
    set(public INTERFACE)
  endif()

  add_library(${target} ${type} ${arg_UNPARSED_ARGUMENTS})
  add_library(${PROJECT_NAME}.l.${name} ALIAS ${target})
  if(name STREQUAL PROJECT_NAME)
    add_library(${PROJECT_NAME}.library ALIAS ${target})
  endif()
  set_target_properties(${target} PROPERTIES
    EXPORT_NAME libraries::${name}
  )

  target_link_libraries(${PROJECT_NAME}.libraries INTERFACE ${target})

  if(PROJECT_IS_TOP_LEVEL)
    add_library(libraries.${name} ALIAS ${target})
    add_library(l.${name} ALIAS ${target})
    if(name STREQUAL PROJECT_NAME)
      add_library(library ALIAS ${target})
    endif()
  endif()

  cupcake_generate_version_header(${name})

  # Each library has one public header directory under `include/`.
  # We want to isolate them from each other,
  # meaning that they cannot inadvertently include each other
  # without declaring an explicit link
  # just because their includes are relative to the same `include/` directory.
  # To implement isolation at build time,
  # we create a _new_ include directory under the build directory
  # that contains only symbolic links to the library's own public headers.
  cupcake_isolate_headers(
    ${target} ${public}
    "${CMAKE_CURRENT_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/include/${name}"
    "${CMAKE_CURRENT_SOURCE_DIR}/include/${name}.h"
    "${CMAKE_CURRENT_SOURCE_DIR}/include/${name}.hpp"
  )

  target_include_directories(${target} ${public}
    "$<BUILD_INTERFACE:${CMAKE_HEADER_OUTPUT_DIRECTORY}>"
    # TODO: Verify that the `INSTALL_INTERFACE` is implemented by
    # `install(TARGETS ... INCLUDES DESTINATION ...)` below.
  )

  get_target_property(type ${target} TYPE)
  if(NOT type STREQUAL INTERFACE_LIBRARY)
    # Let the library include "private" headers if it wants.
    cupcake_isolate_headers(
      ${target} PRIVATE
      "${CMAKE_CURRENT_SOURCE_DIR}"
      "${CMAKE_CURRENT_SOURCE_DIR}/src/lib${name}"
    )

    cupcake_find_sources(sources lib${name} src)
    target_sources(${target} PRIVATE ${sources})
    set_target_properties(${target} PROPERTIES
      OUTPUT_NAME ${name}
    )

    include(GenerateExportHeader)
    # In order to include the generated header by a path starting with
    # a directory matching the library name like all other library headers, we
    # must pass the `EXPORT_FILE_NAME` option.
    generate_export_header(${target}
      BASE_NAME ${name}
      EXPORT_FILE_NAME "${CMAKE_HEADER_OUTPUT_DIRECTORY}/${name}/export.hpp"
    )
    if(NOT type STREQUAL SHARED_LIBRARY)
      # Disable the export definitions.
      string(TOUPPER ${name} UPPER_NAME)
      string(REPLACE - _ UPPER_NAME ${UPPER_NAME})
      target_compile_definitions(${target} PUBLIC ${UPPER_NAME}_STATIC_DEFINE)
    endif()
  endif()
  if(type STREQUAL SHARED_LIBRARY)
    set_target_properties(${target} PROPERTIES
      VERSION ${PROJECT_VERSION}
      SOVERSION ${PROJECT_VERSION_MAJOR}
    )
  endif()

  if(NOT arg_PRIVATE)
    set(alias ${PROJECT_NAME}::libraries::${name})
    add_library(${alias} ALIAS ${target})
    add_library(${PROJECT_NAME}::l::${name} ALIAS ${target})
    if(name STREQUAL PROJECT_NAME)
      add_library(${PROJECT_NAME}::library ALIAS ${target})
    endif()
    cupcake_set_project_property(
      APPEND PROPERTY PROJECT_LIBRARY_NAMES "${name}"
    )
    install(
      TARGETS ${target}
      EXPORT ${PROJECT_EXPORT_SET}
      ARCHIVE
        DESTINATION "${CMAKE_INSTALL_LIBDIR}"
        COMPONENT ${PROJECT_NAME}_development
      LIBRARY
        DESTINATION "${CMAKE_INSTALL_LIBDIR}"
        COMPONENT ${PROJECT_NAME}_runtime
        NAMELINK_SKIP
      RUNTIME
        DESTINATION "${CMAKE_INSTALL_BINDIR}"
        COMPONENT ${PROJECT_NAME}_runtime
      INCLUDES
        DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}"
    )
    # added in CMake 3.12: NAMELINK_COMPONENT
    install(
      TARGETS ${target}
      LIBRARY
        DESTINATION "${CMAKE_INSTALL_LIBDIR}"
        COMPONENT ${PROJECT_NAME}_development
        NAMELINK_ONLY
    )
    # We must install the headers with install(DIRECTORY) because
    # installing a target does not install its include directories.
    install(
      DIRECTORY
        "${CMAKE_HEADER_OUTPUT_DIRECTORY}/${name}"
        "${CMAKE_CURRENT_SOURCE_DIR}/include/${name}"
      DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}"
      COMPONENT ${PROJECT_NAME}_development
    )
  endif()
endfunction()
