## © [2024] A7 Studio. All rights reserved. Trademark.
## This is the StateMachine class which extends from Object
## It's used to control the different states in our game
class_name StateMachine extends Object

## Signals that is emitted when the state is changed, sending the new sqtate as the argiument
signal state_changed(State)

var name: String #name of the state machine
var states: Dictionary # [String => State] mapping of the state IDs to states
var valid_transition: Array[Transition] # List of valid transitions
var current_state: State # Current state of the state machine


# core
func _init() -> void:
	name = "StateMachine(%s)" % self
	states = {}
	valid_transition = []
	current_state = null


## Method used to change the state
## [param state_id] : ID of the chosen state
## It will validate the transition, and if var id, execute it and emit a state_changed signal
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

## This is used at the start of the game to set the initial state
func toggle_initial_state() -> bool:
	assert(current_state, "Initial state has not be initialized")
	Log.trace(Log.Level.DEBUG, "%s : Toggle initial state %s" % [name, current_state])
	state_changed.emit(current_state)
	return true

## This is used to interact with the current state
func handle_current_state(args: Array) -> bool:
	return current_state.handle(args)

## Getter for current_state
func get_current_state() -> State:
	return current_state

## Public method to add new stated to the state machine
##
## [param state_id] : ID of the state
## [param new_state] : new state to add
func add_state(state_id: String, new_state: State) -> void:
	assert(not state_id in states.keys(), "%s is already registered" % new_state)
	Log.trace(Log.Level.INFO, "%s : New state %s" % [name, new_state])
	states[state_id] = new_state

# Public
## Method to add initial state to the state machine
## [param state_id] : ID of the state
## [param new_state] : new state to add
func add_initial_state(state_id: String, new_state: State) -> void:
	add_state(state_id, new_state)
	current_state = states.get(state_id)

# Public
## Method to add a new transition ti the state machine
## [param new _transition] : new Transition Object
func add_transition(new_transition: Transition) -> void:
	assert(not _is_transition_valid(new_transition.from, new_transition.to), "%s is already registered" % new_transition)
	Log.trace(Log.Level.INFO, "%s : New transition %s" % [name, new_transition])
	valid_transition.append(new_transition)


# private
## This method check if a transition exists between the given states
##
## [param State] : State Object
func _is_transition_valid(from: State, to: State) -> bool:
	if _find_transition(from, to):
		return true

	return false

## This methods finds a transition object between two states
##
## [param State] : State Object
func _find_transition(from: State, to: State) -> Transition:
	for tra in valid_transition:
		if tra.from == from and tra.to == to:
			return tra
	return null

## Method to handle state transitions
func transition_to(state_id: String) -> bool:
	if not states.has(state_id):
		Log.trace(Log.Level.ERROR, "%s : Unknown state id: '%s'" % [name, state_id])
		return false
	var next_state             = states.get(state_id)
	var transition: Transition = _find_transition(current_state, next_state)

	if transition:
		current_state = next_state
		transition.handle() #
		Log.trace(Log.Level.INFO, "%s : Transitioned to state %s" % [name, current_state])
		emit_signal("state_changed", current_state)
		return true
	else:
		Log.trace(Log.Level.ERROR, "%s : Invalid transition from %s to %s" % [name, current_state, state_id])
		return false


# signal


# event


# setget
