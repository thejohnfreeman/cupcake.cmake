# Assert that a condition is true.
macro(cupcake_assert)
  if(NOT (${ARGN}))
    string(JOIN " " _expression ${ARGN})
    # Every line indented by a single space to disable CMake formatting.
    # CMAKE_CURRENT_LIST_LINE does not have dynamic scope like
    # CMAKE_CURRENT_LIST_FILE.
    # https://gitlab.kitware.com/cmake/cmake/-/issues/14118
    message(FATAL_ERROR " ${CMAKE_CURRENT_LIST_FILE}:??:\n assertion failed: (${_expression})")
  endif()
endmacro()
