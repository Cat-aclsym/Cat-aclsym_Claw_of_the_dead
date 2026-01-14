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
	ARG_UNKNOWN = 0,
	ARG_BOOL = 1,
	ARG_INT = 2,
	ARG_FLOAT = 3,
	ARG_STRING = 4,
}


# public
## Returns the command's description.
func description() -> String:
	return ""


## Returns an array of expected argument types.
## Deprecated: Use [method get_args] instead.
func expected_args_types() -> Array[ICommand.Types]:
	return []


## Returns an array of argument definitions.
## Each definition is a Dictionary with:
## - "name": String (Argument name)
## - "type": ICommand.Types (Argument type)
## - "optional": bool (Whether the argument is optional, default false)
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
			if not _validate_type(args[i], arg_def.get("type", Types.ARG_UNKNOWN)):
				return ERR_INVALID_ARGS_TYPES

	elif not is_variable_args():
		if len(args) != len(expected_args_types()):
			return ERR_INVALID_ARGS_COUNT

		if not _validate_args(args):
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
		_:
			return "unknown"


# private
## Implements the command's behavior. Override in derived classes.
func _execute(_console: Console, _args: Array) -> int:
	return OK


func _validate_args(args: Array) -> bool:
	for i in range(len(args)):
		if not _validate_type(args[i], expected_args_types()[i]):
			return false
	return true


func _validate_type(in_string: String, in_type: ICommand.Types) -> bool:
	match in_type:
		Types.ARG_INT:
			return in_string.is_valid_int()
		Types.ARG_FLOAT:
			return in_string.is_valid_float()
		Types.ARG_STRING:
			return true
		Types.ARG_BOOL:
			return in_string == "true" or in_string == "false"
		_:
			return false
