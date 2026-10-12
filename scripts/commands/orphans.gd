## © [2026] A7 Studio. All rights reserved. Trademark.
##
## Prints the orphan nodes (nodes outside any scene tree that are not freed) to the output.
extends ICommand


# public
func description() -> String:
	return "Call `print_orphan_nodes` method."


# private
func _execute(_console: Console, _args: Array) -> int:
	Node.print_orphan_nodes()
	return OK
