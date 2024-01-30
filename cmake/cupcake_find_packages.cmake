include_guard(GLOBAL)

include(cupcake_assert_special)
include(cupcake_find_package)

# Call cupcake_find_package for every dependency in the given group.
# TODO: Default `group` to `main`.
function(cupcake_find_packages group)
  cupcake_assert_special()

  string(
    JSON dependencies ERROR_VARIABLE error
    GET "${PROJECT_JSON}" groups ${group} dependencies
  )
  if(error)
    message(DEBUG "missing groups.${group}.dependencies")
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
