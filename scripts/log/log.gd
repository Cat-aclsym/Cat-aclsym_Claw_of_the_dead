## File:	log/log.gd
## Basic logger
## No one use print function anymore
##
## Created: 15/11/2023
class_name Log extends Node

const LOG_LEVEL_INFO := "[INFO ]  "
const LOG_LEVEL_WARN := "[WARN ]  "
const LOG_LEVEL_ERROR := "[ERROR] "
const LOG_LEVEL_DEBUG := "[DEBUG] "


static func info(args: Variant) -> void:
	var output := "{0} {1}".format([
		_log_prefix( LOG_LEVEL_INFO ),
		_format_args( args )
	])
	
	if Global.debug_console:
		Global.debug_console.output_text( output )
	print( output )


static func warning(args: Variant) -> void:
	var output := "{0} {1}".format([
		_log_prefix( LOG_LEVEL_WARN ),
		_format_args( args )
	])
	
	if Global.debug_console:
		Global.debug_console.output_text( output )
	print( output )

	
static func error(args: Variant) -> void:
	var output := "{0} {1}".format([
		_log_prefix( LOG_LEVEL_ERROR ),
		_format_args( args )
	])
	
	if Global.debug_console:
		Global.debug_console.output_text( output )
	print( output )


static func debug(args: Variant) -> void:
	var output := "{0} {1}".format([
		_log_prefix( LOG_LEVEL_DEBUG ),
		_format_args( args )
	])
	
	if Global.debug_console:
		Global.debug_console.output_text( output )
	print( output )


# Format log args to string
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


# Prepare prefix for log message
static func _log_prefix(log_level: String) -> String:	
	var time: Dictionary = Time.get_time_dict_from_system()
	
	var output := "{0} {1}:{2}:{3}\t".format([
		log_level,
		time["hour"],
		time["minute"],
		time["second"],
	])
	
	return output
