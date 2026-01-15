## © [2024] A7 Studio. All rights reserved. Trademark.
## Sets the game window resolution.
##
## Updates both the window size and project settings with the new resolution.
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

	console.get_viewport().get_window().size = Vector2i(width, height)
	ProjectSettings.set_setting("display/window/size/width", width)
	ProjectSettings.set_setting("display/window/size/height", height)

	return OK
