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

# core


# public
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
	
	print(output)



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


# signal


# event


# setget
