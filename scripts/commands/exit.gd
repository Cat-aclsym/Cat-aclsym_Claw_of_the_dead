## © [2024] A7 Studio. All rights reserved. Trademark.
##
## Exits the game by closing the application window.
## This command immediately terminates the game process and performs cleanup.
extends ICommand


# Public functions
func description() -> String:
	return "Closes the game and terminates the application."


# Private functions
func _execute(console: Console, _args: Array) -> int:
	console.get_tree().quit()
	return OK
