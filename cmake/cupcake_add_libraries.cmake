include_guard(GLOBAL)

include(cupcake_add_library)
include(cupcake_assert_special)

# json_get(variable json default [key...])
function(json_get variable json type default)
  # Catch the error here because any step on the path may be missing.
  string(
    JSON value ERROR_VARIABLE error
    GET "${json}" ${ARGN}
  )
  if(error)
    message(DEBUG "missing ${ARGN}")
    set(value "${default}")
  else()
    string(JSON actual TYPE "${json}" ${ARGN})
    if(NOT actual STREQUAL type)
      message(FATAL_ERROR "value ${ARGN} has unexpected type ${actual} != {type}")
    endif()
  endif()
  set(${variable} "${value}" PARENT_SCOPE)
endfunction()

function(cupcake_add_libraries group)
  cupcake_assert_special()

  json_get(libraries "${PROJECT_JSON}" ARRAY "[]" groups ${group} libraries)
  # libraries :: [{ name :: string, links? :: array }]
  string(JSON count LENGTH "${libraries}")
  if(count GREATER 0)
    math(EXPR stop "${count} - 1")
    foreach(i RANGE ${stop})
      string(JSON library GET "${libraries}" ${i})

      string(JSON name GET "${library}" name)
      # If ${name} is a JSON string, it is unquoted here.
      cupcake_add_library(${name} "${ARGN}")

      json_get(links "${library}" ARRAY "[]" links)
      # links :: [
      #   { target :: string, scope? :: PUBLIC | PRIVATE | INTERFACE }
      # ]
      string(JSON count LENGTH "${links}")
      if(count GREATER 0)
        math(EXPR stop "${count} - 1")
        foreach(j RANGE ${stop})
          string(JSON link GET "${links}" ${j})
          string(JSON target GET "${link}" target)
          cmake_language(EVAL CODE "set(target ${target})")
          json_get(scope "${link}" STRING "PUBLIC" scope)
          target_link_libraries(${this} ${scope} ${target})
        endforeach()
      endif()
    endforeach()
  endif()
endfunction()
