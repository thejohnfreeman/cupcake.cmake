include_guard(GLOBAL)

macro(cupcake_add_tests)
  # Do not add unexported targets when added as a subproject.
  if(PROJECT_NAME STREQUAL CMAKE_PROJECT_NAME)
    include(CTest)
    # Give package builders a means to skip unexported targets.
    if(BUILD_TESTING)
      set(target ${PROJECT_NAME}.dependencies.test)
      add_library(${target} INTERFACE)
      add_library(${PROJECT_NAME}::dependencies::test ALIAS ${target})
      add_subdirectory(tests)
    endif()
  endif()
endmacro()
