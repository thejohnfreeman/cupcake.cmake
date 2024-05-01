# Called by `execute.<name>` custom targets.
execute_process(COMMAND "${cmd}" $ENV{CUPCAKE_EXE_ARGUMENTS})
