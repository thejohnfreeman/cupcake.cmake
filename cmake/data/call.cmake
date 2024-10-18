# Called by `execute.<name>` custom targets.
# TODO: test no arguments
# TODO: test with arguments containing ';'
# https://cmake.org/cmake/help/latest/command/string.html#join
# TODO: test with arguments containing '''
string(JOIN "' '" arguments $ENV{CUPCAKE_EXE_ARGUMENTS})
if(arguments)
  set(arguments " '${arguments}'")
endif()
# Start with a carriage return to overwrite the prefix added by CMake.
# https://stackoverflow.com/a/71869855/618906
string(ASCII 13 CR)
message(STATUS "${CR}${executable}${arguments}")
execute_process(COMMAND "${executable}" $ENV{CUPCAKE_EXE_ARGUMENTS})
