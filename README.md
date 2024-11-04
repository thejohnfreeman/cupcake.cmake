# cupcake.cmake

[![GitHub checks](https://img.shields.io/github/check-runs/thejohnfreeman/project-template-cpp/master?label=tests)](https://github.com/thejohnfreeman/project-template-cpp/actions?query=branch%3Amaster)
[![GitHub releases](https://img.shields.io/github/v/release/thejohnfreeman/cupcake.cmake?filter=!*%23*)](https://github.com/thejohnfreeman/cupcake.cmake/releases)
![CMake](https://img.shields.io/badge/CMake-%3E%3D%203.21-important)

cupcake.cmake is a CMake module.
It is named with the .cmake extension to distinguish it from [cupcake.py][],
which is a Python tool for working with Conan and CMake projects,
with additional features for projects using cupcake.cmake.


## Install

cupcake.cmake requires **CMake >= 3.21**.
The recommended method to import cupcake.cmake is with
[`find_package()`][find_package]:

```cmake
find_package(cupcake.cmake REQUIRED)
```

Unlike [`include()`][include], `find_package()` lets us easily
check version compatibility and lean on package managers like Conan.
For that to work, an installation must be found on the
[`CMAKE_PREFIX_PATH`][CMAKE_PREFIX_PATH].
There are a few ways to accomplish that.

### Install from Conan

First, add `cupcake.cmake` as a non-tool[^1] requirement to your Conan recipe:

```
requires = ['cupcake.cmake/alpha']
```

[^1]: The [`CMakeDeps`][CMakeDeps] generator will [not generate][6]
a package configuration file for a [tool requirement][tool_requires].

Second, tell Conan how to find cupcake.cmake.
You can either:

- Point it to my public [Redirectory][]:

    ```shell
    conan remote add redirectory https://conan.jfreeman.dev
    ```

- Copy the recipe from this project:

    ```shell
    conan export .
    ```


### Install manually

```shell
# In this project:
cmake -B <build-dir> -DCMAKE_INSTALL_PREFIX=<path> .
cmake --build <build-dir> --target install
# In your project:
cmake -B <build-dir> -DCMAKE_PREFIX_PATH=<path> .
```


### Install as submodule

Alternatively, you can embed this project in yours as a submodule and import
it with [`add_subdirectory()`][add_subdirectory]:

```cmake
add_subdirectory(path/to/cupcake.cmake)
```


## Interface

There are two categories of commands, general and special.
**General commands** have no special requirements,
but **special commands** require a `cupcake.json` file
in the project's root directory.
Special commands effectively relocate essential CMake configuration data
from multiple CMake listfiles sprinkled throughout a project
to a single JSON file that is more easily read and written by other tools.
Special commands are documented with example `cupcake.json`
and Pythonic pseudocode.


<a id="toc"></a>

### General commands

- [`cupcake_project`](#cupcake_project)
- [`cupcake_find_package`](#cupcake_find_package)
- [`cupcake_add_subproject`](#cupcake_add_subproject)
- [`cupcake_add_library`](#cupcake_add_library)
- [`cupcake_add_executable`](#cupcake_add_executable)
- [`cupcake_enable_testing`](#cupcake_enable_testing)
- [`cupcake_add_test`](#cupcake_add_test)
- [`cupcake_install_project`](#cupcake_install_project)
- [`cupcake_install_cpp_info`](#cupcake_install_cpp_info)


### Special commands

- [`cupcake_find_packages`](#cupcake_find_packages)
- [`cupcake_link_libraries`](#cupcake_link_libraries)
- [`cupcake_add_libraries`](#cupcake_add_libraries)
- [`cupcake_add_executables`](#cupcake_add_executables)
- [`cupcake_add_tests`](#cupcake_add_tests)


### Examples

A project using only general commands might look like this:

```cmake
# CMakeLists.txt
cmake_minimum_required(VERSION 3.21)
project(example LANGUAGES CXX)
find_package(cupcake REQUIRED)
cupcake_project()
cupcake_find_package(abc)
cupcake_add_library(example)
target_link_libraries(${this} PUBLIC abc::abc)
cupcake_add_executable(example)
target_link_libraries(${this} PUBLIC example.libexample)
cupcake_enable_testing()
cupcake_install_project()
cupcake_install_cpp_info()
```

```cmake
# tests/CMakeLists.txt
cupcake_find_package(xyz PRIVATE)
cupcake_add_test(example)
target_link_libraries(${this} PUBLIC xyz::xyz example.libexample)
```

A project using special commands might look like this:

```cmake
# CMakeLists.txt
cmake_minimum_required(VERSION 3.21)
project(example LANGUAGES CXX)
find_package(cupcake REQUIRED)
cupcake_project()
cupcake_find_packages(main)
cupcake_link_libraries(example.imports.main INTERFACE main)
cupcake_add_libraries()
cupcake_add_executables()
cupcake_enable_testing()
cupcake_install_project()
cupcake_install_cpp_info()
```

```cmake
# tests/CMakeLists.txt
cupcake_find_packages(test PRIVATE)
cupcake_link_libraries(example.imports.test INTERFACE test)
cupcake_add_tests()
```

```js
// cupcake.json
{
    "project": {
        "name": "example"
    },
    "imports": [
        { "name": "abc", "file": "abc", "targets": ["abc::abc"] },
        { "name": "xyz", "file": "xyz", "targets": ["xyz::xyz"], "groups": ["test"] }
    ],
    "libraries": [
        { "name": "example", "links": ["abc::abc"] }
    ],
    "executables": [
        { "name": "example", "links": [{ "target": "example.libexample", "scope": "PUBLIC" }] }
    ],
    "tests": [
        {
            "name": "example", "links": [
                "xyz::xyz",
                { "target": "example.libexample", "scope": "PUBLIC" }
            ]
        }
    ]
}
```


### `cupcake_project`
[:arrow_up:](#toc) :hash: [general](#interface)

```
cupcake_project()
```

Define project variables used by other cupcake.cmake commands,
and choose different defaults for built-in CMake commands and variables.

`cupcake_project()` must be called after a call of the built-in CMake command
[`project()`][project] and before any other cupcake.cmake commands in that project.
It should be called in the project's root `CMakeLists.txt`.
The recommended pattern looks like this:

```cmake
project(${PROJECT_NAME} LANGUAGES CXX)
find_package(cupcake REQUIRED)
cupcake_project()
```

`cupcake_project()` takes no arguments directly,
instead taking them all from the variables set by the call to `project()`.
I would have liked this command to wrap the call to `project()`, if possible,
but CMake [requires][1] a "literal, direct call to the `project()` command" in
the root `CMakeLists.txt`, and thus it cannot be wrapped.

`cupcake_project()` adds one special `INTERFACE` library target,
`${PROJECT_NAME}.imports.main`,
that projects can use to aggregate the "main" group of required libraries.
Other targets can conveniently link to this one target
instead of to each requirement individually,
and automatically link to new requirements as they are added.
Projects can use the special command `cupcake_link_libraries()`
to link all the "main" required libraries listed in `cupcake.json`.

`cupcake_project()` adds three more special internal targets:

- `${PROJECT_NAME}.libraries`: An [`INTERFACE` library][4] target.
- `${PROJECT_NAME}.executables`: A [custom][45] target.
- `${PROJECT_NAME}.tests`: A custom target.

All three are [excluded][EXCLUDE_FROM_ALL] from the "all" target.
Each has an external alias with the same name,
except the dot (`.`) is replaced with a double colon (`::`).
They each depend on all of the [libraries](#cupcake_add_library),
[executables](#cupcake_add_executable), or [tests](#cupcake_add_test),
respectively, added (by a `cupcake_add_<target>()` command)
in the project directly , i.e. not in a subproject.
Further, if the project is the root project,
equivalent targets are available under the unqualified names
`libraries`, `executables`, and `tests`, respectively.
These targets are intended to be automatic groups
with names that can be easily passed to `cmake --build`.

`cupcake_project()` changes these default behaviors:

|  #  | Variable | Value
| :-: | -------- | -----
|  1  | **[`CMAKE_POLICY_DEFAULT_CMP0087`][7]** | `NEW`
|  2  | **[`CMAKE_FIND_PACKAGE_PREFER_CONFIG`][15]** | `TRUE`
|  3  | **[`CMAKE_FIND_PACKAGE_SORT_ORDER`][16]** | `NATURAL`
|  3  | **[`CMAKE_FIND_PACKAGE_SORT_DIRECTION`][17]** | `DEC`
|  4  | **[`CMAKE_MODULE_PATH`][18]** | `${CMAKE_CURRENT_SOURCE_DIR}/external`
|  5  | **[`CMAKE_CXX_VISIBILITY_PRESET`][22]** | `hidden`
|  5  | **[`CMAKE_VISIBILITY_INLINES_HIDDEN`][23]** | `TRUE`
|  6  | **[`CMAKE_EXPORT_COMPILE_COMMANDS`][25]** | `TRUE`
|  7  | **[`CMAKE_BUILD_RPATH_USE_ORIGIN`][28]** | `TRUE`
|  7  | **[`CMAKE_INSTALL_RPATH`][29]** | `${origin} ${origin}/${relDir}`
|  8  | **[`CMAKE_RUNTIME_OUTPUT_DIRECTORY`][9]** | `${CMAKE_OUTPUT_PREFIX}/${CMAKE_INSTALL_BINDIR}`
|  8  | **[`CMAKE_LIBRARY_OUTPUT_DIRECTORY`][13]** | `${CMAKE_OUTPUT_PREFIX}/${CMAKE_INSTALL_LIBDIR}`
|  8  | **[`CMAKE_ARCHIVE_OUTPUT_DIRECTORY`][12]** | `${CMAKE_OUTPUT_PREFIX}/${CMAKE_INSTALL_LIBDIR}`

1. Lets `install(CODE)` use generator expressions,
which is required by [`cupcake_install_cpp_info()`](#cupcake_install_cpp_info).
2. Makes `find_package()` try Config mode before Module mode by default.
3. Sorts packages by latest semantic version when multiple versions are installed.
4. Lets `find_package()` find the project's [Find Modules][19].
5. Treats symbols in shared libraries as private by default, hiding them.
[Harmonizes][24] the default on non-Windows platforms
with the existing defaults on Windows and for C++ modules.
Public symbols must be explicitly exported with annotations.
These annotations are supplied by preprocessor macros
defined in headers generated for each library by
[`cupcake_add_library()`](#cupcake_add_library).[^2]
6. Generates a ["compilation database"][26] file (`compile_commands.json`)
used by [language servers][27] like [clangd][].
7. Uses relative rpaths both when building and installing,
which lets you move your build directory or install prefix
without breaking the executables underneath.
8. See section ["Output directory"](#output-directory).

[^2]: If you ever define an inline function in a public header that either
(a) has its address taken or (b) defines a static variable,
then you will need to make inlined functions visible
to ensure that different translation units that see that definition
resolve its addresses in the same way.

`cupcake_project()` adds these project variables (different for each subproject):

- **`PROJECT_EXPORT_SET`**:
    The name of the default [export set][14] for the project's exported targets.
- **`PROJECT_EXPORT_DIR`**:
    The directory in which to place generated export files,
    i.e. the [package configuration file][pcf],
    the [package version file][pvf], and any [target export files][30].
- **`${PROJECT_NAME}_FOUND`**:
    `TRUE`, to short-circuit calls to `find_package()`
    looking for this project's package from other subprojects,
    e.g. examples or siblings.

`cupcake_project()` adds these global variables (same for all subprojects):

- **`CMAKE_PROJECT_EXPORT_SET`**:
    The `PROJECT_EXPORT_SET` of the root project.
- **`CMAKE_INSTALL_EXPORTDIR`**:
    The path, relative to the installation prefix
    ([`CMAKE_INSTALL_PREFIX`][33]),
    in the style of [`GNUInstallDirs`][8], at which to install
    CMake package configuration files and other project metadata files
    (e.g. `cpp_info.py` installed by
    [`cupcake_install_cpp_info()`](#cupcake_install_cpp_info)).
    In other words, the string `share`.
- **`CMAKE_OUTPUT_DIR`**:
    See section ["Output directory"](#output-directory).
- **`CMAKE_OUTPUT_PREFIX`**: 
    See section ["Output directory"](#output-directory).
- **`CMAKE_HEADER_OUTPUT_DIRECTORY`**:
    See section ["Output directory"](#output-directory).


#### Output directory

CMake has a variable, [`CMAKE_RUNTIME_OUTPUT_DIRECTORY`][9],
that chooses the default value for the target property
[`RUNTIME_OUTPUT_DIRECTORY`][10],
which chooses the output directory for [`RUNTIME`][11] targets,
which includes executables on all platforms and DLLs on Windows.
That is, each runtime _target_ (an executable or a DLL)
has a _property_ `RUNTIME_OUTPUT_DIRECTORY` that chooses where it is placed,
and the default value for that target property is the value of the _variable_
`CMAKE_RUNTIME_OUTPUT_DIRECTORY` when the target is added
(with [`add_executable()`][add_executable] or [`add_library()`][add_library]).
Setting this variable is necessary on Windows to ensure that DLLs end up in
the same directory as the executables (including tests) that load them,
which is where those executables look for them.

We can use this variable and its cousins,
[`CMAKE_ARCHIVE_OUTPUT_DIRECTORY`][12] (for static libraries) and
[`CMAKE_LIBRARY_OUTPUT_DIRECTORY`][13]
(for shared libraries on non-Windows platforms),
to construct at build-time (i.e. before installation) a directory
structure that mimics, _in part_, the structure that will be created by an
installation, and isolated from the intermediate files littering the build
directory.
In other words, they let us create a _pseudo-installation_
where builders (and tools) can inspect and use
the interesting outputs of a build before they are installed,
including outputs like tests that will not be installed.

Each build configuration requires a separate pseudo-installation
because they are not guaranteed to use unique file names.
Each pseudo-installation is rooted at a `CMAKE_OUTPUT_PREFIX`,
akin to [`CMAKE_INSTALL_PREFIX`][33].
All output prefixes are nested under a common output directory,
`CMAKE_OUTPUT_DIR`, akin to [`CMAKE_BINARY_DIR`][34].
In fact, `CMAKE_OUTPUT_PREFIX` is just `${CMAKE_OUTPUT_DIR}/$<CONFIG>`.

There is no similar variable
choosing the output directory for generated headers,
just like there is no `add_header()` command
to add a generated header as a target.
cupcake.cmake fills this gap by defining the variable
`CMAKE_HEADER_OUTPUT_DIRECTORY`.
Generated headers are not configuration-specific, though,
so they are not placed under any output prefix.
Instead, `CMAKE_HEADER_OUTPUT_DIRECTORY` is just
`${CMAKE_OUTPUT_DIR}/Common/${CMAKE_INSTALL_INCLUDEDIR}`.

</details>


### `cupcake_find_package`
[:arrow_up:](#toc) :hash: [general](#interface)

```
cupcake_find_package(<package-name> [<version>] [PRIVATE] ...)
```

Import targets from a requirement by calling [`find_package()`][find_package].

`<version>` is forwarded to `find_package()`,
but it is an optional parameter for this command.
I recommend that you do _not_ include it.
Instead, version declaration and checking should happen
at the package manager level, e.g. in your Conan recipe.

In the underlying call to `find_package()`,
`REQUIRED` is always passed so that missing requirements raise an error.
Optional requirements should always be guarded by an [option][35],
e.g. `with_xyz`, rather than
conditionally linking based on whether or not CMake succeeded in finding them.

Unless `PRIVATE` is passed, this command saves the package name
(but not the version, even when given)
in a list of dependencies for the project.
That list is kept in a [`DIRECTORY` property][36]
of [`PROJECT_SOURCE_DIR`][31] named `PROJECT_DEPENDENCIES`.
It affects the behavior of
[`cupcake_install_project()`](#cupcake_install_project):
the generated [package configuration file][pcf] will transitively call
[`find_dependency()`][find_dependency] for all non-private dependencies.

Remaining arguments are passed through to `find_package()`.

`cupcake_find_package()` returns a variable `<package-name>_TARGETS`
containing a list of the targets imported by the command.


### `cupcake_add_subproject`
[:arrow_up:](#toc) :hash: [general](#interface)

```
cupcake_add_subproject(<name> [PRIVATE] [<path>])
```

Import targets from a requirement by calling
[`add_subdirectory()`][add_subdirectory].

`<path>` is forwarded to `add_subdirectory()` as the `<source_dir>` argument.
If it is absent, then `<name>` is used instead.
Relative paths, like the subproject name,
are relative to [`CMAKE_CURRENT_SOURCE_DIR`][CMAKE_CURRENT_SOURCE_DIR].

`<name>` should match the name passed to the [`project()`][project] command in
the `CMakeLists.txt` of the subdirectory.

`PRIVATE` has the same meaning as it does for
[`cupcake_find_package()`](#cupcake_find_package).


### `cupcake_add_library`
[:arrow_up:](#toc) :hash: [general](#interface)

```
cupcake_add_library(<name> [PRIVATE])
```

Add targets for a library by calling [`add_library()`][add_library].

Unless `PRIVATE` is passed, the library is exported,
meaning it is included when installing the project.
`PRIVATE` libraries can be good for sharing code among tests.

`cupcake_add_library()`
adds an internal target named `${PROJECT_NAME}.libraries.<name>`,
with an abbreviated [alias][3] named `${PROJECT_NAME}.l.<name>`.
If the library has the same name as the project,
then it is the project's _default library_ target
and gets the additional alias `${PROJECT_NAME}.library`.

If the library is exported,
then `cupcake_add_library()` adds external [`ALIAS`][3] targets
matching all of the above names,
but with the dot (`.`) separators replaced with double colons (`::`),
i.e. `${PROJECT_NAME}::libraries::<name>`, `${PROJECT_NAME}::l::<name>`,
and `${PROJECT_NAME}::library`.

Commands in the same project should use the internal target name.
Commands in different projects,
even if they are children (e.g. examples) or siblings
(e.g. fellow dependencies) sharing the same root project,
should use the external target name.
The external target names match the ones supplied by
the installed package configuration file
(see [`cupcake_install_project()`](#cupcake_install_project))
and/or the installed `cpp_info.py` script
(see [`cupcake_install_cpp_info()`](#cupcake_install_cpp_info)).

The internal target is added as a dependency
of the internal [`INTERFACE` library][4] target `${PROJECT_NAME}.libraries`,
which has an external alias `${PROJECT_NAME}::libraries`,
and an internal alias `libraries` if the project is the root project
(see [`cupcake_project()`](#cupcake_project)).

`cupcake_add_library()` returns a variable, `this`,
with the name of the internal target
for convenient use in subsequent commands.
Commands configuring the target should be called immediately after it,
to keep all of a target's configuration in one place.

A library's public headers must be either
the single file `include/<name>.hpp` (or `.h`)
or every file under the directory `include/<name>/`.
Private headers may be placed under `src/lib<name>/`.
Exported libraries export their public headers only.

If a library has sources, they should be either
the single file `src/lib<name>.cpp`
or every `.cpp` file under the directory `src/lib<name>/`.
If a library does not have sources, i.e. if it is a header-only library,
then the target will be an [`INTERFACE` library][4].
If a library does have sources, then the target will be a
[`STATIC` or `SHARED` library][5] depending on the value of variable
[`BUILD_SHARED_LIBS`][BUILD_SHARED_LIBS].

A library may include
its own public headers by their paths relative to `include/`,
and its own private headers by their paths relative to the project's
root directory (i.e. starting with `src/lib<name>/`),
but it may not include other headers in the project,
even relative to those same directories,
unless it links to a library exporting those headers.
In fact, it _cannot_ include unlinked headers
because `cupcake_add_library()` creates temporary symbolic links
in the build directory pointing to the permitted headers,
and only those will be found by the compiler.

Each library is given two generated headers.
These headers are installed with the library (if it is installed).
Libraries must _not_ define their own public headers with these names.

- `<name>/export.hpp`: An [export header][38] with preprocessor macros
    for annotating public and deprecated symbols in shared libraries.
    - `${NAME_UPPER}_EXPORT`
    - `${NAME_UPPER}_DEPRECATED`
- `<name>/version.hpp`: A version header with preprocessor macros
    deconstructing the package version string.
    - `${NAME_UPPER}_VERSION`:
        A string literal of [`PROJECT_VERSION`][39].
    - `${NAME_UPPER}_VERSION_MAJOR`:
        An integer expression equal to [`PROJECT_VERSION_MAJOR`][40].
    - `${NAME_UPPER}_VERSION_MINOR`:
        An integer expression equal to [`PROJECT_VERSION_MINOR`][41].
    - `${NAME_UPPER}_VERSION_PATCH`:
        An integer expression equal to [`PROJECT_VERSION_PATCH`][42].


### `cupcake_add_executable`
[:arrow_up:](#toc) :hash: [general](#interface)

```
cupcake_add_executable(<name> [PRIVATE])
```

Add targets for an executable by calling
[`add_executable()`][add_executable].

Unless `PRIVATE` is passed, the executable is exported,
meaning it is included when installing the project.
`PRIVATE` executables can be good for manual testing.

`cupcake_add_executable()`
adds an internal target named `${PROJECT_NAME}.executables.<name>`,
with an abbreviated [alias][47] named `${PROJECT_NAME}.e.<name>`.
If the executable has the same name as the project,
then it is the project's _default executable_ target
and gets the additional alias `${PROJECT_NAME}.executable`.

If the executable is exported,
then `cupcake_add_executable()` adds external [`ALIAS` targets][3]
matching all of the above names,
but with the dot (`.`) separators replaced with double colons (`::`),
i.e. `${PROJECT_NAME}::executables::<name>`, `${PROJECT_NAME}::e::<name>`,
and `${PROJECT_NAME}::executable`.

Commands in the same project should use the internal target name.
Commands in different projects,
even if they are children (e.g. examples) or siblings
(e.g. fellow dependencies) sharing the same root project,
should use the external target name.
The external target names match the ones supplied by
the installed package configuration file
(see [`cupcake_install_project()`](#cupcake_install_project))
and/or the installed `cpp_info.py` script
(see [`cupcake_install_cpp_info()`](#cupcake_install_cpp_info)).

The internal target is added as a dependency
of the internal [custom][45] target `${PROJECT_NAME}.executables`,
which has no external alias,
but has an internal alias `executables` if the project is the root project
(see [`cupcake_project()`](#cupcake_project)).

`cupcake_add_executable()` returns a variable, `this`,
with the name of the internal target
for convenient use in subsequent commands.
Commands configuring the target should be called immediately after it,
to keep all of a target's configuration in one place.

An executable must have sources, and they should be either
the single file `src/<name>.cpp`
or every `.cpp` file under the directory `src/<name>/`.

An executable may include
its own private headers by their paths relative to the project's
root directory (i.e. starting with `src/<name>/`),
but it may not include other headers in the project,
even relative to the same directory,
unless it links to a library exporting those headers.
In fact, it _cannot_ include unlinked headers
because `cupcake_add_library()` creates temporary symbolic links
in the build directory pointing to the permitted headers,
and only those will be found by the compiler.

`cupcake_add_executable()` adds two more internal targets.
The first is named `execute.${PROJECT_NAME}.<name>`,
aliased as `execute.<name>` if the project is the root project,
and as `execute` if the executable name matches the project name too.
It is a [custom][45] target that executes the executable.
You can invoke it yourself with the following command
instead of digging around in the output directory to find the executable.

```
cmake --build <build-dir> --target execute.<name>
```

Additionally, the target passes any
[CMake list][46] of command-line arguments
found in the environment variable `CUPCAKE_EXE_ARGUMENTS`.[^3]
In other words,
if you want to pass any command-line arguments
through the custom target to the executable,
then you must set environment variable `CUPCAKE_EXE_ARGUMENTS`
to a semicolon-separated (`;`) list of string arguments,
where each argument internally escapes any semicolons (with `\;`)
and is double-quoted (`"`) if it contains any whitespace.
If you use [cupcake.py][], then it will set `CUPCAKE_EXE_ARGUMENTS`
to forward any trailing arguments you pass to `cupcake exe <name>`.

[^3]: An environment variable must be used
because `cmake --build` does not forward any command-line arguments.

The second target is named `debug.${PROJECT_NAME}.<name>`,
aliased as `debug.<name>` if the project is the root project,
and as `debug` if the executable name matches the project name too.
It is a custom target that works almost like `execute.${PROJECT_NAME}.<name>`,
except that it executes [GDB][], the GNU debugger, on the executable target,
and initializes it with a [command file][48]
that sets the command line arguments found in `CUPCAKE_EXE_ARGUMENTS`
and then copies whatever is in the `.gdbinit` file of your current directory.
If you use [cupcake.py][], then it will set `CUPCAKE_EXE_ARGUMENTS`
to forward any trailing arguments you pass to `cupcake debug <name>`.


### `cupcake_enable_testing`
[:arrow_up:](#toc) :hash: [general](#interface)

```
cupcake_enable_testing()
```

Conditionally add tests to the project,
in the style of [`enable_testing()`][enable_testing].

The command does nothing if the project is not top-level.
Dependents generally want to run a dependency's tests only when the dependency
is installed, if at all, not every time the dependent runs its own tests.

If the project is top-level, then the command imports the [CTest module][CTest].
If [`BUILD_TESTING`][CTest] is `ON`, which it is by default,
then the command calls [`add_subdirectory(tests)`][add_subdirectory]
and adds a special `INTERFACE` library target
named `${PROJECT_NAME}.imports.test`,
akin to the `${PROJECT_NAME}.imports.main` target
added by [`cupcake_project()`](#cupcake_project),
i.e. a convenient target that projects can use
to aggregate the "test" group of required libraries.

Individual tests should be added in the `CMakeLists.txt` of the `tests/`
subdirectory.
Dependencies that only the tests require should be imported there too.


### `cupcake_add_test`
[:arrow_up:](#toc) :hash: [general](#interface)

```
cupcake_add_test(<name>)
```

Add targets for an executable by calling
[`add_executable()`][add_executable],
and add a CMake test whose command executes that executable by calling
[`add_test()`][add_test].

In CMake's documentation, the term "test", which I call here a "CMake test",
refers to a command that exits with code 0 if and only if it passes.
Typical commands simply execute an executable target in the project.
`cupcake_add_test()` implements exactly this pattern.
In this document, the term "test" refers to
the executable, the target, and the CMake test as a single unit.
Where necessary, I differentiate them.

`cupcake_add_test()`
adds an internal target named `${PROJECT_NAME}.tests.<name>`,
with an abbreviated [alias][3] named `${PROJECT_NAME}.t.<name>`,
as a dependency of the target `${PROJECT_NAME}.tests`.
If the project is the root project,
then it gives the internal target additional unqualified aliases
`tests.<name>` and `t.<name>`
and adds it as a dependency of the unqualified target `tests`.
Tests are never exported, meaning they are never installed
nor given external targets.
`cupcake_add_test()` defines the variable `this` in the parent scope
just like [`cupcake_add_library()`](#cupcake_add_library)
and for the same reason.

The target is [excluded][EXCLUDE_FROM_ALL] from the "all" target.
This way, resources are not spent building tests unless they are run.

`cupcake_add_test()` should be called only from the `tests` subdirectory,
where all tests should live.
The executable must have sources,
and they should be either the single file `tests/<name>.cpp`
or every `.cpp` file under the directory `tests/<name>/`.

The executable may include
its own private headers by their paths relative to the project's
root directory (i.e. starting with `tests/<name>/`),
but it may not include other headers in the project,
even relative to the same directory,
unless it links to a library exporting those headers.
In fact, it _cannot_ include unlinked headers
because `cupcake_add_library()` creates temporary symbolic links
in the build directory pointing to the permitted headers,
and only those will be found by the compiler.

The CMake test is added to the list of tests run by [CTest][].
It is given a [fixture][43] that builds (or rebuilds)
the executable before it is run.


### `cupcake_install_project`
[:arrow_up:](#toc) :hash: [general](#interface)

```
cupcake_install_project()
```

Add rules to install all exported targets.

`cupcake_install_project()` installs a [package configuration file][pcf] that
calls [`find_dependency()`][find_dependency]
for all non-`PRIVATE` packages imported with
[`cupcake_find_package()`](#cupcake_find_package), and
exports all non-`PRIVATE` [libraries](#cupcake_add_library) and
[executables](#cupcake_add_executable) added
(by `cupcake_add_<target>()` commands) in the project directly,
i.e. not in a subproject.
These targets are exported with their external names,
i.e. qualified by the project namespace,
e.g. `${PROJECT_NAME}::libraries::<name>`.

`cupcake_install_project()` installs a [package version file][pvf] too.

`cupcake_install_project()` should be called only once,
after all exported targets have been added.
It should be called from the project's root `CMakeLists.txt`.


### `cupcake_install_cpp_info`
[:arrow_up:](#toc) :hash: [general](#interface)

```
cupcake_install_cpp_info()
```

Add rules to install package metadata for Conan.

This command adds an installation rule to install a Python script at
`${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_EXPORTDIR}/<PackageName>/cpp_info.py`.
That script can be executed within the [`package_info()`][package_info] method
of a Python Conan recipe (`conanfile.py`) to [fill in the details][2] of the
[`cpp_info`][cpp_info] attribute:

```python
def package_info(self):
    path = f'{self.package_folder}/share/{self.name}/cpp_info.py'
    with open(path, 'r') as file:
        exec(file.read(), {}, {'self': self.cpp_info})
```


### `cupcake_find_packages`
[:arrow_up:](#toc) :hash: [special](#interface)

```
cupcake_find_packages(<group> ...)
```

Import targets from all requirements belonging to a group.

`cupcake_find_packages()` first selects all objects in the `.imports` array
of `cupcake.json` with a `.groups` array property (default value `["main"]`)
that contains `<group>`.
Then, it calls [`cupcake_find_package()`](#cupcake_find_package)
for each selected object, passing the `.file` string property of the object
(or if that is missing, the `.name` string property)
and any additional arguments that were passed to `cupcake_find_packages()`.

```js
{
    "imports": [
        { "name": "a", "file": "a", "targets": ["a::a"] },
        { "name": "b", "file": "b", "targets": ["b::b"], "groups": ["main"] },
        { "name": "c", "file": "c", "targets": ["c::c"], "groups": ["test"] }
    ]
}
```

```python
def cupcake_find_packages(group, *args):
    metadata = json.parse('cupcake.json')
    for package in metadata.get('imports', []):
        if group in package.get('groups', ['main']):
            cupcake_find_package(package['file'] or package['name'], *args)
```

Note: The `.name` property is the name of the package in the Conan ecosystem,
while the `.file` property is the name of the [package configuration file][pcf]
that the [`CMakeDeps`][CMakeDeps] generator generates for it,
corresponding to the [`cmake_file_name` property][44]
of the package recipe's [`cpp_info`][cpp_info].
When the `cmake_file_name` property is missing,
`CMakeDeps` uses the package name as its default value.


### `cupcake_link_libraries`
[:arrow_up:](#toc) :hash: [special](#interface)

```cmake
cupcake_link_libraries(<target> <scope> <group>)
```

Link a target to all imported targets of all requirements belonging to a group.

`cupcake_link_libraries()` is typically called
to link a convenience `INTERFACE` target,
e.g. `${PROJECT_NAME}.imports.main` or `${PROJECT_NAME}.imports.test`,
to the targets of its corresponding requirement group, following a call
to [`cupcake_find_packages()`](#cupcake_find_packages) for that group.

`cupcake_link_libraries()` first selects all objects in the `.imports` array
of `cupcake.json` with a `.groups` array property (default value `["main"]`)
that contains `<group>`.
Then, it calls [`target_link_libraries()`][target_link_libraries]
for each selected object, passing `<target>`, `<scope>`, and
the `.targets` array property of the object.

`<scope>` must be a [scope][] keyword,
one of `PUBLIC`, `PRIVATE`, or `INTERFACE`.
When `<target>` is an `INTERFACE` target, `<scope>` _must_ be `INTERFACE`.

```js
{
    "imports": [
        { "name": "a", "file": "a", "targets": ["a::a"] },
        { "name": "b", "file": "b", "targets": ["b::b"], "groups": ["main"] },
        { "name": "c", "file": "c", "targets": ["c::c"], "groups": ["test"] }
    ]
}
```

```python
def cupcake_link_libraries(target, scope, group):
    metadata = json.parse('cupcake.json')
    for package in metadata.get('imports', []):
        if group in package.get('groups', ['main']):
            name = package['name']
            targets = package.get('targets', [f'{name}::{name}'])
            target_link_libraries(target, scope, targets)
```


### `cupcake_add_libraries`
[:arrow_up:](#toc) :hash: [special](#interface)

```cmake
cupcake_add_libraries()
```

Add targets for all libraries in the project.

For each object in the `.libraries` array of `cupcake.json`,
`cupcake_add_libraries()` first calls
[`cupcake_add_library()`](#cupcake_add_library)
with the object's `.name` string property,
passing `PRIVATE` if the object has a `.private` Boolean property
that is `true`.
Then it calls [`target_link_libraries()`][target_link_libraries]
for each value in the object's `.links` array property.

Each link takes one of two forms.
If it is a string, then `cupcake_add_libraries()` calls
`target_link_libraries()` with it as the name of the linked target
and `PUBLIC` as the scope.
If it is an object, then `cupcake_add_libraries()` calls
`target_link_libraries()` with its `.target` string property
as the name of the linked target and
its optional `.scope` string property (default value `PUBLIC`) as the scope.

```js
{
    "libraries": [
        { "name": "x", "links": ["a::a"] },
        { "name": "y", "links": ["b::b", { "target": "c::c", "scope": "PRIVATE" }
    ]
}
```

```python
def cupcake_add_libraries():
    metadata = json.parse('cupcake.json')
    for library in metadata.get('libraries', []):
        target = cupcake_add_library(
            library['name'], PRIVATE if library['private'] else None
        )
        for link in library.get('links', []):
            if type(link) == str:
                target_link_libraries(target, PUBLIC, link)
            else:
                target_link_libraries(target, link.get('scope', PUBLIC), link['target'])
```


### `cupcake_add_executables`
[:arrow_up:](#toc) :hash: [special](#interface)

```cmake
cupcake_add_executables()
```

Add targets for all executables in the project.

For each object in the `.executables` array of `cupcake.json`,
`cupcake_add_executables()` first calls
[`cupcake_add_executable()`](#cupcake_add_executable)
with the object's `.name` string property,
passing `PRIVATE` if the object has a `.private` Boolean property
that is `true`.
Then it calls [`target_link_libraries()`][target_link_libraries]
for each value in the object's `.links` array property.

Each link takes one of two forms.
If it is a string, then `cupcake_add_executables()` calls
`target_link_libraries()` with it as the name of the linked target
and `PUBLIC` as the scope.
If it is an object, then `cupcake_add_executables()` calls
`target_link_libraries()` with its `.target` string property
as the name of the linked target and
its optional `.scope` string property (default value `PUBLIC`) as the scope.

```js
{
    "executables": [
        { "name": "x", "links": ["a::a"] },
        { "name": "y", "links": ["b::b", { "target": "c::c", "scope": "PRIVATE" }
    ]
}
```

```python
def cupcake_add_executables():
    metadata = json.parse('cupcake.json')
    for executable in metadata.get('executables', []):
        target = cupcake_add_executable(
            executable['name'], PRIVATE if executable['private'] else None
        )
        for link in executable.get('links', []):
            if type(link) == str:
                target_link_libraries(target, PUBLIC, link)
            else:
                target_link_libraries(target, link.get('scope', PUBLIC), link['target'])
```


### `cupcake_add_tests`
[:arrow_up:](#toc) :hash: [special](#interface)

```cmake
cupcake_add_tests()
```

Add targets for all tests in the project.

For each object in the `.tests` array of `cupcake.json`,
`cupcake_add_tests()` first calls
[`cupcake_add_test()`](#cupcake_add_test)
with the object's `.name` string property.
Then it calls [`target_link_libraries()`][target_link_libraries]
for each value in the object's `.links` array property.

Each link takes one of two forms.
If it is a string, then `cupcake_add_tests()` calls
`target_link_libraries()` with it as the name of the linked target
and `PUBLIC` as the scope.
If it is an object, then `cupcake_add_tests()` calls
`target_link_libraries()` with its `.target` string property
as the name of the linked target and
its optional `.scope` string property (default value `PUBLIC`) as the scope.

```js
{
    "tests": [
        { "name": "x", "links": ["a::a"] },
        { "name": "y", "links": ["b::b", { "target": "c::c", "scope": "PRIVATE" }
    ]
}
```

```python
def cupcake_add_tests():
    metadata = json.parse('cupcake.json')
    for test in metadata.get('tests', []):
        target = cupcake_add_test(test['name'])
        for link in test.get('links', []):
            if type(link) == str:
                target_link_libraries(target, PUBLIC, link)
            else:
                target_link_libraries(target, link.get('scope', PUBLIC), link['target'])
```


[BUILD_SHARED_LIBS]: https://cmake.org/cmake/help/latest/variable/BUILD_SHARED_LIBS.html
[CMAKE_CURRENT_SOURCE_DIR]: https://cmake.org/cmake/help/latest/variable/CMAKE_CURRENT_SOURCE_DIR.html
[CMAKE_PREFIX_PATH]: https://cmake.org/cmake/help/latest/variable/CMAKE_PREFIX_PATH.html
[EXCLUDE_FROM_ALL]: https://cmake.org/cmake/help/latest/prop_tgt/EXCLUDE_FROM_ALL.html#prop_tgt:EXCLUDE_FROM_ALL
[add_executable]: https://cmake.org/cmake/help/latest/command/add_executable.html
[add_library]: https://cmake.org/cmake/help/latest/command/add_library.html
[add_test]: https://cmake.org/cmake/help/latest/command/add_test.html
[add_subdirectory]: https://cmake.org/cmake/help/latest/command/add_subdirectory.html
[find_package]: https://cmake.org/cmake/help/latest/command/find_package.html
[find_dependency]: https://cmake.org/cmake/help/latest/module/CMakeFindDependencyMacro.html#command:find_dependency
[include]: https://cmake.org/cmake/help/latest/command/include.html
[project]: https://cmake.org/cmake/help/latest/command/project.html
[target_link_libraries]: https://cmake.org/cmake/help/latest/command/target_link_libraries.html#libraries-for-a-target-and-or-its-dependents
[CTest]: https://cmake.org/cmake/help/latest/module/CTest.html
[enable_testing]: https://cmake.org/cmake/help/latest/command/enable_testing.html
[pcf]: https://cmake.org/cmake/help/latest/manual/cmake-packages.7.html#package-configuration-file
[pvf]: https://cmake.org/cmake/help/latest/manual/cmake-packages.7.html#package-version-file
[CMakeDeps]: https://docs.conan.io/2/reference/tools/cmake/cmakedeps.html
[scope]: https://cmake.org/cmake/help/latest/manual/cmake-buildsystem.7.html#target-usage-requirements

[Artifactory]: https://docs.conan.io/1/uploading_packages/using_artifactory.html
[Redirectory]: https://conan.jfreeman.dev
[cpp_info]: https://docs.conan.io/2/reference/conanfile/methods/package_info.html#conan-conanfile-model-cppinfo
[package_info]: https://docs.conan.io/2/reference/conanfile/methods/package_info.html
[tool_requires]: https://docs.conan.io/1/devtools/build_requires.html
[requires]: https://docs.conan.io/1/reference/conanfile/attributes.html#requires
[cupcake.py]: https://github.com/thejohnfreeman/cupcake.py
[clangd]: https://clangd.llvm.org/
[GDB]: https://www.sourceware.org/gdb/

[1]: https://cmake.org/cmake/help/latest/command/project.html#usage
[2]: https://docs.conan.io/1/creating_packages/package_information.html
[3]: https://cmake.org/cmake/help/latest/command/add_library.html#alias-libraries
[4]: https://cmake.org/cmake/help/latest/command/add_library.html#interface-libraries
[5]: https://cmake.org/cmake/help/latest/command/add_library.html#normal-libraries
[6]: https://github.com/conan-io/conan/issues/13036
[7]: https://cmake.org/cmake/help/latest/policy/CMP0087.html
[8]: https://cmake.org/cmake/help/latest/module/GNUInstallDirs.html
[9]: https://cmake.org/cmake/help/latest/variable/CMAKE_RUNTIME_OUTPUT_DIRECTORY.html
[10]: https://cmake.org/cmake/help/latest/prop_tgt/RUNTIME_OUTPUT_DIRECTORY.html
[11]: https://cmake.org/cmake/help/latest/manual/cmake-buildsystem.7.html#runtime-output-artifacts
[12]: https://cmake.org/cmake/help/latest/variable/CMAKE_ARCHIVE_OUTPUT_DIRECTORY.html
[13]: https://cmake.org/cmake/help/latest/variable/CMAKE_LIBRARY_OUTPUT_DIRECTORY.html
[14]: https://cmake.org/cmake/help/latest/command/install.html#export
[15]: https://cmake.org/cmake/help/latest/variable/CMAKE_FIND_PACKAGE_PREFER_CONFIG.html
[16]: https://cmake.org/cmake/help/latest/variable/CMAKE_FIND_PACKAGE_SORT_ORDER.html
[17]: https://cmake.org/cmake/help/latest/variable/CMAKE_FIND_PACKAGE_SORT_DIRECTION.html
[18]: https://cmake.org/cmake/help/latest/variable/CMAKE_MODULE_PATH.html
[19]: https://cmake.org/cmake/help/book/mastering-cmake/chapter/Finding%20Packages.html
[20]: https://cmake.org/cmake/help/latest/variable/CMAKE_SYSTEM_NAME.html
[21]: https://cmake.org/cmake/help/latest/manual/cmake-variables.7.html#variables-that-describe-the-system
[22]: https://cmake.org/cmake/help/latest/prop_tgt/LANG_VISIBILITY_PRESET.html
[23]: https://cmake.org/cmake/help/latest/prop_tgt/VISIBILITY_INLINES_HIDDEN.html
[24]: https://gcc.gnu.org/wiki/Visibility
[25]: https://cmake.org/cmake/help/latest/variable/CMAKE_EXPORT_COMPILE_COMMANDS.html
[26]: https://clangd.llvm.org/design/compile-commands#compilation-databases
[27]: https://en.wikipedia.org/wiki/Language_Server_Protocol
[28]: https://cmake.org/cmake/help/latest/variable/CMAKE_BUILD_RPATH_USE_ORIGIN.html
[29]: https://cmake.org/cmake/help/latest/prop_tgt/INSTALL_RPATH.html
[30]: https://cmake.org/cmake/help/latest/command/export.html#exporting-targets
[31]: https://cmake.org/cmake/help/latest/variable/PROJECT_SOURCE_DIR.html
[32]: https://cmake.org/cmake/help/latest/variable/CMAKE_CURRENT_SOURCE_DIR.html
[33]: https://cmake.org/cmake/help/latest/variable/CMAKE_INSTALL_PREFIX.html
[34]: https://cmake.org/cmake/help/latest/variable/CMAKE_BINARY_DIR.html
[35]: https://cmake.org/cmake/help/latest/command/option.html
[36]: https://cmake.org/cmake/help/latest/command/set_property.html
[37]: https://cmake.org/cmake/help/latest/variable/CMAKE_SOURCE_DIR.html
[38]: https://cmake.org/cmake/help/latest/module/GenerateExportHeader.html
[39]: https://cmake.org/cmake/help/latest/variable/PROJECT_VERSION.html
[40]: https://cmake.org/cmake/help/latest/variable/PROJECT_VERSION_MAJOR.html
[41]: https://cmake.org/cmake/help/latest/variable/PROJECT_VERSION_MINOR.html
[42]: https://cmake.org/cmake/help/latest/variable/PROJECT_VERSION_PATCH.html
[43]: https://stackoverflow.com/a/56448477/618906
[44]: https://docs.conan.io/2/reference/tools/cmake/cmakedeps.html#cmakedeps-properties
[45]: https://cmake.org/cmake/help/latest/command/add_custom_target.html
[46]: https://cmake.org/cmake/help/latest/command/list.html#introduction
[47]: https://cmake.org/cmake/help/latest/command/add_executable.html#alias-executables
[48]: https://ftp.gnu.org/old-gnu/Manuals/gdb/html_node/gdb_190.html
[49]: https://sourceware.org/gdb/current/onlinedocs/gdb.html/Arguments.html#Arguments
