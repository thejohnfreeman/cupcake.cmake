include_guard(GLOBAL)

include(cupcake_find_sources)

function(cupcake_add_test name)
  set(target ${PROJECT_NAME}.tests.${name})
  set(this ${target} PARENT_SCOPE)
  add_executable(${target} EXCLUDE_FROM_ALL ${ARGN})
  add_executable(${PROJECT_NAME}.t.${name} ALIAS ${target})

  # Let the test include "private" headers if it wants.
  cupcake_isolate_headers(
    ${target} PRIVATE
    "${CMAKE_CURRENT_SOURCE_DIR}"
    "${CMAKE_CURRENT_SOURCE_DIR}/tests/${name}"
  )

  cupcake_find_sources(sources ${name})
  target_sources(${target} PRIVATE ${sources})

  add_dependencies(${PROJECT_NAME}.tests ${target})

  if(PROJECT_IS_TOP_LEVEL)
    add_executable(tests.${name} ALIAS ${target})
    add_executable(t.${name} ALIAS ${target})
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
