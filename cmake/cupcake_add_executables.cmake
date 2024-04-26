include_guard(GLOBAL)

include(cupcake_add_executable)
include(cupcake_assert_special)
include(cupcake_json)

function(cupcake_add_executables)
  cupcake_assert_special()

  # executables = metadata.get('executables', []):
  # executables :: [{ name :: string, links? :: array }]
  cupcake_json_get(executables ARRAY "[]" "${PROJECT_JSON}" executables)
  # for executable in executables:
  string(JSON count LENGTH "${executables}")
  if(count GREATER 0)
    math(EXPR stop "${count} - 1")
    foreach(i RANGE ${stop})
      # executable :: { name :: string, private? :: boolean, links :: array }
      string(JSON executable GET "${executables}" ${i})

      # If ${name} is a JSON string, it is unquoted here.
      string(JSON name GET "${executable}" name)
      cupcake_json_get(private BOOLEAN "false" "${executable}" private)
      if(private)
        set(private PRIVATE)
      else()
        set(private)
      endif()
      cupcake_add_executable(${name} ${private} "${ARGN}")

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
