class_name StateMachine extends Object

signal state_changed(State)

var name: String
var states: Dictionary # [String => State]
var valid_transition: Array[Transition]
var current_state: State


# core
func _init() -> void:
	name = "StateMachine(%s)" % self
	states = {}
	valid_transition = []
	current_state = null


# public
func toggle_state(state_id: String) -> bool:
	if not state_id in states.keys():
		Log.trace(Log.Level.ERROR, "%s : Unkown state id : '%s'" % [name, state_id])
		return false

	var transition: Transition = _find_transition(current_state, states.get(state_id))
	if transition:
		current_state = states.get(state_id)
		transition.handle()
		Log.trace(Log.Level.DEBUG, "%s : Toggle state %s" % [name, current_state])
		state_changed.emit(current_state)
		return true

	Log.trace(Log.Level.ERROR, "%s : Failed to toggle state %s : invalid transition from %s to %s" % [name, state_id, current_state, states.get(state_id)])
	return false


func toggle_initial_state() -> bool:
	assert(current_state, "Initial state has not be initialized")
	Log.trace(Log.Level.DEBUG, "%s : Toggle initial state %s" % [name, current_state])
	state_changed.emit(current_state)
	return true


func handle_current_state(args: Array) -> bool:
	return current_state.handle(args)


func get_current_state() -> State:
	return current_state


func add_state(state_id: String, new_state: State) -> void:
	assert(not state_id in states.keys(), "%s is already registered" % new_state)
	Log.trace(Log.Level.INFO, "%s : New state %s" % [name, new_state])
	states[state_id] = new_state


func add_initial_state(state_id: String, new_state: State) -> void:
	add_state(state_id, new_state)
	current_state = states.get(state_id)


func add_transition(new_transition: Transition) -> void:
	assert(not _is_transition_valid(new_transition.from, new_transition.to), "%s is already registered" % new_transition)
	Log.trace(Log.Level.INFO, "%s : New transition %s" % [name, new_transition])
	valid_transition.append(new_transition)


# private
func _is_transition_valid(from: State, to: State) -> bool:
	if _find_transition(from, to):
		return true

	return false


func _find_transition(from: State, to: State) -> Transition:
	for tra in valid_transition:
		if tra.from == from and tra.to == to:
			return tra
	return null


# signal


# event


# setget
