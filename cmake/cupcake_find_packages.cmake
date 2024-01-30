include_guard(GLOBAL)

include(cupcake_assert_special)
include(cupcake_find_package)
include(cupcake_json)

# Call cupcake_find_package for every dependency in the given group.
# TODO: Default `group` to `main`.
function(cupcake_find_packages group)
  cupcake_assert_special()
  cupcake_json_get(dependencies ARRAY "[]" "${PROJECT_JSON}" groups ${group} dependencies)
  # dependencies :: [{ file :: string, targets :: [string] }]
  string(JSON count LENGTH "${dependencies}")
  if(count GREATER 0)
    math(EXPR stop "${count} - 1")
    foreach(i RANGE ${stop})
      string(JSON file GET "${dependencies}" ${i} file)
      cupcake_find_package("${file}" "${ARGN}")
    endforeach()
  endif()
endfunction()
