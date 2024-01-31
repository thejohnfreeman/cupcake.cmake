include_guard(GLOBAL)

include(cupcake_add_library)
include(cupcake_assert_special)
include(cupcake_json)

function(cupcake_add_libraries)
  if(ARGC GREATER 0)
    list(POP_FRONT ARGN group)
  else()
    set(group main)
  endif()
  cupcake_assert_special()
  cupcake_json_get(libraries ARRAY "[]" "${PROJECT_JSON}" groups ${group} libraries)
  # libraries :: [{ name :: string, links? :: array }]
  string(JSON count LENGTH "${libraries}")
  if(count GREATER 0)
    math(EXPR stop "${count} - 1")
    foreach(i RANGE ${stop})
      string(JSON library GET "${libraries}" ${i})

      string(JSON name GET "${library}" name)
      # If ${name} is a JSON string, it is unquoted here.
      cupcake_add_library(${name} "${ARGN}")

      cupcake_json_get(links ARRAY "[]" "${library}" links)
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
          cupcake_json_get(scope STRING "PUBLIC" "${link}" scope)
          target_link_libraries(${this} ${scope} ${target})
        endforeach()
      endif()
    endforeach()
  endif()
endfunction()
