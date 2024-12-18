## © [2024] A7 Studio. All rights reserved. Trademark.
## The Transition class represents a transition between two states in a StateMachine
class_name Transition extends Object

var from: State # The state that this transition will progress from
var to: State # The state that this transition will advance to
var callback: Callable # A Callable object which will be executed when the transition is performed

# core
## The constructor for the Transition class
## [param new_from] : The 'from' state for this transition
## [param new_to] : The 'to' state for this transition
## [param new_callback] : A Callable object which will be executed when this transition is performed
func _init(new_from: State, new_to: State, new_callback: Callable) -> void:
	from = new_from
	to = new_to
	callback = new_callback

## Returns a string representation of the Transition for debugging purposes
func _to_string() -> String:
	return "Transition(%s => %s: %s)" % [from, to, callback]

## Performs the transition
## Executes the callback associated with this transition
func handle() -> void:
	callback.call()

# public


# private


# signal


# event


# setget

