cmake_minimum_required(VERSION 3.11)

project(LANGUAGES CXX)

message(STATUS "searching for '${PACKAGE_NAME}' under '${CMAKE_INSTALL_PREFIX}'")
find_package(
  ${PACKAGE_NAME}
  REQUIRED
  NO_DEFAULT_PATH
  PATHS ${CMAKE_INSTALL_PREFIX}
)

string(APPEND cpp_info
  # - names[generator]: namespace name
  "self.names['cmake_find_package'] = '${PACKAGE_NAME}'\n"
  "self.names['cmake_find_package_multi'] = '${PACKAGE_NAME}'\n"
  # - filenames[generator]: Config Module filename
  "self.filenames['cmake_find_package'] = '${PACKAGE_NAME}'\n"
  "self.filenames['cmake_find_package_multi'] = '${PACKAGE_NAME}'\n"
  # - set_property('cmake_file_name'): Config Module filename
  "self.set_property('cmake_file_name', '${PACKAGE_NAME}')\n"
  # - set_property('cmake_find_mode'): 'config'
  "self.set_property('cmake_find_mode', 'config')\n"
)

unset(buffer.log)
macro(log level text)
  message(${level} "${text}")
  string(APPEND buffer.log "# [${level}] ${text}\n")
endmacro()

set(pattern_scope "^([^:]+)::(.+)$")

# For each library target, add Python statements to the script text
# to declare these properties on a component named after the target:
#
# - requires: list of linked Conan package components
# - includedirs: list of include directories relative to the install prefix
# - defines: list of "name=value" definitions
# - cflags: list of non-definition compiler options (for C libraries)
# - cxxflags: list of non-definition compiler options (for C++ libraries)
# - sharedlinkflags: list of linker flags for shared libraries
# - libs: singleton list of installed library name to be searched by linker
# - libdirs: singleton list of directory, relative to the install prefix, where library is installed

