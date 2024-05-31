# Called by `execute.<name>` custom targets.
execute_process(COMMAND "${executable}" $ENV{CUPCAKE_EXE_ARGUMENTS})
