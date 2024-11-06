include_guard(GLOBAL)

include(cupcake_json)
include(cupcake_project_properties)

# This is a function just to create a private scope for variables.
function(_cupcake_parse_json json)
  set(members "\"\":null")
  # imports = json.get('imports', [])
  cupcake_json_get_list(imports "${json}" imports)
  foreach(import IN LISTS imports)
    # import :: { root :: object, components :: object[] }

    # if component := import['root']:
    string(JSON component ERROR_VARIABLE error GET "${import}" root)
    if(NOT error)
      cupcake_parse_component(ms "${component}")
      string(APPEND members "${ms}")
    endif()

    # components = import.get('components', [])
    cupcake_json_get_list(components "${import}" components)
    foreach(component IN LISTS components)
      # component :: { name :: string, target :: string, aliases: string[] }
      cupcake_parse_component(ms "${component}")
      string(APPEND members "${ms}")
    endforeach()

  endforeach()
  cupcake_set_project_property(PROPERTY CONAN_COMPONENTS "${members}")
endfunction()

function(cupcake_parse_component variable component)
  string(JSON name GET "${component}" name)
  string(JSON target GET "${component}" target)
  # members[target] = name
  set(members ",\"${target}\":\"${name}\"")
  # aliases = component.get('aliases', []):
  cupcake_json_get_list(aliases "${component}" aliases)
  foreach(alias IN LISTS aliases)
    # members[alias] = name
    string(APPEND members ",\"${alias}\":\"${name}\"")
  endforeach()
  set(${variable} "${members}" PARENT_SCOPE)
endfunction()

