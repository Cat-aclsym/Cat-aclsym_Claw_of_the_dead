## © [2026] A7 Studio. All rights reserved. Trademark.
##
## Handles map events such as path unlocks and wave-based path changes.
class_name MapEvents
extends Node

signal event_triggered(event_name: String)
signal path_locked(path_index: int)
signal path_unlocked(path_index: int)

@export var map: IMap = null

## Wave-based path event configuration.
## Format: { wave_number: { "activate": [path_indices], "deactivate": [path_indices] } }
@export var wave_path_events: Dictionary = {}

## Reference to the current level for state and currency checks.
var _level: ILevel = null


func _ready() -> void:
	# Wait one frame to ensure scene references are initialized.
	await get_tree().process_frame
	if not is_instance_valid(map) and get_parent() is IMap:
		map = get_parent() as IMap
	_initialize_paths_for_wave_events()
	_connect_to_level()


func _connect_to_level() -> void:
	if is_instance_valid(ILevel.current_level):
		_level = ILevel.current_level
		if not _level.wave_started.is_connected(on_wave_start):
			_level.wave_started.connect(on_wave_start)
		Log.trace(Log.Level.DEBUG, "MapEvents connected to current level.")


## Configure events for a specific wave.
func set_wave_event(wave_number: int, activate: Array[int] = [], deactivate: Array[int] = []) -> void:
	wave_path_events[wave_number] = {
		"activate": activate,
		"deactivate": deactivate
	}


## Apply configured path events when a wave starts.
func on_wave_start(wave_number: int) -> void:
	if not wave_path_events.has(wave_number):
		return

	if not is_instance_valid(map):
		Log.trace(Log.Level.ERROR, "MapEvents has no valid map reference.")
		return

	var event: Dictionary = wave_path_events[wave_number]
	var to_deactivate: Array = event.get("deactivate", [])
	var to_activate: Array = event.get("activate", [])

	for path_index in to_deactivate:
		map.deactivate_path(path_index)
		path_locked.emit(path_index)

	for path_index in to_activate:
		map.activate_path(path_index)
		path_unlocked.emit(path_index)

	event_triggered.emit("wave_%d_paths" % wave_number)
	Log.trace(Log.Level.INFO, "Applied path events for wave %d." % wave_number)


## Unlock a path after a specific wave.
func unlock_path_after_wave(path_index: int, wave_number: int) -> void:
	set_wave_event(wave_number, [path_index], [])


## Unlock a path by spending coins.
func unlock_path_with_money(path_index: int, cost: int) -> bool:
	if not _ensure_level_reference() or not is_instance_valid(map):
		return false

	if _level.coins >= cost:
		_level.coins -= cost
		map.activate_path(path_index)
		path_unlocked.emit(path_index)
		event_triggered.emit("path_%d_purchased" % path_index)
		return true
	return false


## Close one path, then open another.
func switch_paths(close_index: int, open_index: int) -> void:
	if not is_instance_valid(map):
		return

	map.deactivate_path(close_index)
	map.activate_path(open_index)
	path_locked.emit(close_index)
	path_unlocked.emit(open_index)
	event_triggered.emit("path_switch_%d_to_%d" % [close_index, open_index])


## Activate multiple paths for a rush-mode event.
func activate_rush_mode(path_indices: Array[int]) -> void:
	if not is_instance_valid(map):
		return

	for index in path_indices:
		map.activate_path(index)
		path_unlocked.emit(index)
	event_triggered.emit("rush_mode_activated")


## Deactivate all paths except the initial one.
func reset_to_main_path() -> void:
	if not is_instance_valid(map):
		return

	map.set_active_paths_only([map.initial_path_index])
	event_triggered.emit("paths_reset")


## Activate a random path from a list of indices.
func activate_random_path(path_indices: Array[int]) -> int:
	if not is_instance_valid(map):
		return -1

	if path_indices.is_empty():
		return -1

	var random_index = path_indices[randi() % path_indices.size()]
	map.activate_path(random_index)
	path_unlocked.emit(random_index)
	event_triggered.emit("random_path_%d_activated" % random_index)
	return random_index


## Schedule a callback to run after a delay.
func schedule_event(event_name: String, delay: float, callback: Callable) -> void:
	var timer = get_tree().create_timer(delay)
	await timer.timeout
	callback.call()
	event_triggered.emit(event_name)


## Activate paths when the enemy count is below a threshold.
func check_enemy_count_event(threshold: int, paths_to_activate: Array[int]) -> void:
	if not _ensure_level_reference() or not is_instance_valid(map):
		return

	if _level._enemies_alive <= threshold:
		for path_index in paths_to_activate:
			map.activate_path(path_index)
			path_unlocked.emit(path_index)
		event_triggered.emit("low_enemy_paths_activated")


func _ensure_level_reference() -> bool:
	if is_instance_valid(_level):
		return true

	if is_instance_valid(ILevel.current_level):
		_level = ILevel.current_level
		return true

	Log.trace(Log.Level.WARN, "No active level reference found.")
	return false


func _initialize_paths_for_wave_events() -> void:
	if not is_instance_valid(map) or wave_path_events.is_empty():
		return

	map.set_active_paths_only([map.initial_path_index])
	Log.trace(Log.Level.INFO, "MapEvents initialized active paths from wave configuration.")
