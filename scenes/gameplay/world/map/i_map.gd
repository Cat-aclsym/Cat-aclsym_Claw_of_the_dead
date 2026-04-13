## © [2026] A7 Studio. All rights reserved. Trademark.
##
## Base map class. Handles enemy paths and wave-driven map events.
class_name IMap
extends Node2D

@export var initial_path_index: int = 0
@export var tilemap: TileMap

## Currently active paths available to enemy spawners.
var active_paths: Array[Path2D] = []
## Optional MapEvents node for wave-driven path changes.
var map_events: Node = null
## All path nodes found under the map.
var paths: Array[Path2D] = []

@onready var camera: Camera2D = $Camera2D


# core
func _ready() -> void:
	assert(tilemap != null, "TileMap reference is required.")
	_load_paths()
	_initialize_paths()
	_load_map_events()

	var placement_system: Node = Global.get("cursor")
	if is_instance_valid(placement_system):
		placement_system.tm_ref = tilemap
	else:
		call_deferred("_assign_tilemap_to_cursor")


# public
## Activate a path by its index.
func activate_path(path_index: int) -> void:
	if path_index < 0 or path_index >= paths.size():
		Log.trace(Log.Level.ERROR, "Invalid path index: %d" % path_index)
		return

	var path: Path2D = paths[path_index]
	if path not in active_paths:
		active_paths.append(path)
		path.visible = true
		Log.trace(Log.Level.INFO, "Path %d activated." % path_index)


## Activate multiple paths by their indices.
func activate_paths(path_indices: Array[int]) -> void:
	for index in path_indices:
		activate_path(index)


## Deactivate a path by its index.
func deactivate_path(path_index: int) -> void:
	if path_index < 0 or path_index >= paths.size():
		return

	var path: Path2D = paths[path_index]
	if path in active_paths:
		active_paths.erase(path)
		path.visible = false
		Log.trace(Log.Level.INFO, "Path %d deactivated." % path_index)


## Returns the list of currently active paths.
func get_active_paths() -> Array[Path2D]:
	return active_paths


## Returns a random active path.
func get_random_active_path() -> Path2D:
	if active_paths.is_empty():
		Log.trace(Log.Level.ERROR, "No active path available.")
		return null
	return active_paths[randi() % active_paths.size()]


## Returns the first tower-like node matching the provided node name.
func get_tower_by_name(tower_name: String) -> Node2D:
	for child in get_children():
		if child is Node2D and child.name == tower_name and child.has_method("sell_tower"):
			return child as Node2D
	return null


## Notify the MapEvents node when a wave starts.
func notify_wave_start(wave_number: int) -> void:
	if is_instance_valid(map_events) and map_events.has_method("on_wave_start"):
		map_events.on_wave_start(wave_number)


## Deactivate all paths, then activate only the requested ones.
func set_active_paths_only(path_indices: Array[int]) -> void:
	for i in range(paths.size()):
		deactivate_path(i)
	activate_paths(path_indices)


# private
func _assign_tilemap_to_cursor() -> void:
	var placement_system: Node = Global.get("cursor")
	if is_instance_valid(placement_system):
		placement_system.tm_ref = tilemap


## Load all Path2D nodes under the Paths node.
func _load_paths() -> void:
	var paths_node: Node = $Paths
	var children: Array[Node] = paths_node.get_children()
	for child in children:
		if child is Path2D:
			paths.append(child as Path2D)

	Log.trace(Log.Level.DEBUG, "Loaded %d paths." % paths.size())


## Initialize path visibility: hide all, then activate the configured initial one.
func _initialize_paths() -> void:
	for path in paths:
		path.visible = false

	if initial_path_index >= 0 and initial_path_index < paths.size():
		activate_path(initial_path_index)
	else:
		Log.trace(Log.Level.WARN, "Invalid initial path index.")


## Load the optional MapEvents node if present.
func _load_map_events() -> void:
	if has_node("MapEvents"):
		map_events = get_node("MapEvents")
		Log.trace(Log.Level.DEBUG, "MapEvents node loaded.")
