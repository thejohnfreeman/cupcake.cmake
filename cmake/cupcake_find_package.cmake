include_guard(GLOBAL)

include(cupcake_project_properties)

# cupcake_find_package(<package-name> [PRIVATE] ...)
# We cannot scope the call to find_package because we cannot predict which
# variables that it sets need to percolate. Therefore, this must be a macro.
macro(cupcake_find_package name)
  if(NOT ${name}_FOUND)

    string(RANDOM cupcake_scope)

    message(STATUS
      "Finding package '${name}' depended by '${PROJECT_NAME}'..."
    )

    cmake_parse_arguments(${cupcake_scope} "PRIVATE" "" "" ${ARGN})

    # Prepare to set a variable listing the imported targets.
    # https://stackoverflow.com/a/69496683/618906
    get_property(
      ${cupcake_scope}_before
      DIRECTORY "${CMAKE_SOURCE_DIR}"
      PROPERTY IMPORTED_TARGETS
    )

    # if(PROJECT_IS_TOP_LEVEL AND ...)
    if(PROJECT_NAME STREQUAL CMAKE_PROJECT_NAME AND NOT ${cupcake_scope}_PRIVATE)
      cupcake_set_project_property(
        # Each item in this list is itself another list,
        # an argument list for `find_dependency`.
        # If the version is missing, that's fine.
        APPEND PROPERTY PROJECT_DEPENDENCIES "${name}"
      )
    endif()

    find_package(${name} REQUIRED ${${cupcake_scope}_UNPARSED_ARGUMENTS})
    if(NOT ${name}_FOUND)
      message(FATAL_ERROR "Package '${name}' was not found.")
    endif()

    get_property(
      ${name}_TARGETS
      DIRECTORY "${CMAKE_SOURCE_DIR}"
      PROPERTY IMPORTED_TARGETS
    )
    list(REMOVE_ITEM ${name}_TARGETS ${${cupcake_scope}_before})

  endif()
endmacro()
