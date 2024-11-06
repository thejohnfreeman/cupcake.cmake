include_guard(GLOBAL)

include(cupcake_assert_special)
include(cupcake_json)

# Call target_link_libraries for every target
# of every dependency in the given group.
# TODO: Default `group` to `main`.
function(cupcake_link_libraries target scope group)
  cupcake_assert_special()
  cupcake_json_get_list(imports "${PROJECT_JSON}" imports)
  foreach(import IN LISTS imports)
    # import :: { file :: string, targets :: [string] }
    # Select only imports whose `groups` (default: `["main"]`) contain `group`.
    cupcake_json_get(groups ARRAY "[\"main\"]" "${import}" groups)
    cupcake_json_to_list(groups "${groups}")
    # Group names are quoted JSON strings in the list.
    list(FIND groups "\"${group}\"" i)
    if(i LESS 0)
      continue()
    endif()
    string(JSON name GET "${import}" name)
    cupcake_json_get(targets ARRAY "[\"${name}::${name}\"]" "${import}" targets)
    cupcake_json_to_list(targets "${targets}")
    cupcake_unquote(targets "${targets}")
    target_link_libraries(${target} ${scope} ${targets})
  endforeach()
endfunction()
