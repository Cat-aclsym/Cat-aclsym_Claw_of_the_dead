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
## Returns the command's identifier token.
func command_token() -> String:
	return ""


## Returns the command's description.
func description() -> String:
	return ""


## Returns an array of expected argument types.
func expected_args_types() -> Array[ICommand.Types]:
	return []


## Executes the command with the given arguments.
##
## Returns [constant OK] on success or an error code on failure.
func execute(console: Console, args: Array) -> int:
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
