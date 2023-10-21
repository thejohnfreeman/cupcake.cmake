include_guard(GLOBAL)

function(cupcake_find_sources var name)
  set(globs "")
  get_cmake_property(langs ENABLED_LANGUAGES)
  if(CXX IN_LIST langs)
    list(APPEND globs
      "${CMAKE_CURRENT_SOURCE_DIR}/src/${name}/*.cpp"
      "${CMAKE_CURRENT_SOURCE_DIR}/src/${name}.cpp"
    )
  endif()
  if(C IN_LIST langs)
    list(APPEND globs
      "${CMAKE_CURRENT_SOURCE_DIR}/src/${name}/*.c"
      "${CMAKE_CURRENT_SOURCE_DIR}/src/${name}.c"
    )
  endif()
  file(GLOB_RECURSE sources CONFIGURE_DEPENDS ${globs})
  set(${var} "${sources}" PARENT_SCOPE)
endfunction()
