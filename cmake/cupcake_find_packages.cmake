include_guard(GLOBAL)

include(cupcake_find_package)

# Call cupcake_find_package for every dependency in the given group.
# TODO: Default `group` to `main`.
function(cupcake_find_packages group)
  string(JSON dependencies GET "${PROJECT_JSON}" dependencies ${group})
  string(JSON count LENGTH "${dependencies}")
  if(count GREATER 0)
    math(EXPR stop "${count} - 1")
    foreach(i RANGE ${stop})
      string(JSON name GET "${dependencies}" ${i} name)
      cupcake_find_package("${name}" "${ARGN}")
    endforeach()
  endif()
endfunction()
