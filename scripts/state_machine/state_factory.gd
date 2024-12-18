## © [2024] A7 Studio. All rights reserved. Trademark
## StateFactory is a class that produces State objects.
## It provides a centralized location to construct and manage State instances
## Factory design pattern
class_name StateFactory extends Object


# core


# public
## Static method to create and return a new State object
## [param state_id]: The unique identifier for the new State
## [param state_callback]: A Callable object representing the function to be executed when the new State is handled
static func create(state_id: String, state_callback: Callable) -> State:
	return State.new(state_id, state_callback)


# private


# signal


# event


# setget

