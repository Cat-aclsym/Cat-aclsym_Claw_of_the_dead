## © [2024] A7 Studio. All rights reserved. Trademark.
##
## Exits the game by closing the application window.
## This command immediately terminates the game process and performs cleanup.
extends ICommand


# public
func description() -> String:
	return "Exit game."


# private
func _execute(console: Console, _args: Array) -> int:
	console.get_tree().quit()
	queue_free()
	return ERR_UNKNOWN_BEHAVIOR
