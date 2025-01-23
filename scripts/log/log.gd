## © 2024 A7 Studio. All rights reserved. Trademark.
##
## A utility class for logging messages with different severity levels.
## Provides functionality for logging to console, file, and debug console if available.
##
## Usage example:
## [codeblock]
## Log.init()  # Initialize the logging system
## Log.trace(Log.Level.INFO, "Game started!")
## Log.trace(Log.Level.ERROR, ["Failed to load resource: ", resource_path])
## [/codeblock]
class_name Log
extends Node

## Enumeration of available log levels in ascending order of severity.
enum Level {
	DEBUG = 0, ## Detailed debugging information
	INFO, ## General information about program execution
	WARN, ## Warnings about potential issues
	ERROR, ## Errors that don't stop program execution
	FATAL, ## Critical errors that may stop program execution
}

## Prefix strings for each log level to improve log readability.
## These prefixes are added to the beginning of each log message.
const PREFIXS: Dictionary = {
	Level.DEBUG: "[DEBUG]",
	Level.INFO: "[ INFO]",
	Level.WARN: "[ WARN]",
	Level.ERROR: "[ERROR]",
	Level.FATAL: "[FATAL]"
}

## Path to the current log file.
## [br]
## The path is generated using the current timestamp when [method Log.init] is called.
static var _log_filepath: String = ""

## Initializes the logging system by creating a new log file.
## [br]
## This method should be called once when the game starts. It creates a new log file
## in the [code]res://log[/code] directory with a timestamp-based filename.
## [br][br]
## The log file format is: [code]YYYY_MM_DD-HH_mm.log[/code]
static func init() -> void:
	_create_log_file()
	Log.trace(Log.Level.INFO, "Logger initialized!")

## Logs a message with the specified severity level.
## [br]
## The message format includes:
## - Timestamp with millisecond precision
## - Log level prefix ([code]PREFIXS[/code])
## - Source file, line number, and function name
## - The actual message
## [br][br]
## @param level The severity level from [enum Level]
## @param args A single message or array of messages to log
## [br]
## Example:
## [codeblock]
## Log.trace(Log.Level.ERROR, ["Failed to load: ", file_path])
## [/codeblock]
static func trace(level: Log.Level, args: Variant) -> void:
	if level == Level.DEBUG and not Global.debug:
		return

	var prefix_1: String = ""
	var stack: Array[Dictionary] = get_stack()

	# Stack can be empty when the game is not running from Godot engine
	if not stack.is_empty():
		var execution_line := stack[1]
		prefix_1 = "{0}::{1}@{2}".format([
			execution_line["source"],
			execution_line["line"],
			execution_line["function"],
		])

	var time: Dictionary = Time.get_time_dict_from_system()
	var milliseconds: int = Time.get_ticks_msec() % 1000
	var prefix_2 := "{0} {1}:{2}:{3}.{4}".format([
		PREFIXS[level],
		time["hour"],
		time["minute"],
		time["second"],
		milliseconds
	])

	var text: String = _format_args(args)
	var output := "{1} - {0} - {2}".format([
		prefix_1,
		prefix_2,
		text,
	])

	_publish_message(output)

## Saves a message to the log file.
## [br]
## If the log file cannot be opened or doesn't exist, the message is silently dropped.
## [br][br]
## @param message The message to append to the log file
static func save_message(message: String) -> void:
	if _log_filepath.is_empty():
		return

	var file := FileAccess.open(_log_filepath, FileAccess.READ_WRITE)
	if not file:
		return

	file.seek_end()
	file.store_string(message + "\n")
	file.close()

## Formats the input arguments into a single string.
## [br]
## If [param args] is not an array, it is converted to a single-element array.
## Each element is converted to a string and separated by spaces.
## [br][br]
## @param args A single value or array of values to format
## @return The formatted string with all arguments concatenated
static func _format_args(args: Variant) -> String:
	var output := ""
	if not args is Array:
		args = [args]

	for arg in args:
		output += arg if arg is String else str(arg)
		output += " "

	return output

## Publishes a message to all configured outputs.
## [br]
## The message is sent to:
## - Terminal (using [method print])
## - Debug console (if [member Global.console] exists)
## - Log file (using [method save_message])
## [br][br]
## @param message The formatted message to publish
static func _publish_message(message: String) -> void:
	print(message)

	if Global.console != null:
		Global.console.push_text(message)

	save_message(message)

## Creates a new log file with the current timestamp.
## [br]
## The file is created in the [code]res://log[/code] directory.
## If the directory doesn't exist, it will be created.
## [br][br]
## The log filename format is: [code]YYYY_MM_DD-HH_mm.log[/code]
static func _create_log_file() -> void:
	var dir := DirAccess.open("res://log")
	if not dir:
		dir = DirAccess.open("res://")
		var err := dir.make_dir("res://log")
		if err != OK:
			Log.trace(Log.Level.ERROR, "Failed to create log directory: %s" % err)
			return

	var current_time := Time.get_datetime_dict_from_system()
	var file_name := "%d_%02d_%02d-%02d_%02d.log" % [
		current_time["year"],
		current_time["month"],
		current_time["day"],
		current_time["hour"],
		current_time["minute"]
	]

	_log_filepath = "res://log/" + file_name

	var file := FileAccess.open(_log_filepath, FileAccess.WRITE)
	if file:
		file.store_string(">>> Log created on %d/%02d/%02d at %02d:%02d\n" % [
			current_time["year"],
			current_time["month"],
			current_time["day"],
			current_time["hour"],
			current_time["minute"]
		])
		file.close()
	else:
		Log.trace(Log.Level.ERROR, "Failed to create log file.")
		_log_filepath = ""
