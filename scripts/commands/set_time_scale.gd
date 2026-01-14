## © [2024] A7 Studio. All rights reserved. Trademark.
##
## Sets time scale
extends ICommand


# Public functions
func description() -> String:
	return "Set time scale"


func get_args() -> Array[Dictionary]:
	return [{ "name": "timescale", "type": ICommand.Types.ARG_FLOAT, "optional": false }]


# Private functions
func _execute(console: Console, args: Array) -> int:
	var timescale: float = float(args[0])
	if timescale <= 0.0:
		console.push_error("Time scale must be positive.")
		return ERR_UNKNOWN_BEHAVIOR

	Engine.time_scale = timescale
	console.push_text("Set time scale to: %.2f" % timescale)

	return OK
