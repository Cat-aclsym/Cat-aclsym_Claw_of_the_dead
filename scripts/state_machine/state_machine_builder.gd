## © [2024] A7 Studio. All rights reserved. Trademark.
## StateMachineBuilder Builder Pattern
## It makes the construction of objects step by step
## It creates a StateMachine instance and provides methods to configure its states and transitions
class_name StateMachineBuilder extends Object

##
## Instance of of the StateMachne that this builder will use
var _state_machine: StateMachine

# core
func _init() -> void:
	_state_machine = StateMachine.new()

# public
##
## Returns the constructed StateMachine when it's fully built
func build() -> StateMachine:
	return _state_machine

##
## Method to add a state to the StateMachine being built
## It creates a new State with the provided id and callback, adds it to the StateMachine, and returns the builder for chaining
##
## [param state_id] : ID of the State Object
## [param state_callback] :
func build_state(state_id: String, state_callback: Callable) -> StateMachineBuilder:
	var state := StateFactory.create(state_id, state_callback)
	_state_machine.add_state(state_id, state)
	return self

##
## This function adds a new initial state to our StateMachine
## [param state_id] : ID of the state we're adding
## [param state_callback] : The function to call when the state is executed
func build_initial_state(state_id: String, state_callback: Callable) -> StateMachineBuilder:
	var state := StateFactory.create(state_id, state_callback)
	_state_machine.add_initial_state(state_id, state)
	return self

##
## This function adds a new transition between two states in the StateMachine
##
## [param tr_id_from] : The ID of the state we're transitioning from
## [param tr_id_to] : The ID of the state we're transitioning to
## [param new_callback] : The function to call when the transition is executed
func build_transition(tr_id_from: String, tr_id_to: String, new_callback: Callable = func(): pass) -> StateMachineBuilder:
	var transition := TransitionFactory.create(
		_state_machine.states.get(tr_id_from), 
		_state_machine.states.get(tr_id_to),
		new_callback
	)
	_state_machine.add_transition(transition)
	return self


# private


# signal


# event


# setget
