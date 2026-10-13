## © [2026] A7 Studio. All rights reserved. Trademark.
##
## Finite state machine: states that run an optional callback on each tick, and the transitions allowed between them.
## [br]Example:
## [codeblock]
## var machine: StateMachine = StateMachine.new()
## machine.add_state("IDLE", Callable(), true)
## machine.add_state("RUN", _on_run_tick)
## machine.allow("IDLE", "RUN")
## machine.toggle_state("RUN") # true, an unallowed transition returns false and logs an error
## machine.tick() # calls _on_run_tick
## [/codeblock]
class_name StateMachine extends RefCounted

## Id of the current state, empty until the initial state is added.
var current_state_id: String = ""

## Allowed transitions, keyed by "from>to".
var _transitions: Dictionary[String, bool] = {}
## Tick callback of each state, invalid when the state does nothing on a tick.
var _ticks: Dictionary[String, Callable] = {}


## Registers the state [param id], [param on_tick] runs on each [method tick] while it is the current state.
## [br]The machine starts in the state added with [param initial].
func add_state(id: String, on_tick: Callable = Callable(), initial: bool = false) -> void:
	assert(not _ticks.has(id), "State %s is already registered" % id)
	_ticks[id] = on_tick
	if initial:
		current_state_id = id


## Allows the transition from the state [param from] to the state [param to].
func allow(from: String, to: String) -> void:
	assert(_ticks.has(from) and _ticks.has(to), "Transition %s to %s uses an unknown state" % [from, to])
	_transitions[from + ">" + to] = true


## Runs the tick callback of the current state.
func tick() -> void:
	var on_tick: Callable = _ticks[current_state_id]
	if on_tick.is_valid():
		on_tick.call()


## Moves to the state [param id], returns false and logs an error when the state is unknown or the transition is not allowed.
func toggle_state(id: String) -> bool:
	if not _ticks.has(id):
		Log.trace(Log.Level.ERROR, "StateMachine: unknown state id '%s'" % id)
		return false

	if not _transitions.has(current_state_id + ">" + id):
		Log.trace(Log.Level.ERROR, "StateMachine: failed to toggle state %s: invalid transition from %s" % [id, current_state_id])
		return false

	current_state_id = id
	return true
