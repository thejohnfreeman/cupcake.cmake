include_guard(GLOBAL)

include(cupcake_assert_special)
include(cupcake_json)

# Call target_link_libraries for every target
# of every dependency in the given group.
# TODO: Default `group` to `main`.
function(cupcake_link_libraries target scope group)
  cupcake_assert_special()
  cupcake_json_get(imports ARRAY "[]" "${PROJECT_JSON}" groups ${group} imports)
  # imports :: [{ file :: string, targets :: [string] }]
  string(JSON count LENGTH "${imports}")
  if(count GREATER 0)
    math(EXPR stop "${count} - 1")
    foreach(i RANGE ${stop})
      cupcake_json_get(targets ARRAY "[]" "${imports}" ${i} targets)
      cupcake_json_to_list(targets "${targets}")
      target_link_libraries(${target} ${scope} ${targets})
    endforeach()
  endif()
endfunction()
