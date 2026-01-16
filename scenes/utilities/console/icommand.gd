## © [2024] A7 Studio. All rights reserved. Trademark.
##
## Base interface for console commands.
## Provides the foundation for creating custom console commands with argument validation and execution handling.
class_name ICommand extends Node

const OK: int = 0
const ERR_INVALID_ARGS_TYPES: int = -1
const ERR_INVALID_ARGS_COUNT: int = -2
const ERR_UNKNOWN_BEHAVIOR: int = -3

## Enumerates the supported argument types for console commands.
enum Types {
	ARG_BOOL,
	ARG_CHALLENGE,
	ARG_COMMAND,
	ARG_ENEMY,
	ARG_ENUM,
	ARG_FLOAT,
	ARG_INGAME_TOWER,
	ARG_INT,
	ARG_LEVEL,
	ARG_STRING,
	ARG_TOWER,
	ARG_UNKNOWN,
}


# Public functions
## Returns the command's description.
func description() -> String:
	return ""


## Returns an array of argument definitions.
## Each definition is a Dictionary with:
## - "name": String (Argument name)
## - "type": ICommand.Types (Argument type)
## - "optional": bool (Whether the argument is optional, default false)
## - "enum_values": Array[String] (For ARG_ENUM, the list of valid values)
func get_args() -> Array[Dictionary]:
	return []


## Returns true if the command accepts a variable number of arguments.
## If true, argument count validation is skipped.
func is_variable_args() -> bool:
	return false


## Executes the command with the given arguments.
##
## Returns [constant OK] on success or an error code on failure.
func execute(console: Console, args: Array) -> int:
	var defined_args := get_args()

	if not defined_args.is_empty():
		var required_count := 0
		for arg in defined_args:
			if not arg.get("optional", false):
				required_count += 1

		if args.size() < required_count or args.size() > defined_args.size():
			return ERR_INVALID_ARGS_COUNT

		for i in range(args.size()):
			var arg_def := defined_args[i]
			if not _validate_type_with_def(args[i], arg_def):
				return ERR_INVALID_ARGS_TYPES

	return _execute(console, args)


## Converts an argument type to its string representation.
func type_to_string(t: ICommand.Types) -> String:
	match t:
		Types.ARG_INT:
			return "int"
		Types.ARG_FLOAT:
			return "float"
		Types.ARG_STRING:
			return "string"
		Types.ARG_BOOL:
			return "bool"
		Types.ARG_COMMAND:
			return "command"
		Types.ARG_TOWER:
			return "tower"
		Types.ARG_ENEMY:
			return "enemy"
		Types.ARG_ENUM:
			return "enum"
		Types.ARG_INGAME_TOWER:
			return "ingame_tower"
		Types.ARG_LEVEL:
			return "level"
		Types.ARG_CHALLENGE:
			return "challenge"
		_:
			return "unknown"


# Private functions
## Implements the command's behavior. Override in derived classes.
func _execute(_console: Console, _args: Array) -> int:
	return OK


func _validate_type(in_string: String, in_type: ICommand.Types) -> bool:
	match in_type:
		Types.ARG_BOOL:
			return in_string == "true" or in_string == "false"
		Types.ARG_FLOAT:
			return in_string.is_valid_float()
		Types.ARG_INT:
			return in_string.is_valid_int()
		Types.ARG_STRING:
			return true
		Types.ARG_COMMAND, Types.ARG_TOWER, Types.ARG_ENEMY, Types.ARG_ENUM, Types.ARG_INGAME_TOWER, Types.ARG_LEVEL, Types.ARG_CHALLENGE:
			return true
		_:
			return false


func _validate_type_with_def(in_string: String, arg_def: Dictionary) -> bool:
	var in_type: ICommand.Types = arg_def.get("type", Types.ARG_UNKNOWN)

	if in_type == Types.ARG_ENUM:
		var enum_values: Array = arg_def.get("enum_values", [])
		if enum_values.is_empty():
			return true
		return in_string in enum_values

	return _validate_type(in_string, in_type)
