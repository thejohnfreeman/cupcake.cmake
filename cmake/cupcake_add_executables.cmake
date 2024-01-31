include_guard(GLOBAL)

include(cupcake_add_executable)
include(cupcake_assert_special)
include(cupcake_json)

function(cupcake_add_executables group)
  cupcake_assert_special()
  cupcake_json_get(executables ARRAY "[]" "${PROJECT_JSON}" groups ${group} executables)
  # executables :: [{ name :: string, links? :: array }]
  string(JSON count LENGTH "${executables}")
  if(count GREATER 0)
    math(EXPR stop "${count} - 1")
    foreach(i RANGE ${stop})
      string(JSON executable GET "${executables}" ${i})

      string(JSON name GET "${executable}" name)
      # If ${name} is a JSON string, it is unquoted here.
      cupcake_add_executable(${name} "${ARGN}")

      cupcake_json_get(links ARRAY "[]" "${executable}" links)
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
