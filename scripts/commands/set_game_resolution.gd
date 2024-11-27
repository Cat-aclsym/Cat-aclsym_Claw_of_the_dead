## © [2024] A7 Studio. All rights reserved. Trademark.
## Sets the game window resolution.
##
## Updates both the window size and project settings with the new resolution.
extends ICommand


# public
func command_token() -> String:
	return "set_game_resolution"


func description() -> String:
	return "Set game resolution. set_game_resolution width height"


func expected_args_types() -> Array[ICommand.Types]:
	return [ICommand.Types.ARG_INT, ICommand.Types.ARG_INT]


# private
func _execute(console: Console, args: Array) -> int:
	var width: int = int(args[0])
	var height: int = int(args[1])
	assert(width > 0 and height > 0, "Resolution dimensions must be positive")

	console.get_viewport().get_window().size = Vector2i(width, height)
	ProjectSettings.set_setting("display/window/size/width", width)
	ProjectSettings.set_setting("display/window/size/height", height)

	return OK
