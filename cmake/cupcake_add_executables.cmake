include_guard(GLOBAL)

include(cupcake_add_executable)
include(cupcake_assert_special)
include(cupcake_json)

function(cupcake_add_executables)
  cupcake_assert_special()

  # executables = metadata.get('executables', [])
  cupcake_json_get_list(executables "${PROJECT_JSON}" executables)
  foreach(executable IN LISTS executables)
    # executable :: { name :: string, private? :: boolean, links :: array }

    # If ${name} is a JSON string, it is unquoted here.
    string(JSON name GET "${executable}" name)
    cupcake_json_get(private BOOLEAN "false" "${executable}" private)
    if(private)
      set(private PRIVATE)
    else()
      set(private)
    endif()
    cupcake_add_executable(${name} ${private} "${ARGN}")

    cupcake_json_get_list(links "${executable}" links)
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
