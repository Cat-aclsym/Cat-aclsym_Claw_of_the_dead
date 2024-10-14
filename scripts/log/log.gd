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

	var stack: Dictionary = get_stack()[1]
	
	var prefix_1: String = "{0}::{1}@{2}".format([
		stack["source"],
		stack["line"],
		stack["function"],
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
	
	var output: String = "{1} - {0} - {2}".format([
		prefix_1,
		prefix_2,
		text
	])
	
	_publish_message(output)


# private
static func _format_args(args: Variant) -> String:
	var output := ""
	
	if ( args is Array ):
		for arg in args:
			if ( arg is String ): output += arg
			else : output += str( arg )
			output += " "
	else:	
		if ( args is String ): output += args
		else : output += str( args )
	
	return output


static func _publish_message(message: String) -> void:
	# terminal output
	print(message)

	# debug console output
	if Global.debug_console:
		Global.debug_console.output_text(message)

	# file output
	if log_filepath:
		 # Open the file in append mode (WRITE_READ mode)
		var file = FileAccess.open(log_filepath, FileAccess.READ_WRITE)

		# Move the file cursor to the end of the file
		if file:
			file.seek_end()
			file.store_string(message + "\n")  # Append the string followed by a newline
			file.close()


static func _create_log_file():
	# Use DirAccess to ensure the directory exists
	var dir = DirAccess.open("res://log")
	if not dir:
		dir = DirAccess.open("res://")
		var err = dir.make_dir("res://log")
		if err != OK:
			Log.trace(Log.Level.ERROR, "Failed to create log directory: %s" % err)
			return

	# Get the current date and time
	var current_time = Time.get_datetime_dict_from_system()

	# Format the name as YYYY_MM_DD-HH_mm
	var file_name = "%d_%02d_%02d-%02d_%02d.log" % [
		current_time["year"], 
		current_time["month"], 
		current_time["day"], 
		current_time["hour"], 
		current_time["minute"]
	]

	# Construct the file path
	log_filepath = "res://log/" + file_name

	# Use FileAccess to create the log file
	var file = FileAccess.open(log_filepath, FileAccess.WRITE)
	if file:
		file.store_string(">>> Log created on %d/%02d/%02d at %02d:%02d\n" % [current_time.year, current_time.month, current_time.day, current_time.hour, current_time.minute])
		file.close()
	else:
		Log.trace(Log.Level.ERROR, "Failed to create log file.")
		log_filepath = ""



# signal


# event


# setget
