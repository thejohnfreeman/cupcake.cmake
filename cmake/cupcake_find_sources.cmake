include_guard(GLOBAL)

function(cupcake_find_sources var name)
  # Optional third argument is subdirectory.
  if(NOT ARGC GREATER 2)
    set(ARGV2 ".")
  endif()
  set(globs "")
  get_cmake_property(langs ENABLED_LANGUAGES)
  if(CXX IN_LIST langs)
    list(APPEND globs
      "${CMAKE_CURRENT_SOURCE_DIR}/${ARGV2}/${name}/*.cpp"
      "${CMAKE_CURRENT_SOURCE_DIR}/${ARGV2}/${name}.cpp"
    )
  endif()
  if(C IN_LIST langs)
    list(APPEND globs
      "${CMAKE_CURRENT_SOURCE_DIR}/${ARGV2}/${name}/*.c"
      "${CMAKE_CURRENT_SOURCE_DIR}/${ARGV2}/${name}.c"
    )
  endif()
  file(GLOB_RECURSE sources CONFIGURE_DEPENDS ${globs})
  set(${var} "${sources}" PARENT_SCOPE)
endfunction()
