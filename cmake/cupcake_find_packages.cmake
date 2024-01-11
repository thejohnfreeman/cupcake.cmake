include_guard(GLOBAL)

include(cupcake_find_package)

# Call cupcake_find_package for every dependency in the given group.
# TODO: Default `group` to `main`.
function(cupcake_find_packages group)
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
      string(JSON file GET "${dependencies}" ${i} file)
      cupcake_find_package("${file}" "${ARGN}")
    endforeach()
  endif()
endfunction()
