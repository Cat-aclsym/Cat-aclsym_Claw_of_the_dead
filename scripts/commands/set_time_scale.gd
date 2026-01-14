## © [2024] A7 Studio. All rights reserved. Trademark.
##
## Sets time scale
extends ICommand


# public
func description() -> String:
	return "Set time scale"


func get_args() -> Array[Dictionary]:
	return [{ "name": "timescale", "type": ICommand.Types.ARG_FLOAT, "optional": false }]


# private
func _execute(_console: Console, args: Array) -> int:
	assert(float(args[0]) > 0.0, "Time scale must be positive")

	Engine.time_scale = float(args[0])

	return OK
