## © [2024] A7 Studio. All rights reserved. Trademark.
##
## Sets time scale
extends ICommand


# public
func command_token() -> String:
	return "set_time_scale"


func description() -> String:
	return "Set time scale"


func expected_args_types() -> Array[ICommand.Types]:
	return [ICommand.Types.ARG_FLOAT]


# private
func _execute(_console: Console, args: Array) -> int:
	assert(float(args[0]) > 0.0, "Time scale must be positive")

	Engine.time_scale = float(args[0])

	return OK