macro(cupcake_project)
  # Allow `install(CODE)` to use generator expressions.
  cmake_policy(SET CMP0087 NEW)

  # Define more project variables.
  set(PROJECT_EXPORT_SET ${PROJECT_NAME}_targets)
  set(PROJECT_EXPORT_DIR "${CMAKE_BINARY_DIR}/export/${PROJECT_NAME}")
  set(CMAKE_INSTALL_EXPORTDIR share)

  if(PROJECT_IS_TOP_LEVEL)
    set(CMAKE_PROJECT_EXPORT_SET ${PROJECT_EXPORT_SET})
  endif()

  # Change defaults to follow recommended best practices.

  # On Windows, we need to make sure that shared libraries end up next to the
  # executables that require them.
  # Without setting these variables, multi-config generators generally place
  # targets in ${subdirectory}/${target}.dir/${config}.
  # We cannot use CMAKE_INSTALL_LIBDIR because the value of that variable may
  # differ between the top-level project linking against subproject
  # artifacts installed under the output prefix, and subprojects installing
  # themselves under the top-level project's output prefix.
  # In other words, if a subproject installs a library to
  # CMAKE_INSTALL_LIBDIR, then it may end up somewhere other than the
  # CMAKE_INSTALL_LIBDIR that the top-level project looks in.
  # We use root source and binary directories instead of current directories
  # because outputs from all subprojects must end up in the same directory.
  if(DEFINED ENV{CMAKE_OUTPUT_DIR})
    set(CMAKE_OUTPUT_DIR_DEFAULT "$ENV{CMAKE_OUTPUT_DIR}")
    # Seems impossible to get the current working directory.
    # Use `CMAKE_SOURCE_DIR` for now.
    # https://stackoverflow.com/a/71109856/618906
    cmake_path(
      ABSOLUTE_PATH CMAKE_OUTPUT_DIR_DEFAULT
      BASE_DIRECTORY "${CMAKE_SOURCE_DIR}"
    )
  else()
    set(CMAKE_OUTPUT_DIR_DEFAULT "${CMAKE_BINARY_DIR}/output/")
  endif()
  set(
    CMAKE_OUTPUT_DIR "${CMAKE_OUTPUT_DIR_DEFAULT}"
    CACHE FILEPATH
    "root directory for interesting outputs"
  )
  set(CMAKE_OUTPUT_PREFIX "${CMAKE_OUTPUT_DIR}/$<CONFIG>")

  if(NOT CMAKE_RUNTIME_OUTPUT_DIRECTORY)
    set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_OUTPUT_PREFIX}/${CMAKE_INSTALL_BINDIR}")
  endif()
  if(NOT CMAKE_LIBRARY_OUTPUT_DIRECTORY)
    set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${CMAKE_OUTPUT_PREFIX}/${CMAKE_INSTALL_LIBDIR}")
  endif()
  if(NOT CMAKE_ARCHIVE_OUTPUT_DIRECTORY)
    set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_OUTPUT_PREFIX}/${CMAKE_INSTALL_LIBDIR}")
  endif()
  if(NOT CMAKE_HEADER_OUTPUT_DIRECTORY)
    set(CMAKE_HEADER_OUTPUT_DIRECTORY "${CMAKE_OUTPUT_DIR}/Common/${CMAKE_INSTALL_INCLUDEDIR}")
  endif()

  # Search for Package Configuration Files first.
  # Use Find Modules as backup only.
  set(CMAKE_FIND_PACKAGE_PREFER_CONFIG TRUE)
  # Prefer the latest version of a package.
  set(CMAKE_FIND_PACKAGE_SORT_ORDER NATURAL)
  # Prefer Config Modules over Find Modules.
  set(CMAKE_FIND_PACKAGE_SORT_DIRECTION DEC)
  # Cupcake projects must put their Find Modules in `external/`.
  list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}/external")

  # See `CMAKE_SYSTEM_NAME` to identify the platform,
  # but see "variables that describe the system"
  # to identify families of platforms.
  # The Big Three are best approximated with `APPLE`, `LINUX`, and `WIN32`.
  # https://cmake.org/cmake/help/latest/manual/cmake-variables.7.html#variables-that-describe-the-system

  set(CMAKE_CXX_VISIBILITY_PRESET hidden)
  set(CMAKE_VISIBILITY_INLINES_HIDDEN YES)
  set(CMAKE_EXPORT_COMPILE_COMMANDS YES)

  # Enable deterministic relocatable builds.
  set(CMAKE_BUILD_RPATH_USE_ORIGIN TRUE)

  get_property(languages GLOBAL PROPERTY ENABLED_LANGUAGES)
  if("CXX" IN_LIST languages OR "C" IN_LIST languages)
    include(GNUInstallDirs)
    # Use relative rpath for installation.
    if(APPLE)
      set(origin @loader_path)
    else()
      set(origin $ORIGIN)
    endif()
    file(RELATIVE_PATH relDir
      ${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_INSTALL_BINDIR}
      ${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_INSTALL_LIBDIR}
    )
    set(CMAKE_INSTALL_RPATH ${origin} ${origin}/${relDir})
  endif()

  set(target ${PROJECT_NAME}.imports.main)
  add_library(${target} INTERFACE)
  set_target_properties(${target} PROPERTIES EXPORT_NAME imports::main)
  install(TARGETS ${target} EXPORT ${PROJECT_EXPORT_SET})
  add_library(${PROJECT_NAME}::imports::main ALIAS ${target})

  add_library(${PROJECT_NAME}.libraries INTERFACE EXCLUDE_FROM_ALL)
  add_library(${PROJECT_NAME}::libraries ALIAS ${PROJECT_NAME}.libraries)
  add_custom_target(${PROJECT_NAME}.executables)
  # There is no external group target for executables.
  add_custom_target(${PROJECT_NAME}.tests)

  if(PROJECT_IS_TOP_LEVEL)
    add_library(libraries ALIAS ${PROJECT_NAME}.libraries)
    add_custom_target(executables)
    add_dependencies(executables ${PROJECT_NAME}.executables)
    add_custom_target(tests)
    add_dependencies(tests ${PROJECT_NAME}.tests)
  endif()

  # This command should be called when
  # `CMAKE_CURRENT_SOURCE_DIR == PROJECT_SOURCE_DIR`,
  # but when it isn't, we want to look in `PROJECT_SOURCE_DIR`.
  set(path "${PROJECT_SOURCE_DIR}/cupcake.json")
  if(EXISTS "${path}")
    file(READ "${path}" PROJECT_JSON)
    set(${PROJECT_NAME}_JSON "${PROJECT_JSON}")
    _cupcake_parse_json("${PROJECT_JSON}")
  endif()

  set(${PROJECT_NAME}_FOUND 1)
endmacro()
