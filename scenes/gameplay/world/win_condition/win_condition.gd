## © [2024] A7 Studio. All rights reserved. Trademark.
class_name WinConditionEntity
extends Node

## Class with all WinCondition State
##
## Manages game level states like configuring, start/end of wave & level,
## victory, and loss. Uses StateMachine to handle transitions based on
## level status and health. Connects to signal updates for stats and wave completion.
##


# Constants for state names
const STATE_CONFIGURING: String = "StateConfiguring"
const STATE_START_WAVE: String = "StateStartWave"
const STATE_ONGOING_WAVE: String = "StateOngoingWave"
const STATE_END_WAVE: String = "StateEndWave"
const STATE_END_LEVEL: String = "StateEndLevel"
const STATE_VICTORY: String = "StateVictory"
const STATE_LOSE: String = "StateLose"

# Level reference
@export var level: ILevel = null

# State machine instance
var state_machine: StateMachine

func _ready() -> void:
	_setup()

func _setup() -> void:
	_build_state_machine()
	state_machine.toggle_initial_state()

	if not level:
		Log.trace(Log.Level.WARN, "Level reference is missing in WinConditionEntity. Waiting for initialization...")
		return

	_connect_signals()
	Log.trace(Log.Level.INFO, "WinConditionEntity is ready.")

func _process(delta: float) -> void:
	state_machine.handle_current_state([delta])

# Setup the state machine
func _build_state_machine() -> void:
	var builder: StateMachineBuilder = StateMachineBuilder.new()

	builder.build_initial_state(STATE_CONFIGURING, _on_configuring_state)
	builder.build_state(STATE_START_WAVE, _on_start_wave_state)
	builder.build_state(STATE_ONGOING_WAVE, _on_ongoing_wave_state)
	builder.build_state(STATE_END_WAVE, _on_end_wave_state)
	builder.build_state(STATE_VICTORY, _on_victory_state)
	builder.build_state(STATE_LOSE, _on_lose_state)
	builder.build_state(STATE_END_LEVEL, _on_end_level_state)

	builder.build_transition(STATE_CONFIGURING, STATE_START_WAVE, _on_start_wave_state)
	builder.build_transition(STATE_START_WAVE, STATE_ONGOING_WAVE)
	builder.build_transition(STATE_ONGOING_WAVE, STATE_END_WAVE, _on_end_wave_state)
	builder.build_transition(STATE_END_WAVE, STATE_START_WAVE, _on_start_wave_state)
	builder.build_transition(STATE_ONGOING_WAVE, STATE_LOSE, _on_lose_state)
	builder.build_transition(STATE_END_WAVE, STATE_LOSE)
	builder.build_transition(STATE_CONFIGURING, STATE_VICTORY, _on_victory_state)

	state_machine = builder.build()

# Signal connections
func _connect_signals() -> void:
	if not level:
		Log.trace(Log.Level.ERROR, "Cannot connect signals. Level reference is null.")
		return

	SignalUtil.connects([
		{SignalUtil.WHO: level, SignalUtil.WHAT: "stats_updated", SignalUtil.TO: Callable(self, "_evaluate_conditions")}
	])

	if level.map:
		SignalUtil.connects([
			{SignalUtil.WHO: level.map, SignalUtil.WHAT: "wave_complete", SignalUtil.TO: Callable(self, "_on_wave_complete")}
		])
	else:
		Log.trace(Log.Level.ERROR, "Cannot connect 'wave_complete' signal. Level map is null.")

# State callbacks
func _on_configuring_state(_args: Array) -> bool:
	Log.trace(Log.Level.INFO, "Configuring level...")
	state_machine.transition_to(STATE_START_WAVE)
	return true

#Called when the wave is started
func _on_start_wave_state() -> void:
	Log.trace(Log.Level.INFO, "Starting wave...")
	if level and level.map:
		state_machine.transition_to(STATE_ONGOING_WAVE)
	else:
		Log.trace(Log.Level.ERROR, "Level or map is not properly set. Cannot start wave.")

func _on_ongoing_wave_state(_args : Array) -> bool:
	return true

#Called when a wave is ended
func _on_end_wave_state() -> void:
	Log.trace(Log.Level.INFO, "Wave ended.")
	if level.health > 0 and level.map.all_waves_completed:
		state_machine.transition_to(STATE_VICTORY)
	else:
		state_machine.transition_to(STATE_START_WAVE)

# Called when all waves are finished
func _on_end_level_state() -> void:
	Log.trace(Log.Level.INFO, "End of level.")
	if level.health > 0 and level.map.all_waves_completed:
		state_machine.transition_to(STATE_VICTORY)

func _on_victory_state() -> void:
	Log.trace(Log.Level.INFO, "Victory! All waves completed.")

func _on_lose_state() -> void:
	Log.trace(Log.Level.INFO, "Defeat! Health has reached zero.")
	_pause_game()

# Evaluate win/lose conditions
func _evaluate_conditions() -> void:
	if not state_machine:
		Log.trace(Log.Level.ERROR, "State machine reference is null.")
		return

	var current_state: State = state_machine.get_current_state()
	Log.trace(Log.Level.DEBUG, "Current state: %s" % current_state)

	# Prevent redundant transitions
	if current_state in [STATE_VICTORY, STATE_LOSE]:
		return

	if level.health <= 0:
		if current_state.name != STATE_CONFIGURING:
			if state_machine.transition_to(STATE_LOSE):
				Log.trace(Log.Level.INFO, "Successfully transitioned to StateLose.")
			else:
				Log.trace(Log.Level.ERROR, "Failed to transition to StateLose.")
	elif level.map and level.map.all_waves_completed and level.health > 0:
		state_machine.transition_to(STATE_VICTORY)

# Wave complete signal handler
func _on_wave_complete(last_wave: bool) -> void:
	Log.trace(Log.Level.DEBUG, "Transitioning to next wave state.")
	if last_wave:
		state_machine.transition_to(STATE_END_WAVE)
	else:
		state_machine.transition_to(STATE_START_WAVE)
		level.map._start_wave


# Pause the game
func _pause_game() -> void:
	get_tree().paused = true
	Log.trace(Log.Level.INFO, "Game paused.")
