include_guard(GLOBAL)

# cupcake_json_get(variable type default json [key...])
function(cupcake_json_get variable type default json)
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

function(cupcake_json_to_list list array)
  set(tmp "")
  string(JSON count LENGTH "${array}")
  if(count GREATER 0)
    math(EXPR stop "${count} - 1")
    foreach(i RANGE ${stop})
      string(JSON item GET "${array}" ${i})
      list(APPEND tmp "${item}")
    endforeach()
  endif()
  set(${list} "${tmp}" PARENT_SCOPE)
endfunction()
