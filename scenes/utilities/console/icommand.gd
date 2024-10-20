## © [2024] A7 Studio. All rights reserved. Trademark.
class_name ICommand extends Node

const OK: int = 0
const ERR_INVALID_ARGS_TYPES: int = -1
const ERR_INVALID_ARGS_COUNT: int = -2
const ERR_UNKNOWN_BEHAVIOR: int = -3

enum Types {
	ARG_UNKNOWN = 0,
	ARG_BOOL,
	ARG_INT,
	ARG_FLOAT,
	ARG_STRING,
}

# core


# public
func command_token() -> String:
	return ""


func description() -> String:
	return ""


func expected_args_types() -> Array[ICommand.Types]:
	return []


func execute(console: Console, args: Array) -> int:
	if len(args) != len(expected_args_types()):
		return ERR_INVALID_ARGS_COUNT

	if not _validate_args(args):
		return ERR_INVALID_ARGS_TYPES

	return _execute(console, args)


func type_to_string(t: ICommand.Types) -> String:
	if t == ICommand.Types.ARG_INT:
		return "int"
	if t == ICommand.Types.ARG_FLOAT:
		return "float"
	if t == ICommand.Types.ARG_STRING:
		return "string"
	if t == ICommand.Types.ARG_BOOL:
		return "bool"
	return "unknown"


# private
func _execute(_console: Console, _args: Array) -> int:
	return OK


func _validate_args(args: Array) -> bool:
	for i in range(len(args)):
		if not _validate_type(args[i], expected_args_types()[i]):
			return false

	return true


func _validate_type(in_string: String, in_type: ICommand.Types) -> bool:
	if in_type == ICommand.Types.ARG_INT:
		return in_string.is_valid_int()
	if in_type == ICommand.Types.ARG_FLOAT:
		return in_string.is_valid_float()
	if in_type == ICommand.Types.ARG_STRING:
		return true
	if in_type == ICommand.Types.ARG_BOOL:
		return in_string == "true" or in_string == "false"
	return false

# signal


# event


# setget
