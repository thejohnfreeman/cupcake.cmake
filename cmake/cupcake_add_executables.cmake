include_guard(GLOBAL)

include(cupcake_add_executable)
include(cupcake_assert_special)
include(cupcake_json)

function(cupcake_add_executables)
  if(ARGC GREATER 0)
    list(POP_FRONT ARGN group)
  else()
    set(group main)
  endif()
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
      #   | string
      #   | { target :: string, scope? :: PUBLIC | PRIVATE | INTERFACE }
      # ]
      string(JSON count LENGTH "${links}")
      if(count GREATER 0)
        math(EXPR stop "${count} - 1")
        foreach(j RANGE ${stop})
          string(JSON link GET "${links}" ${j})
          string(JSON type TYPE "${links}" ${j})
          if(type STREQUAL STRING)
            set(target "${link}")
            set(scope "PRIVATE")
          else()
            string(JSON target GET "${link}" target)
            cupcake_json_get(scope STRING "PRIVATE" "${link}" scope)
          endif()
          cmake_language(EVAL CODE "set(target ${target})")
          target_link_libraries(${this} ${scope} ${target})
        endforeach()
      endif()
    endforeach()
  endif()
endfunction()
