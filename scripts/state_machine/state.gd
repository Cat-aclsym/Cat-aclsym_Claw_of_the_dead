class_name State extends Object

var name: String
var callback: Callable


# core
func _init(new_name: String, new_callback: Callable) -> void:
	name = new_name
	callback = new_callback


func _to_string() -> String:
	return "State(%s)" % name


# public
func handle(args: Array) -> bool:
	return callback.call(args)


# private


# signal


# event


# setget
