## © [2024] A7 Studio. All rights reserved. Trademark.
class_name Log extends Node

enum Level {
	DEBUG = 0,
	INFO,
	WARN,
	ERROR,
	FATAL
}

const PREFIXS: Dictionary = {
	Level.DEBUG: "[DEBUG]",
	Level.INFO: "[ INFO]",
	Level.WARN: "[ WARN]",
	Level.ERROR: "[ERROR]",
	Level.FATAL: "[FATAL]"
}

static var log_filepath: String = ""

# core


# public
static func init() -> void:
	_create_log_file()
	Log.trace(Log.Level.INFO, "Logger initialized!")


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


static func save_message(message: String) -> void:
	if log_filepath:
		 # Open the file in append mode (WRITE_READ mode)
		var file := FileAccess.open(log_filepath, FileAccess.READ_WRITE)

		# Move the file cursor to the end of the file
		if file:
			file.seek_end()
			file.store_string(message + "\n")  # Append the string followed by a newline
			file.close()


# private
static func _format_args(args: Variant) -> String:
	var output := ""
	if not args is Array:
		args = [args]

	for arg in args:
		output += arg if arg is String else str(arg)
		output += " "

	return output


static func _publish_message(message: String) -> void:
	# terminal output
	print(message)

	# debug console output
	if Global.console:
		Global.console.push_text(message)

	# file output
	save_message(message)


static func _create_log_file() -> void:
	# Use DirAccess to ensure the directory exists
	var dir := DirAccess.open("res://log")
	if not dir:
		dir = DirAccess.open("res://")
		var err := dir.make_dir("res://log")
		if err != OK:
			Log.trace(Log.Level.ERROR, "Failed to create log directory: %s" % err)
			return

	# Get the current date and time
	var current_time := Time.get_datetime_dict_from_system()

	# Format the name as YYYY_MM_DD-HH_mm
	var file_name := "%d_%02d_%02d-%02d_%02d.log" % [
		current_time["year"],
		current_time["month"],
		current_time["day"],
		current_time["hour"],
		current_time["minute"]
	]

	# Construct the file path
	log_filepath = "res://log/" + file_name

	# Use FileAccess to create the log file
	var file := FileAccess.open(log_filepath, FileAccess.WRITE)
	if file:
		file.store_string(">>> Log created on %d/%02d/%02d at %02d:%02d\n" % [current_time.year, current_time.month, current_time.day, current_time.hour, current_time.minute])
		file.close()
	else:
		Log.trace(Log.Level.ERROR, "Failed to create log file.")
		log_filepath = ""



# signal


# event


# setget
