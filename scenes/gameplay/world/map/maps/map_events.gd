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
			SignalUtil.connects([{SignalUtil.WHO: _level, SignalUtil.WHAT: "wave_started", SignalUtil.TO: on_wave_start}])
		Log.trace(Log.Level.DEBUG, "MapEvents connected to current level.")


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

	for path_index: int in to_deactivate:
		map.deactivate_path(path_index)
		path_locked.emit(path_index)

	for path_index: int in to_activate:
		map.activate_path(path_index)
		path_unlocked.emit(path_index)

	event_triggered.emit("wave_%d_paths" % wave_number)
	Log.trace(Log.Level.INFO, "Applied path events for wave %d." % wave_number)


func _initialize_paths_for_wave_events() -> void:
	if not is_instance_valid(map) or wave_path_events.is_empty():
		return

	map.set_active_paths_only([map.initial_path_index])
	Log.trace(Log.Level.INFO, "MapEvents initialized active paths from wave configuration.")
