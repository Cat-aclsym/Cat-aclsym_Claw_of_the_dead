class_name StateMachineBuilder extends Object


var _state_machine: StateMachine

# core
func _init() -> void:
	_state_machine = StateMachine.new()


# public
func build() -> StateMachine:
	return _state_machine


func build_state(state_id: String, state_callback: Callable) -> StateMachineBuilder:
	var state := StateFactory.create(state_id, state_callback)
	_state_machine.add_state(state_id, state)
	return self


func build_initial_state(state_id: String, state_callback: Callable) -> StateMachineBuilder:
	var state := StateFactory.create(state_id, state_callback)
	_state_machine.add_initial_state(state_id, state)
	return self


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
