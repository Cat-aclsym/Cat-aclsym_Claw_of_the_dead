class_name Transition extends Object

var from: State
var to: State
var callback: Callable

# core
func _init(new_from: State, new_to: State, new_callback: Callable) -> void:
	from = new_from
	to = new_to
	callback = new_callback


func _to_string() -> String:
	return "Transition(%s => %s: %s)" % [from, to, callback]


func handle() -> void:
	callback.call()

# public


# private


# signal


# event


# setget

