## © [2026] A7 Studio. All rights reserved. Trademark.
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

## Log file kept open for the whole session, [code]null[/code] when file logging is unavailable.
## [br]
## The file is generated using the current timestamp when [method Log.init] is called.
static var _log_file: FileAccess = null

## Initializes the logging system by creating a new log file.
## [br]
## This method should be called once when the game starts. It creates a new log file
## in the [code]res://log[/code] directory with a timestamp-based filename.
## [br][br]
## The log file format is: [code]YYYY_MM_DD-HH_mm.log[/code]
static func init() -> void:
	_create_log_file()
	Log.trace(Log.Level.INFO, "Logger initialized!")

## Closes the log file. Messages are still printed afterwards, but no longer written to disk.
static func close() -> void:
	_log_file = null

## Logs a message with the specified severity level.
## [br]
## The message format includes:
## - Timestamp with millisecond precision
## - Log level prefix ([code]PREFIXS[/code])
## - Source file, line number, and function name (ERROR and FATAL only, [method @GlobalScope.get_stack] is slow)
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

	var time: Dictionary = Time.get_time_dict_from_system()
	var milliseconds: int = Time.get_ticks_msec() % 1000
	var output: String = "{0} {1}:{2}:{3}.{4}".format([
		PREFIXS[level],
		time["hour"],
		time["minute"],
		time["second"],
		milliseconds
	])

	if level >= Level.ERROR:
		# Stack can be empty when the game is not running from Godot engine
		var stack: Array[Dictionary] = get_stack()
		if stack.size() > 1:
			var execution_line: Dictionary = stack[1]
			output += " - {0}::{1}@{2}".format([
				execution_line["source"].get_file(),
				execution_line["line"],
				execution_line["function"],
			])

	output += " - " + _format_args(args)
	_publish_message(output, level >= Level.WARN)

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

	for arg: Variant in args:
		output += arg if arg is String else str(arg)
		output += " "

	return output

## Publishes a message to all configured outputs.
## [br]
## The message is sent to:
## - Terminal (using [method print])
## - Debug console (if [member Global.console] exists, display only)
## - Log file (flushed right away when [param flush] is true)
## [br][br]
## @param message The formatted message to publish
## @param flush Whether the log file is flushed to disk after writing the message
static func _publish_message(message: String, flush: bool) -> void:
	print(message)

	if Global.console != null:
		Global.console.push_text(message)

	if _log_file == null:
		return

	_log_file.store_line(message)
	if flush:
		_log_file.flush()

## Creates a new log file with the current timestamp.
## [br]
## The file is created in the [code]res://log[/code] directory.
## If the directory doesn't exist, it will be created.
## [br][br]
## The log filename format is: [code]YYYY_MM_DD-HH_mm.log[/code]
## If a file with that name already exists, new messages are appended to it.
static func _create_log_file() -> void:
	var dir := DirAccess.open("res://log")
	if not dir:
		dir = DirAccess.open("res://")
		var err := dir.make_dir("res://log")
		if err != OK:
			Log.trace(Log.Level.ERROR, "Failed to create log directory: %s" % err)
			return

	var current_time := Time.get_datetime_dict_from_system()
	var file_path: String = "res://log/%d_%02d_%02d-%02d_%02d.log" % [
		current_time["year"],
		current_time["month"],
		current_time["day"],
		current_time["hour"],
		current_time["minute"]
	]

	_log_file = FileAccess.open(file_path, FileAccess.READ_WRITE if FileAccess.file_exists(file_path) else FileAccess.WRITE_READ)
	if _log_file == null:
		Log.trace(Log.Level.ERROR, "Failed to create log file.")
		return

	_log_file.seek_end()
	_log_file.store_line(">>> Log created on %d/%02d/%02d at %02d:%02d" % [
		current_time["year"],
		current_time["month"],
		current_time["day"],
		current_time["hour"],
		current_time["minute"]
	])
