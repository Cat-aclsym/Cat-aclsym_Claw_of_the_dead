## © [2024] A7 Studio. All rights reserved. Trademark.
##
## Displays all available commands with their descriptions.
## Lists all commands in the [code]COMMANDS_DIRECTORY[/code] with their usage and descriptions.
extends ICommand


# Public functions
func description() -> String:
	return "Lists all available commands or shows detailed info for a specific one."


func get_args() -> Array[Dictionary]:
	return [{"name": "command", "type": Types.ARG_COMMAND, "optional": true}]


# Private functions
func _execute(console: Console, args: Array) -> int:
	if not args.is_empty():
		var cmd_name: String = args[0]
		var cmd_path := "%s/%s.gd" % [Console.COMMANDS_DIRECTORY, cmd_name]

		if FileAccess.file_exists(cmd_path):
			var cmd_script := load(cmd_path)
			if cmd_script:
				var cmd: ICommand = cmd_script.new()
				var message: String = "> %s" % cmd_name

				var defined_args := cmd.get_args()
				if not defined_args.is_empty():
					for arg in defined_args:
						var arg_name: String = arg.get("name", "arg")
						var arg_type: int = arg.get("type", 0)
						var type_str: String = cmd.type_to_string(arg_type)

						if arg_type == ICommand.Types.ARG_ENUM:
							var enum_values: Array = arg.get("enum_values", [])
							if not enum_values.is_empty():
								type_str = "|".join(enum_values)

						if arg.get("optional", false):
							message += " [%s: %s]" % [arg_name, type_str]
						else:
							message += " <%s: %s>" % [arg_name, type_str]
				else:
					for arg_type in cmd.expected_args_types():
						var type_str: String = cmd.type_to_string(arg_type)
						message += " <%s>" % type_str

				console.push_text(message)
				console.push_text("Description: %s" % cmd.description())
				return OK

		console.push_error("Command '%s' not found." % cmd_name)
		return ERR_UNKNOWN_BEHAVIOR

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
