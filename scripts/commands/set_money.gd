## © [2024] A7 Studio. All rights reserved. Trademark.
## Set in game money
extends ICommand


# public
func command_token() -> String:
	return "set_money"


func description() -> String:
	return "Set in game money."


func expected_args_types() -> Array[ICommand.Types]:
	return [ICommand.Types.ARG_INT]


# private
func _execute(console: Console, args: Array) -> int:
	if not ILevel.current_level:
		console.push_error("You must be in a level to use this method")
		return -1

	ILevel.current_level.coins = int(args[0])

	return OK