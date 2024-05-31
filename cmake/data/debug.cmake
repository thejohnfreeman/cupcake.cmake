# Called by `debug.<name>` custom targets.
# The `CUPCAKE_EXE_ARGS` environment variable is
# a semicolon-separated CMake list of strings.
# In .gdbinit, we need to `set args` with
# a space-separated shell list of strings.
# Trust that the strings have been appropriately quoted
# by the one who set the environment variable.
# Semicolons must be escaped within those strings.
string(JOIN " " args $ENV{CUPCAKE_EXE_ARGUMENTS})
set(cwd "$ENV{PWD}")
set(fin "${cwd}/.gdbinit")
set(fout "${CMAKE_BINARY_DIR}/gdbinit")
if(EXISTS "${fin}")
  file(READ "${fin}" gdbinit)
endif()
configure_file("${CMAKE_CURRENT_LIST_DIR}/gdbinit" "${fout}")
execute_process(
  COMMAND gdb --command "${fout}" "${executable}"
  WORKING_DIRECTORY "${cwd}"
)
# TODO: Implement a cross-platform solution:
# - Find the current working directory.
# - Choose a debugger.
# - Set arguments for the debugger.
