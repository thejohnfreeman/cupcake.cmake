include_guard(GLOBAL)

# Assert, from a special function,
# that cupcake.json exists
# and special functions are not disabled.
macro(cupcake_assert_special)
  if(NOT PROJECT_JSON)
    message(DEBUG "missing ${PROJECT_SOURCE_DIR}/cupcake.json")
    return()
  endif()
  if(DEFINED ENV{CUPCAKE_NO_SPECIAL})
    message(FATAL_ERROR "called special function ${CMAKE_CURRENT_FUNCTION} from ${CMAKE_CURRENT_LIST_FILE}")
  endif()
endmacro()
