## © [2024] A7 Studio. All rights reserved. Trademark.
## Display all commands with their description.
extends ICommand


# public
func command_token() -> String:
	return "help"


func description() -> String:
	return "Display all commands with their description."


# private
func _execute(console: Console, _args: Array) -> int:
	var cmd_dir := DirAccess.open(Console.COMMANDS_DIRECTORY)
	var cmd_paths: PackedStringArray = cmd_dir.get_files()

	for path in cmd_paths:
		var cmd: ICommand = load("%s/%s" % [Console.COMMANDS_DIRECTORY, path]).new()
		var message: String = " -%s" % cmd.command_token()
		
		var f: bool = true
		for arg in cmd.expected_args_types():
			message += " %s" % type_to_string(arg)
			if not f:
				message += ","
			f = false

		message += "\n\t%s" % cmd.description()
		console.push_text(message)

	return OK
