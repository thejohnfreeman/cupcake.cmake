include_guard(GLOBAL)

include(cupcake_add_test)
include(cupcake_assert_special)
include(cupcake_json)

function(cupcake_add_tests)
  cupcake_assert_special()
  cupcake_json_get_list(tests "${PROJECT_JSON}" tests)
  foreach(test IN LISTS tests)
    # test :: { name :: string, links? :: array }

    string(JSON name GET "${test}" name)
    # If ${name} is a JSON string, it is unquoted here.
    cupcake_add_test(${name} "${ARGN}")

    cupcake_json_get_list(links "${test}" links)
    foreach(link IN LISTS links)
      # link ::
      #   | string
      #   | { target :: string, scope? :: PUBLIC | PRIVATE | INTERFACE }
      string(JSON type TYPE "${link}")
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
  endforeach()
endfunction()
