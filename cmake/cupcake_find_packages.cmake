include_guard(GLOBAL)

include(cupcake_assert_special)
include(cupcake_find_package)
include(cupcake_json)

# Call cupcake_find_package for every import in the given group.
# TODO: Default `group` to `main`.
function(cupcake_find_packages group)
  cupcake_assert_special()
  cupcake_json_get_list(imports "${PROJECT_JSON}" imports)
  foreach(import IN LISTS imports)
    # import :: { file :: string?, targets :: [string], groups :: [string] }
    # Select only imports whose `groups` (default: `["main"]`) contain `group`.
    cupcake_json_get(groups ARRAY "[\"main\"]" "${import}" groups)
    cupcake_json_to_list(groups "${groups}")
    list(FIND groups "${group}" i)
    if(i LESS 0)
      continue()
    endif()
    string(JSON file GET "${import}" file)
    if(NOT file)
      string(JSON file GET "${import}" name)
    endif()
    cupcake_find_package("${file}" "${ARGN}")
  endforeach()
endfunction()
