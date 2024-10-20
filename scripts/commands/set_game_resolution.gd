## © [2024] A7 Studio. All rights reserved. Trademark.
## Set game resolution
extends ICommand


# public
func command_token() -> String:
	return "set_game_resolution"


func description() -> String:
	return "Set game resolution. set_game_resolution weight height"


func expected_args_types() -> Array[ICommand.Types]:
	return [ICommand.Types.ARG_INT, ICommand.Types.ARG_INT]


# private
func _execute(console: Console, args: Array) -> int:
	console.get_viewport().get_window().size = Vector2i(int(args[0]), int(args[1]))
	ProjectSettings.set_setting("display/window/size/width", int(args[0]))
	ProjectSettings.set_setting("display/window/size/height", int(args[1]))

	return OK