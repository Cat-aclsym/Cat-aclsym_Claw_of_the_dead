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
	var commands: Dictionary[String, ICommand] = console.get_commands()

	if not args.is_empty():
		var cmd_name: String = String(args[0]).trim_suffix(".gd")
		var cmd: ICommand = commands.get(cmd_name)
		if cmd == null:
			console.push_error_("Command '%s' not found." % cmd_name)
			return ERR_UNKNOWN_BEHAVIOR

		console.push_text("> %s" % cmd_name)
		console.push_text("Description: %s" % cmd.description())
		console.push_text("Usage paths:")
		for path: String in _get_all_paths(cmd, cmd_name, []):
			console.push_text("  %s" % path)
		return OK

	console.push_text("Available commands:")
	for cmd_name: String in commands:
		var cmd: ICommand = commands[cmd_name]
		console.push_text(" - %s: %s" % [("%s %s" % [cmd_name, cmd.get_signature()]).strip_edges(), cmd.description()])

	return OK


func _get_all_paths(cmd: ICommand, current_path: String, fixed_args: Array) -> Array[String]:
	var paths: Array[String] = []
	var args_def: Array[Dictionary] = cmd.get_args_dynamic(fixed_args)

	if fixed_args.size() >= args_def.size():
		paths.append(current_path)
		return paths

	var next_arg_def: Dictionary = args_def[fixed_args.size()]

	if next_arg_def.get("type") == ICommand.Types.ARG_ENUM:
		var enum_values: Array = next_arg_def.get("enum_values", [])
		for val: String in enum_values:
			var new_fixed: Array = fixed_args.duplicate()
			new_fixed.append(val)
			paths.append_array(_get_all_paths(cmd, current_path + " " + val, new_fixed))
	else:
		# For non-enums, we just show the placeholder and stop expanding deeper
		# unless we want to try to find more args. Usually non-enums are the "leaf" of subcommands.
		var placeholder: String = ""
		for i: int in range(fixed_args.size(), args_def.size()):
			var ad: Dictionary = args_def[i]
			var an: String = ad.get("name", "arg")
			var ts: String = cmd.type_to_string(ad.get("type", Types.ARG_UNKNOWN))
			if ad.get("optional", false):
				placeholder += " [%s: %s]" % [an, ts]
			else:
				placeholder += " <%s: %s>" % [an, ts]
		paths.append(current_path + placeholder)

	return paths
