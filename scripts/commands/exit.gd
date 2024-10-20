## © [2024] A7 Studio. All rights reserved. Trademark.
## Exit game.
extends ICommand


# public
func command_token() -> String:
	return "exit"


func description() -> String:
	return "Exit game."


# private
func _execute(console: Console, _args: Array) -> int:
	console.get_tree().quit() # close game
	queue_free() # force current command memory clean just in case, could be useless
	return ERR_UNKNOWN_BEHAVIOR
