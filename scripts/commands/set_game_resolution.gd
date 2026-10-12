## © [2026] A7 Studio. All rights reserved. Trademark.
## Sets the game window resolution.
##
## Resizes the game window for the current session only, the project settings are not changed.
extends ICommand


# Public functions
func description() -> String:
	return "Changes the game window resolution to the specified width and height."


func get_args() -> Array[Dictionary]:
	return [
		{"name": "width", "type": Types.ARG_INT},
		{"name": "height", "type": Types.ARG_INT}
	]


# Private functions
func _execute(console: Console, args: Array) -> int:
	var width: int = int(args[0])
	var height: int = int(args[1])
	assert(width > 0 and height > 0, "Resolution dimensions must be positive")

	console.get_window().size = Vector2i(width, height)

	return OK
