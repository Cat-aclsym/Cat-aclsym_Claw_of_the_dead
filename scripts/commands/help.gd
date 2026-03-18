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
		if cmd_name.ends_with(".gd"):
			cmd_name = cmd_name.trim_suffix(".gd")
		var cmd_path := "%s/%s.gd" % [console.commands_directory, cmd_name]

		if FileAccess.file_exists(cmd_path):
			var cmd_script := load(cmd_path)
			if cmd_script:
				var cmd: ICommand = cmd_script.new()
				console.push_text("> %s" % cmd_name)
				console.push_text("Description: %s" % cmd.description())
				console.push_text("Usage paths:")

				var paths := _get_all_paths(cmd, cmd_name, [])
				for p in paths:
					console.push_text("  %s" % p)

				return OK

		console.push_error_("Command '%s' not found." % cmd_name)
		return ERR_UNKNOWN_BEHAVIOR

	var cmd_dir := DirAccess.open(console.commands_directory)
	assert(cmd_dir != null, "Failed to open commands directory")

	var cmd_paths: PackedStringArray = cmd_dir.get_files()

	console.push_text("Available commands:")
	for path in cmd_paths:
		if not path.ends_with(".gd"):
			continue

		var cmd_script := load("%s/%s" % [console.commands_directory, path])
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

		message += ": %s" % cmd.description()
		console.push_text(message)

	return OK


func _get_all_paths(cmd: ICommand, current_path: String, fixed_args: Array) -> Array[String]:
	var paths: Array[String] = []
	var args_def := cmd.get_args_dynamic(fixed_args)

	if fixed_args.size() >= args_def.size():
		paths.append(current_path)
		return paths

	var next_arg_def := args_def[fixed_args.size()]

	if next_arg_def.get("type") == ICommand.Types.ARG_ENUM:
		var enum_values: Array = next_arg_def.get("enum_values", [])
		for val in enum_values:
			var new_fixed = fixed_args.duplicate()
			new_fixed.append(val)
			paths.append_array(_get_all_paths(cmd, current_path + " " + val, new_fixed))
	else:
		# For non-enums, we just show the placeholder and stop expanding deeper
		# unless we want to try to find more args. Usually non-enums are the "leaf" of subcommands.
		var placeholder = ""
		for i in range(fixed_args.size(), args_def.size()):
			var ad = args_def[i]
			var an = ad.get("name", "arg")
			var ts = cmd.type_to_string(ad.get("type", 0))
			if ad.get("optional", false):
				placeholder += " [%s: %s]" % [an, ts]
			else:
				placeholder += " <%s: %s>" % [an, ts]
		paths.append(current_path + placeholder)

	return paths