# `libraries` is the set of libraries that
# have been or will be added as Conan components.
set(libraries ${${PACKAGE_NAME}_LIBRARIES})
# `targets` is the subset of `libraries` that
# have not yet been added as Conan components.
set(targets ${libraries})
# On each iteration, we will remove one target from `targets`,
# and add zero or more targets to `targets` and `libraries`
# if they do not already appear in `libraries`.
while(targets)
  list(POP_FRONT targets target)

  # log(STATUS "target = ${target}")

  # Peel off the namespace to get the unqualified CMake target name.
  string(REGEX MATCH "${pattern_scope}" match ${target})
  if(NOT CMAKE_MATCH_1 STREQUAL PACKAGE_NAME)
    message(FATAL_ERROR "foreign target: '${target}'")
  endif()

  # Target name unqualified by package name.
  set(tname ${CMAKE_MATCH_2})

  string(REGEX MATCH "${pattern_scope}" match ${tname})
  set(type ${CMAKE_MATCH_1})
  if(NOT (type STREQUAL "libraries" OR type STREQUAL "imports"))
    message(FATAL_ERROR "not a library: '${target}'")
  endif()

  # Library name.
  set(name ${CMAKE_MATCH_2})
  # Component name cannot contain double colon (::).
  set(cname ${type}.${name})
  string(APPEND components "'${cname}',")

  string(SUBSTRING ${type} 0 1 shorthand)
  set(aliases "'${PACKAGE_NAME}::${shorthand}::${name}'")
  if(type STREQUAL "libraries" AND name STREQUAL PACKAGE_NAME)
    string(APPEND aliases ",'${PACKAGE_NAME}::library'")
  endif()

  string(APPEND cpp_info
    # - names[generator]: unqualified target name
    "self.components['${cname}'].names['cmake_find_package'] = '${tname}'\n"
    "self.components['${cname}'].names['cmake_find_package_multi'] = '${tname}'\n"
    # - set_property('cmake_target_name'): qualified target name
    "self.components['${cname}'].set_property('cmake_target_name', '${target}')\n"
    "self.components['${cname}'].set_property('cmake_target_aliases', [${aliases}])\n"
  )

  get_target_property(links ${target} INTERFACE_LINK_LIBRARIES)
  unset(requires)
  while(links)
    list(POP_FRONT links link)
    # Each link is one of:
    # - An internal target.
    # - An external target.
    # - A non-target, most likely a library name or absolute path.
    if(NOT TARGET ${link})
      log(ERROR "ignoring non-target link '${link}' of target '${target}'")
      continue()
    endif()
    # Unalias once we've confirmed that it is a target.
    get_target_property(linked ${link} ALIASED_TARGET)
    if(linked)
      set(link ${linked})
    endif()
    # log(STATUS "link = ${link}")
    # An internal target starts with "${PACKAGE_NAME}::".
    # Everything else is an external target.
    # We cannot distinguish internal vs external libraries by whether they are
    # imported. It does not work when "importing" external libraries with
    # `add_subdirectory`. The subdirectory's targets would not be imported,
    # but would not be internal either, unless we install them.
    string(REGEX MATCH "${pattern_scope}" match ${link})
    if(CMAKE_MATCH_1 STREQUAL PACKAGE_NAME)
      # Internal target.
      # Add it to `targets` (and `libraries`) if not yet in `libraries`.
      list(FIND libraries "${link}" index)
      if(index LESS 0)
        list(APPEND libraries "${link}")
        list(APPEND targets "${link}")
      endif()
      # Translate to Conan component name.
      if(NOT CMAKE_MATCH_2 MATCHES "${pattern_scope}")
        message(FATAL_ERROR "illegal internal target name: ${link}")
      endif()
      set(lname ${CMAKE_MATCH_1}.${CMAKE_MATCH_2})
    else()
      # External target.
      # TODO: Find Conan component name in variable map `CUPCAKE_CONAN_COMPONENT`.
      # TODO: Pre-populate `CUPCAKE_CONAN_COMPONENT` from `cupcake.json`.
      set(lname ${link})
    endif()
    list(APPEND requires "'${lname}'")
  endwhile()
  if(requires)
    list(REMOVE_DUPLICATES requires)
    list(JOIN requires "," requires)
    string(APPEND cpp_info
      "self.components['${cname}'].requires = [${requires}]\n"
    )
  endif()

  get_target_property(directories ${target} INTERFACE_INCLUDE_DIRECTORIES)
  if(directories)
    foreach(directory ${directories})
      file(RELATIVE_PATH relative "${CMAKE_INSTALL_PREFIX}" "${directory}")
      # TODO: Cannot start with `..`.
      string(APPEND includedirs "'${relative}',")
    endforeach()
    if(NOT includedirs STREQUAL "'include',")
      string(APPEND cpp_info
        "self.components['${cname}'].includedirs = [${includedirs}]\n"
      )
    endif()
  endif()

  get_target_property(definitions ${target} INTERFACE_COMPILE_DEFINITIONS)
  if(definitions)
    foreach(definition ${definitions})
      string(APPEND defines "'${definition}',")
    endforeach()
    string(APPEND cpp_info
      "self.components['${cname}'].defines = [${defines}]\n"
    )
  endif()

  get_target_property(options ${target} INTERFACE_COMPILE_OPTIONS)
  if(options)
    foreach(option ${options})
      string(APPEND cxxflags "'${option}',")
    endforeach()
    string(APPEND cpp_info
      "self.components['${cname}'].cxxflags = [${cxxflags}]\n"
    )
  endif()

  # LINK_FLAGS until CMake 3.13, then LINK_OPTIONS.
  get_target_property(options ${target} LINK_OPTIONS)
  if(NOT options)
    get_target_property(options ${target} LINK_FLAGS)
  endif()
  if(options)
    foreach(option ${options})
      string(APPEND sharedlinkflags "'${option}',")
    endforeach()
    string(APPEND cpp_info
      "self.components['${cname}'].sharedlinkflags = [${sharedlinkflags}]\n"
    )
  endif()

  get_target_property(location ${target} IMPORTED_LOCATION_${CONFIG})
  # Skip header-only libraries.
  if(location)
    get_filename_component(lib "${location}" NAME)
    get_filename_component(libdir "${location}" DIRECTORY)
    file(RELATIVE_PATH libdir "${CMAKE_INSTALL_PREFIX}" "${libdir}")
    string(APPEND cpp_info
      "self.components['${cname}'].libs = ['${lib}']\n"
    )
    if(NOT libdir STREQUAL "lib")
      string(APPEND cpp_info
        "self.components['${cname}'].libdirs = ['${libdir}']\n"
      )
    endif()
  endif()
endwhile()

string(APPEND cpp_info
  "self.components['libraries'].set_property('cmake_target_name', '${PACKAGE_NAME}::libraries')\n"
  "self.components['libraries'].requires = [${components}]\n"
  "${buffer.log}"
)

# There is no way to model executables in `cpp_info`.
# At the moment, Conan adds `bindirs` from `tools_requires` to the `PATH`,
# which has been enough for most consumers.
# https://github.com/conan-io/conan/issues/7240#issuecomment-2100421551

file(GENERATE
  OUTPUT "${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_EXPORTDIR}/${PACKAGE_NAME}/cpp_info.py"
  CONTENT "${cpp_info}"
)
