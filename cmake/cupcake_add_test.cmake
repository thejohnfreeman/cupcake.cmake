include_guard(GLOBAL)

include(cupcake_find_sources)

add_custom_target(tests)

function(cupcake_add_test name)
  set(target ${PROJECT_NAME}.test.${name})
  set(this ${target} PARENT_SCOPE)
  add_executable(${target} EXCLUDE_FROM_ALL ${ARGN})

  cupcake_find_sources(sources ${name})
  target_sources(${target} PRIVATE ${sources})

  # if(PROJECT_IS_TOP_LEVEL)
  if(PROJECT_NAME STREQUAL CMAKE_PROJECT_NAME)
    add_dependencies(tests ${target})
  else()
    # Do not include tests of dependencies added as subdirectories.
    return()
  endif()

  # https://stackoverflow.com/a/56448477/618906
  add_test(NAME ${target} COMMAND ${target})
  set_tests_properties(
    ${target} PROPERTIES
    FIXTURES_REQUIRED ${target}_fixture
  )

  add_test(
    NAME ${target}.build
    COMMAND
      ${CMAKE_COMMAND}
      --build ${CMAKE_BINARY_DIR}
      --config $<CONFIG>
      --target ${target}
  )
  set_tests_properties(${target}.build PROPERTIES
    FIXTURES_SETUP ${target}_fixture
  )
endfunction()
