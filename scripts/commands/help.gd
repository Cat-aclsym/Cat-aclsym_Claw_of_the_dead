## © [2024] A7 Studio. All rights reserved. Trademark.
##
## Displays all available commands with their descriptions.
## Lists all commands in the [code]COMMANDS_DIRECTORY[/code] with their usage and descriptions.
extends ICommand


# Public functions
func description() -> String:
	return "Display all commands with their description."


# Private functions
func _execute(console: Console, _args: Array) -> int:
	var cmd_dir := DirAccess.open(Console.COMMANDS_DIRECTORY)
	assert(cmd_dir != null, "Failed to open commands directory")

	var cmd_paths: PackedStringArray = cmd_dir.get_files()

	console.push_text("Available commands:")
	for path in cmd_paths:
		if not path.ends_with(".gd"):
			continue

		var cmd_script := load("%s/%s" % [Console.COMMANDS_DIRECTORY, path])
		if not cmd_script:
			continue

		var cmd: ICommand = cmd_script.new()
		var message: String = " - %s" % path.trim_suffix(".gd")

		var defined_args := cmd.get_args()
		if not defined_args.is_empty():
			for arg in defined_args:
				var arg_name: String = arg.get("name", "arg")
				if arg.get("optional", false):
					message += " [%s]" % arg_name
				else:
					message += " <%s>" % arg_name
		else:
			for arg_type in cmd.expected_args_types():
				message += " <%s>" % type_to_string(arg_type)

		message += ": %s" % cmd.description()
		console.push_text(message)

	return OK
