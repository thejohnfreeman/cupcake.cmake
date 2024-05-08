include_guard(GLOBAL)

include(cupcake_assert_special)
include(cupcake_find_package)
include(cupcake_json)

# Call cupcake_find_package for every import in the given group.
# TODO: Default `group` to `main`.
function(cupcake_find_packages group)
  cupcake_assert_special()
  cupcake_json_get(imports ARRAY "[]" "${PROJECT_JSON}" imports)
  # imports :: [{ file :: string?, targets :: [string], groups :: [string] }]
  string(JSON count LENGTH "${imports}")
  if(count GREATER 0)
    math(EXPR stop "${count} - 1")
    foreach(i RANGE ${stop})
      string(JSON import GET "${imports}" ${i})
      # Select only imports whose `groups` (default: `["main"]`)
      # contain `group`.
      cupcake_json_get(groups ARRAY "[\"main\"]" "${import}" groups)
      cupcake_json_to_list(groups "${groups}")
      list(FIND groups "${group}" j)
      if(j LESS 0)
        continue()
      endif()
      string(JSON file GET "${import}" file)
      if(NOT file)
        string(JSON file GET "${import}" name)
      endif()
      cupcake_find_package("${file}" "${ARGN}")
    endforeach()
  endif()
endfunction()
