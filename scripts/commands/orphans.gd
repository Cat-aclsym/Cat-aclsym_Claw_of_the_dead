## © [2024] A7 Studio. All rights reserved. Trademark.
##
## Displays all available commands with their descriptions.
## Lists all commands in the [code]COMMANDS_DIRECTORY[/code] with their usage and descriptions.
extends ICommand


# public
func command_token() -> String:
	return "orphans"


func description() -> String:
	return "Call `print_orphan_nodes` method."


# private
func _execute(_console: Console, _args: Array) -> int:
	print_orphan_nodes()
	return OK
