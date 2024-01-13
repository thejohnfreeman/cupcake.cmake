include_guard(GLOBAL)

function(list_from_array out array)
  set(tmp "")
  string(JSON count LENGTH "${array}")
  if(count GREATER 0)
    math(EXPR stop "${count} - 1")
    foreach(i RANGE ${stop})
      string(JSON item GET "${array}" ${i})
      list(APPEND tmp "${item}")
    endforeach()
  endif()
  set(${out} "${tmp}" PARENT_SCOPE)
endfunction()

# Call target_link_libraries for every target
# of every dependency in the given group.
# TODO: Default `group` to `main`.
function(cupcake_link_libraries target scope group)
  if(NOT PROJECT_JSON)
    message(DEBUG "missing cupcake.json")
    return()
  endif()

  string(
    JSON dependencies ERROR_VARIABLE error
    GET "${PROJECT_JSON}" dependencies ${group}
  )
  if(error)
    message(DEBUG "missing dependencies.${group}")
    return()
  endif()

  string(JSON count LENGTH "${dependencies}")
  if(count GREATER 0)
    math(EXPR stop "${count} - 1")
    foreach(i RANGE ${stop})
      string(JSON targets GET "${dependencies}" ${i} targets)
      list_from_array(targets "${targets}")
      target_link_libraries(${target} ${scope} ${targets})
    endforeach()
  endif()
endfunction()
