include_guard(GLOBAL)

include(cupcake_find_sources)
include(cupcake_isolate_headers)
include(cupcake_module_dir)
include(cupcake_project_properties)
include(GNUInstallDirs)

# A target representing all executables declared with the function below.
add_custom_target(executables)

# add_executable(<name> [PRIVATE] [<source>...])
function(cupcake_add_executable name)
  cmake_parse_arguments(arg "PRIVATE" "" "" ${ARGN})

  set(target ${PROJECT_NAME}.executables.${name})
  set(this ${target} PARENT_SCOPE)
  add_executable(${target} ${arg_UNPARSED_ARGUMENTS})
  add_executable(${PROJECT_NAME}.e.${name} ALIAS ${target})
  if(name STREQUAL PROJECT_NAME)
    add_executable(${PROJECT_NAME}.executable ALIAS ${target})
  endif()

  add_dependencies(${PROJECT_NAME}.executables ${target})

  # We must pass arguments through the environment
  # because `cmake --build` will not forward any.
  # We must read arguments in a CMake script
  # because the generator command has no cross-platform method
  # to read the environment.
  add_custom_target(
    execute.${PROJECT_NAME}.${name}
    COMMAND "${CMAKE_COMMAND}"
    "-Dexecutable=$<TARGET_FILE:${target}>"
    -P "${CUPCAKE_MODULE_DIR}/data/call.cmake"
  )
  add_custom_target(
    debug.${PROJECT_NAME}.${name}
    COMMAND "${CMAKE_COMMAND}"
    "-Dexecutable=$<TARGET_FILE:${target}>"
    -P "${CUPCAKE_MODULE_DIR}/data/debug.cmake"
  )

  if(PROJECT_IS_TOP_LEVEL)
    add_dependencies(executables ${target})
    add_executable(executables.${name} ALIAS ${target})
    add_executable(e.${name} ALIAS ${target})
    if(name STREQUAL PROJECT_NAME)
      add_executable(executable ALIAS ${target})
    endif()
    add_custom_target(execute.${name})
    add_dependencies(execute.${name} execute.${PROJECT_NAME}.${name})
    add_custom_target(debug.${name})
    add_dependencies(debug.${name} debug.${PROJECT_NAME}.${name})
    if(name STREQUAL CMAKE_PROJECT_NAME)
      add_custom_target(execute)
      add_dependencies(execute execute.${name})
      add_custom_target(debug)
      add_dependencies(debug debug.${name})
    endif()
  endif()

  # Let the executable include "private" headers if it wants.
  cupcake_isolate_headers(
    ${target} PRIVATE
    "${CMAKE_CURRENT_SOURCE_DIR}"
    "${CMAKE_CURRENT_SOURCE_DIR}/src/${name}"
  )

  cupcake_find_sources(sources ${name} src)
  target_sources(${target} PRIVATE ${sources})

  set_target_properties(${target} PROPERTIES
    OUTPUT_NAME ${name}
    EXPORT_NAME executables::${name}
  )

  # If we call `copy`, but the "from" file list is empty, it will error.
  # Cannot simply condition on `WIN32`, or `BUILD_SHARED_LIBS`.
  # Must condition on whether the DLL list is empty.
  # https://discourse.cmake.org/t/generator-expression-with-potentially-empty-list/6254/2
  # We _chould_ make the command for the custom target change the `PATH`
  # environment variable, but then the builder will not be able to just
  # directly call the executable from the output directory.
  set(has_runtime_dlls $<BOOL:$<TARGET_RUNTIME_DLLS:${target}>>)
  set(copy_runtime_dlls
    ${CMAKE_COMMAND} -E copy
    $<TARGET_RUNTIME_DLLS:${target}>
    $<TARGET_FILE_DIR:${target}>
  )
  add_custom_command(TARGET ${target} POST_BUILD
    COMMAND "$<${has_runtime_dlls}:${copy_runtime_dlls}>"
    COMMAND_EXPAND_LISTS
  )

  if(NOT arg_PRIVATE)
    set(alias ${PROJECT_NAME}::executables::${name})
    add_executable(${alias} ALIAS ${target})
    add_executable(${PROJECT_NAME}::e::${name} ALIAS ${target})
    if(name STREQUAL PROJECT_NAME)
      add_executable(${PROJECT_NAME}::executable ALIAS ${target})
    endif()
    cupcake_set_project_property(
      APPEND PROPERTY PROJECT_EXECUTABLE_NAMES "${name}"
    )
    install(
      TARGETS ${target}
      EXPORT ${PROJECT_EXPORT_SET}
      RUNTIME
        DESTINATION "${CMAKE_INSTALL_BINDIR}"
        COMPONENT ${PROJECT_NAME}_runtime
    )
  endif()
endfunction()
