include_guard(GLOBAL)

include(cupcake_add_library)
include(cupcake_assert_special)
include(cupcake_json)

function(cupcake_add_libraries)
  cupcake_assert_special()

  # libraries = metadata.get('libraries', [])
  cupcake_json_get_list(libraries "${PROJECT_JSON}" libraries)
  foreach(library IN LISTS libraries)
    # library :: { name :: string, private? :: boolean, links :: array }

    # If ${name} is a JSON string, it is unquoted here.
    string(JSON name GET "${library}" name)
    cupcake_json_get(private BOOLEAN "false" "${library}" private)
    if(private)
      set(private PRIVATE)
    else()
      set(private)
    endif()
    cupcake_add_library(${name} ${private} "${ARGN}")

    cupcake_json_get_list(links "${library}" links)
    foreach(link IN LISTS links)
      # link ::
      #   | string
      #   | { target :: string, scope? :: PUBLIC | PRIVATE | INTERFACE }
      string(JSON type TYPE "${link}")
      if(type STREQUAL STRING)
        # A JSON string is already quoted.
        set(target ${link})
        set(scope "PUBLIC")
      else()
        string(JSON target GET "${link}" target)
        cupcake_json_get(scope STRING "PUBLIC" "${link}" scope)
      endif()
      cmake_language(EVAL CODE "set(target ${target})")
      target_link_libraries(${this} ${scope} ${target})
    endforeach()
  endforeach()
endfunction()
