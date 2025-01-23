## © [2024] A7 Studio. All rights reserved. Trademark.
## The State class represents a single state in the state machine
## Each state has a name and a callback function that can be executed when the state is entered
class_name State extends Object

var name: String
var callback: Callable


# core
## The constructor for the State class.
## [param new_name] : The name for this state.
## [param new_callback] : A callable object representing the function to be executed when the state is handled.
func _init(new_name: String, new_callback: Callable) -> void:
	name = new_name
	callback = new_callback

## Returns a string representation of the State for debugging purposes
func _to_string() -> String:
	return "State(%s)" % name


# public
## Executes the callback associated with this state, passing in the provided arguments
## [param args] : An Array of arguments to be passed to the callback when it is executed
func handle(args: Array) -> bool:
	return callback.call(args)


# private


# signal


# event


# setget
