include_guard(GLOBAL)

include(cupcake_add_library)
include(cupcake_assert_special)
include(cupcake_json)

function(cupcake_add_libraries)
  cupcake_assert_special()

  # libraries = metadata.get('libraries', []):
  # libraries :: [{ name :: string, links? :: array }]
  cupcake_json_get(libraries ARRAY "[]" "${PROJECT_JSON}" libraries)
  # for library in libraries:
  string(JSON count LENGTH "${libraries}")
  if(count GREATER 0)
    math(EXPR stop "${count} - 1")
    foreach(i RANGE ${stop})
      # library :: { name :: string, private? :: boolean, links :: array }
      string(JSON library GET "${libraries}" ${i})

      # If ${name} is a JSON string, it is unquoted here.
      string(JSON name GET "${library}" name)
      cupcake_json_get(private BOOLEAN "false" "${library}" private)
      if(private)
        set(private PRIVATE)
      else()
        set(private)
      endif()
      cupcake_add_library(${name} ${private} "${ARGN}")

      cupcake_json_get(links ARRAY "[]" "${library}" links)
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
            set(scope "PUBLIC")
          else()
            string(JSON target GET "${link}" target)
            cupcake_json_get(scope STRING "PUBLIC" "${link}" scope)
          endif()
          cmake_language(EVAL CODE "set(target ${target})")
          target_link_libraries(${this} ${scope} ${target})
        endforeach()
      endif()
    endforeach()
  endif()
endfunction()
