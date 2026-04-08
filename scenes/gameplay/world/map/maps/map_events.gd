## © [2024] A7 Studio. All rights reserved. Trademark.
##
## Manage map events
## Manage map events, such as path unlocks, wave events, etc.
class_name MapEvents
extends Node

signal path_unlocked(path_index: int)
signal path_locked(path_index: int)
signal event_triggered(event_name: String)

@export var map: IMap

## Configuration of wave-based path unlocks
## Format: { wave_number: { "activate": [path_indices], "deactivate": [path_indices] } }
@export var wave_path_events: Dictionary = {}

## Programmed events to trigger later (e.g., after a delay or condition)
var scheduled_events: Array[Dictionary] = []

## Reference to the current level for accessing stats and state
var _level: ILevel = null


func _ready() -> void:
	# Wait a frame to ensure all nodes are initialized before connecting to the level
	await get_tree().process_frame
	_connect_to_level()


func _connect_to_level() -> void:
	if ILevel.current_level:
		_level = ILevel.current_level
		Log.trace(Log.Level.DEBUG, "MapEvents connecté au niveau")


## Configure events for a specific wave
func set_wave_event(wave_number: int, activate: Array[int] = [], deactivate: Array[int] = []) -> void:
	wave_path_events[wave_number] = {
		"activate": activate,
		"deactivate": deactivate
	}


## Called by the level when a wave starts to apply configured path events
func on_wave_start(wave_number: int) -> void:
	if wave_path_events.has(wave_number):
		var event = wave_path_events[wave_number]

		# Deactivate paths
		if event.has("deactivate"):
			for path_index in event["deactivate"]:
				map.deactivate_path(path_index)
				path_locked.emit(path_index)
		else: error

		# Activate paths
		if event.has("activate"):
			for path_index in event["activate"]:
				map.activate_path(path_index)
				path_unlocked.emit(path_index)
		else: error

		event_triggered.emit("wave_%d_paths" % wave_number)
		Log.trace(Log.Level.INFO, "Événements de chemins appliqués pour la vague %d" % wave_number)


## Unlock a path after a specific wave
func unlock_path_after_wave(path_index: int, wave_number: int) -> void:
	set_wave_event(wave_number, [path_index], [])


## Unlock a path by spending coins, with checks for sufficient funds
func unlock_path_with_money(path_index: int, cost: int) -> bool:
	if _level == null:
		_level = ILevel.current_level

	if _level and _level.coins >= cost:
		_level.coins -= cost
		map.activate_path(path_index)
		path_unlocked.emit(path_index)
		event_triggered.emit("path_%d_purchased" % path_index)
		return true
	return false


## Close then open a path
func switch_paths(close_index: int, open_index: int) -> void:
	map.deactivate_path(close_index)
	map.activate_path(open_index)
	path_locked.emit(close_index)
	path_unlocked.emit(open_index)
	event_triggered.emit("path_switch_%d_to_%d" % [close_index, open_index])


## Active multiple paths for a "rush mode" event, where enemies spawn on all unlocked paths
func activate_rush_mode(path_indices: Array[int]) -> void:
	for index in path_indices:
		map.activate_path(index)
		path_unlocked.emit(index)
	event_triggered.emit("rush_mode_activated")


## Deactivate all paths except the initial one
func reset_to_main_path() -> void:
	map.set_active_paths_only([map.initial_path_index])
	event_triggered.emit("paths_reset")


## Activate a random path from a list of indices
func activate_random_path(path_indices: Array[int]) -> int:
	if path_indices.is_empty():
		return -1

	var random_index = path_indices[randi() % path_indices.size()]
	map.activate_path(random_index)
	path_unlocked.emit(random_index)
	event_triggered.emit("random_path_%d_activated" % random_index)
	return random_index


## Program a callback to be called after a delay
func schedule_event(event_name: String, delay: float, callback: Callable) -> void:
	var timer = get_tree().create_timer(delay)
	await timer.timeout
	callback.call()
	event_triggered.emit(event_name)


## Verify enemy count and activate paths if below a threshold
func check_enemy_count_event(threshold: int, paths_to_activate: Array[int]) -> void:
	if _level == null:
		_level = ILevel.current_level

	if _level and _level._enemies_alive <= threshold:
		for path_index in paths_to_activate:
			map.activate_path(path_index)
			path_unlocked.emit(path_index)
		event_triggered.emit("low_enemy_paths_activated")
