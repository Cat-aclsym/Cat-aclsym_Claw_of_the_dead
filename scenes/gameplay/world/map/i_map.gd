## © [2026] A7 Studio. All rights reserved. Trademark.
##
## Base class for game maps. Manages tile-based map layout.
## @tutorial: See map_1.tscn for implementation example
class_name IMap
extends Node2D

var BONUS_TILE_SCENE: PackedScene = load("res://scenes/gameplay/world/map/bonus_tile.tscn") as PackedScene
var MALUS_TILE_SCENE: PackedScene = load("res://scenes/gameplay/world/map/malus_tile.tscn") as PackedScene
var BONUS_SPAWN_SCENE: PackedScene = load("res://scenes/gameplay/world/map/bonus_spawn.tscn") as PackedScene
var PATH_INDICATOR_SCRIPT: Script = load("res://scenes/gameplay/world/map/path_indicator.gd") as Script
const BONUS_TILE_LAYER_NAME: String = "Special Bonus"
const BONUS_TILE_LAYER_Z_INDEX: int = -16
const SPECIAL_TILE_DEBUG_COLOR: Color = Color(0.2, 0.4, 1.0, 0.55)
const SPECIAL_TILE_DEBUG_EXCLUSION_COLOR: Color = Color(1.0, 0.2, 0.2, 0.35)
const SPECIAL_TILE_LAYER_INDEX: int = 3
const SPECIAL_TILE_MAX_DISTANCE_TILES: float = 2.0
const SPECIAL_TILE_MIN_DISTANCE_BETWEEN_TILES: float = 2.0
const MAP_PLACEMENT_BLOCKER_SCRIPT: Script = preload(
	"res://scenes/gameplay/world/map/map_placement_blocker.gd"
)

## Intro sequence timings for special tiles.
const SPECIAL_TILE_INTRO_INITIAL_DELAY_SECONDS: float = 1.5

## Spawn animation timings and placement offsets.
const SPECIAL_TILE_SPAWN_ANIMATION_DURATION_SECONDS: float = 0.4
const SPECIAL_TILE_SPAWN_APPLY_RATIO: float = 0.66
const SPECIAL_TILE_SPAWN_DROP_HEIGHT_PIXELS: float = 128.0
const SPECIAL_TILE_SPAWN_TINT_WHITE_BLEND: float = 0.5
const SPECIAL_TILE_SPAWN_SHAKE_STRENGTH: float = 10.0
const SPECIAL_TILE_SPAWN_STAGGER_SECONDS: float = 0.2
const MALUS_TILE_SPAWN_INTERVAL_SECONDS: float = 0.12
const PATH_INDICATOR_END_TYPE: int = 1
const PATH_INDICATOR_START_TYPE: int = 0

@export var debug_show_spawnable_special_tiles: bool = false
@export var initial_path_index: int = 0
@export_range(0.0, 100.0, 0.1) var special_tile_percentage: float = 2.0

## Reference to the TileMap node for map layout
@export var tilemap: TileMap

## Array of paths that enemies can follow
var paths: Array[Path2D] = []
var _active_paths_lookup: Dictionary = {}

var _debug_exclusion_overlays: Array[Node2D] = []
var _debug_spawnable_overlays: Array[Node2D] = []

var _bonus_tile_scene_source_id: int = -1
var _bonus_tile_scene_tile_id: int = -1
var _malus_tile_scene_source_id: int = -1
var _malus_tile_scene_tile_id: int = -1
var _placement_blocked_cells: Dictionary = {}

## Dictionary of special tiles (position -> modifier data)
var special_tiles: Dictionary = {}
var _pending_special_tile_spawns: Array[Dictionary] = []

@onready var camera: Camera2D = $Camera2D

# core
func _ready() -> void:
	_load_paths()
	_create_path_indicators()
	_ensure_special_tile_layer()
	_ensure_bonus_tile_scene_source()
	_ensure_malus_tile_scene_source()

	var placement_system: BuildPlacement = Global.get("cursor") as BuildPlacement
	if placement_system:
		placement_system.tm_ref = tilemap
	else:
		# If cursor is not yet initialized, wait a frame
		call_deferred("_assign_tilemap_to_cursor")

	_register_placement_blockers()
	_sync_placement_blocked_cells_to_cursor()

	# Generate special tiles immediately
	_generate_special_tiles()

func _assign_tilemap_to_cursor() -> void:
	var placement_system: BuildPlacement = Global.get("cursor") as BuildPlacement
	if placement_system:
		placement_system.tm_ref = tilemap
		_sync_placement_blocked_cells_to_cursor()

#public
func play_special_tiles_intro_sequence() -> void:
	if _pending_special_tile_spawns.is_empty():
		return

	await get_tree().create_timer(SPECIAL_TILE_INTRO_INITIAL_DELAY_SECONDS).timeout

	var bonus_spawn_queue: Array[Dictionary] = []
	var malus_spawn_queue: Array[Dictionary] = []
	for spawn_data in _pending_special_tile_spawns:
		if bool(spawn_data.get("is_bonus", false)):
			bonus_spawn_queue.append(spawn_data)
		else:
			malus_spawn_queue.append(spawn_data)

	bonus_spawn_queue.shuffle()
	malus_spawn_queue.shuffle()

	for i in range(bonus_spawn_queue.size()):
		_spawn_special_tile_with_intro_animation(bonus_spawn_queue[i])
		if i < bonus_spawn_queue.size() - 1:
			await get_tree().create_timer(SPECIAL_TILE_SPAWN_STAGGER_SECONDS).timeout

	for i in range(malus_spawn_queue.size()):
		_spawn_special_tile_with_intro_animation(malus_spawn_queue[i])
		if i < malus_spawn_queue.size() - 1:
			await get_tree().create_timer(MALUS_TILE_SPAWN_INTERVAL_SECONDS).timeout

	_pending_special_tile_spawns.clear()

func get_tower_by_name(tower_name: String) -> ITower:
	for child in get_children():
		if child is ITower:
			var tower: ITower = child as ITower
			if tower.name == tower_name:
				return tower
	return null


## Activates a path so enemy spawners can use it.
func activate_path(path_index: int) -> bool:
	if not _is_valid_path_index(path_index):
		return false

	_active_paths_lookup[path_index] = true
	return true


## Deactivates a path so enemy spawners stop using it.
func deactivate_path(path_index: int) -> bool:
	if not _is_valid_path_index(path_index):
		return false

	_active_paths_lookup.erase(path_index)
	return true


## Returns all currently active spawn paths.
func get_active_paths() -> Array[Path2D]:
	var active_paths: Array[Path2D] = []
	for index in get_active_path_indices():
		active_paths.append(paths[index])

	return active_paths


## Returns currently active path indices.
func get_active_path_indices() -> Array[int]:
	var active_indices: Array[int] = []
	for index in range(paths.size()):
		if _active_paths_lookup.has(index):
			active_indices.append(index)

	return active_indices


## Returns a random active path, or null if none are active.
func get_random_active_path() -> Path2D:
	var active_paths: Array[Path2D] = get_spawn_paths()
	if active_paths.is_empty():
		return null

	return active_paths[randi() % active_paths.size()]


## Returns paths allowed for enemy spawning.
func get_spawn_paths() -> Array[Path2D]:
	return get_active_paths()


## Returns true when the path index is currently active.
func is_path_active(path_index: int) -> bool:
	return _active_paths_lookup.has(path_index)


## Replaces current active paths with the provided indices.
func set_active_paths_only(path_indices: Array[int]) -> void:
	_active_paths_lookup.clear()

	for path_index in path_indices:
		if _is_valid_path_index(path_index):
			_active_paths_lookup[path_index] = true

	if _active_paths_lookup.is_empty():
		Log.trace(Log.Level.WARN, "Map has no active paths after set_active_paths_only().")

# private

## Loads path nodes from the Paths node
func _load_paths() -> void:
	if not has_node("Paths"):
		Log.trace(Log.Level.WARN, "No Paths node found in map")
		return

	paths.clear()
	var children: Array[Node] = $Paths.get_children()

	for child in children:
		if (child is Path2D):
			paths.append(child as Path2D)

	_initialize_active_paths()

func _create_path_indicators() -> void:
	for path in paths:
		var curve = path.curve
		if curve.get_point_count() < 2:
			continue

		# Start point
		var start_pos = path.to_global(curve.get_point_position(0))
		_instantiate_indicator(start_pos, Color(0.1, 0.9, 0.1), PATH_INDICATOR_START_TYPE)

		# End point
		var end_pos = path.to_global(curve.get_point_position(curve.get_point_count() - 1))
		_instantiate_indicator(end_pos, Color(0.9, 0.1, 0.1), PATH_INDICATOR_END_TYPE)

func _instantiate_indicator(global_pos: Vector2, color: Color, point_type: int) -> void:
	var indicator = PATH_INDICATOR_SCRIPT.new()
	indicator.position = to_local(global_pos)
	indicator.base_color = color
	indicator.type = point_type
	indicator.z_index = 1 # Above the ground tiles
	add_child(indicator)

func _generate_special_tiles() -> void:
	if not tilemap:
		return

	var buildable_tiles: Array[Vector2i] = []
	var used_rect := tilemap.get_used_rect()

	for x in range(used_rect.position.x, used_rect.end.x):
		for y in range(used_rect.position.y, used_rect.end.y):
			var coords := Vector2i(x, y)
			if _is_tile_buildable(coords):
				buildable_tiles.append(coords)

	Log.trace(Log.Level.INFO, "Found {0} buildable tiles for special tiles".format([buildable_tiles.size()]))

	if paths.is_empty():
		Log.trace(Log.Level.WARN, "No enemy paths defined, cannot place special tiles near paths")
		return

	var spawnable_tiles := _get_spawnable_special_tiles(buildable_tiles)

	Log.trace(
		Log.Level.INFO,
		"Found {0} tiles at <= 3 tiles distance from paths for special tiles".format([spawnable_tiles.size()])
	)

	if debug_show_spawnable_special_tiles:
		_show_debug_spawnable_special_tiles(spawnable_tiles)
	else:
		_clear_debug_exclusion_tiles()
		_clear_debug_spawnable_special_tiles()

	special_tiles.clear()
	_pending_special_tile_spawns.clear()
	_clear_special_tile_layer()

	var bonus_tile_count: int = 0
	if buildable_tiles.size() > 0:
		bonus_tile_count = int(ceil(float(buildable_tiles.size()) * special_tile_percentage / 100.0))
		if special_tile_percentage > 0.0:
			bonus_tile_count = maxi(1, bonus_tile_count)
	if bonus_tile_count == 0:
		return

	if spawnable_tiles.size() < bonus_tile_count:
		Log.trace(
			Log.Level.WARN,
			"Not enough tiles near paths for special tiles: need {0}, found {1}".format([bonus_tile_count, spawnable_tiles.size()])
		)
		return

	spawnable_tiles.shuffle()

	_clear_debug_exclusion_tiles()

	var selected_special_tiles: Array[Vector2i] = []
	for candidate in spawnable_tiles:
		if not _is_special_tile_spawnable(candidate, selected_special_tiles):
			continue

		selected_special_tiles.append(candidate)
		if selected_special_tiles.size() >= bonus_tile_count:
			break

	if selected_special_tiles.size() < bonus_tile_count:
		Log.trace(
			Log.Level.WARN,
			"Not enough tiles to place special tiles with min separation (%s). Need %s, found %s".format([
				SPECIAL_TILE_MIN_DISTANCE_BETWEEN_TILES,
				bonus_tile_count,
				selected_special_tiles.size()
			])
		)
		return

	var bonus_types = [
		{"fire_rate": 1.3, "color": Color(0.2, 1.0, 0.2, 0.5), "label": "SPEED+"},
		{"damage": 1.3, "color": Color(0.2, 0.2, 1.0, 0.5), "label": "DMG+"},
		{"reward_multiplier": 1.5, "color": Color(1.0, 0.8, 0.2, 0.5), "label": "GOLD+"}
	]

	var malus_types = [
		{"fire_rate": 0.7, "color": Color(0.62, 0.18, 0.22, 0.5), "label": "SPEED-"},
		{"damage": 0.7, "color": Color(0.58, 0.30, 0.16, 0.5), "label": "DMG-"},
		{"shoot_range": 0.7, "color": Color(0.42, 0.20, 0.48, 0.5), "label": "RANGE-"}
	]

	var selected_bonus_tiles: Array[Vector2i] = []
	for i in range(bonus_tile_count):
		var tile_pos = selected_special_tiles.pop_back()
		selected_bonus_tiles.append(tile_pos)
		var modifier = bonus_types[i % bonus_types.size()]
		_pending_special_tile_spawns.append({
			"tile_pos": tile_pos,
			"modifier": modifier,
			"is_bonus": true
		})
		if debug_show_spawnable_special_tiles:
			_show_debug_exclusion_tiles_around(tile_pos)
		Log.trace(Log.Level.INFO, "Queued bonus tile at {0}: {1}".format([tile_pos, modifier["label"]]))

	var malus_tiles: Array[Vector2i] = _get_malus_tiles_around_bonus(selected_bonus_tiles, spawnable_tiles)
	for i in range(malus_tiles.size()):
		var tile_pos = malus_tiles[i]
		var modifier = malus_types[i % malus_types.size()]
		_pending_special_tile_spawns.append({
			"tile_pos": tile_pos,
			"modifier": modifier,
			"is_bonus": false
		})
		if debug_show_spawnable_special_tiles:
			_show_debug_exclusion_tiles_around(tile_pos)
		Log.trace(Log.Level.INFO, "Queued malus tile at {0}: {1}".format([tile_pos, modifier["label"]]))

func _get_malus_tiles_around_bonus(bonus_tiles: Array[Vector2i], spawnable_tiles: Array[Vector2i]) -> Array[Vector2i]:
	var spawnable_lookup: Dictionary = {}
	for tile_pos in spawnable_tiles:
		spawnable_lookup[tile_pos] = true

	var bonus_lookup: Dictionary = {}
	for tile_pos in bonus_tiles:
		bonus_lookup[tile_pos] = true

	var malus_lookup: Dictionary = {}
	for bonus_tile in bonus_tiles:
		for dx in range(-1, 2):
			for dy in range(-1, 2):
				if dx == 0 and dy == 0:
					continue

				var candidate := bonus_tile + Vector2i(dx, dy)
				if bonus_lookup.has(candidate):
					continue
				if not spawnable_lookup.has(candidate):
					continue

				malus_lookup[candidate] = true

	var malus_tiles: Array[Vector2i] = []
	for tile_pos in malus_lookup.keys():
		malus_tiles.append(tile_pos)

	return malus_tiles

func _is_special_tile_spawnable(candidate: Vector2i, already_selected: Array[Vector2i]) -> bool:
	for other in already_selected:
		if candidate.distance_to(other) < SPECIAL_TILE_MIN_DISTANCE_BETWEEN_TILES:
			return false
	return true

func _clear_debug_exclusion_tiles() -> void:
	for node in _debug_exclusion_overlays:
		if is_instance_valid(node):
			node.queue_free()
	_debug_exclusion_overlays.clear()

func _show_debug_exclusion_tiles_around(center: Vector2i) -> void:
	# Draw an exclusion disk of radius < 2 around the special tile (in tile units)
	var radius := int(ceil(SPECIAL_TILE_MIN_DISTANCE_BETWEEN_TILES))
	for dx in range(-radius, radius + 1):
		for dy in range(-radius, radius + 1):
			var coords := center + Vector2i(dx, dy)
			if coords == center:
				continue
			if center.distance_to(coords) < SPECIAL_TILE_MIN_DISTANCE_BETWEEN_TILES:
				_create_debug_tile_overlay(coords, SPECIAL_TILE_DEBUG_EXCLUSION_COLOR, _debug_exclusion_overlays)

func _get_spawnable_special_tiles(buildable_tiles: Array[Vector2i]) -> Array[Vector2i]:
	var origin := tilemap.map_to_local(Vector2i.ZERO)
	var neighbor := tilemap.map_to_local(Vector2i(1, 0))
	var tile_step_distance: float = origin.distance_to(neighbor)
	if tile_step_distance <= 0.0:
		tile_step_distance = 32.0

	var max_distance_to_path: float = tile_step_distance * SPECIAL_TILE_MAX_DISTANCE_TILES

	var spawnable_tiles: Array[Vector2i] = []
	for coords in buildable_tiles:
		var world_pos := tilemap.map_to_local(coords)
		var min_distance := INF

		for path in paths:
			if not path.curve:
				continue

			var closest_point := path.curve.get_closest_point(path.to_local(world_pos))
			var distance := world_pos.distance_to(path.to_global(closest_point))
			if distance < min_distance:
				min_distance = distance

		if min_distance <= max_distance_to_path:
			spawnable_tiles.append(coords)

	return spawnable_tiles

func _clear_debug_spawnable_special_tiles() -> void:
	for node in _debug_spawnable_overlays:
		if is_instance_valid(node):
			node.queue_free()
	_debug_spawnable_overlays.clear()

func _clear_special_tile_layer() -> void:
	if not tilemap:
		return

	if tilemap.get_layers_count() > SPECIAL_TILE_LAYER_INDEX:
		tilemap.clear_layer(SPECIAL_TILE_LAYER_INDEX)

func _create_debug_tile_overlay(tile_pos: Vector2i, color: Color, overlays: Array[Node2D]) -> void:
	var world_pos := tilemap.map_to_local(tile_pos)

	var poly := Polygon2D.new()
	var half_height := 16.0
	var half_width := 32.0
	var points := PackedVector2Array([
		Vector2(0, -half_height),
		Vector2(half_width, 0),
		Vector2(0, half_height),
		Vector2(-half_width, 0),
	])

	poly.color = color
	poly.polygon = points
	poly.position = world_pos
	poly.z_index = 0
	add_child(poly)
	overlays.append(poly)

func _show_debug_spawnable_special_tiles(spawnable_tiles: Array[Vector2i]) -> void:
	_clear_debug_spawnable_special_tiles()
	for tile_pos in spawnable_tiles:
		_create_debug_tile_overlay(tile_pos, SPECIAL_TILE_DEBUG_COLOR, _debug_spawnable_overlays)

func _create_bonus_visual_indicator(tile_pos: Vector2i, _modifier: Dictionary) -> void:
	if not tilemap:
		return

	if _bonus_tile_scene_source_id < 0 or _bonus_tile_scene_tile_id < 0:
		Log.trace(Log.Level.ERROR, "Bonus tile scene source is not ready")
		return

	tilemap.set_cell(
		SPECIAL_TILE_LAYER_INDEX,
		tile_pos,
		_bonus_tile_scene_source_id,
		Vector2i.ZERO,
		_bonus_tile_scene_tile_id
	)

func _create_malus_visual_indicator(tile_pos: Vector2i, _modifier: Dictionary) -> void:
	if not tilemap:
		return

	if _malus_tile_scene_source_id < 0 or _malus_tile_scene_tile_id < 0:
		Log.trace(Log.Level.ERROR, "Malus tile scene source is not ready")
		return

	tilemap.set_cell(
		SPECIAL_TILE_LAYER_INDEX,
		tile_pos,
		_malus_tile_scene_source_id,
		Vector2i.ZERO,
		_malus_tile_scene_tile_id
	)

func _spawn_special_tile_with_intro_animation(spawn_data: Dictionary) -> void:
	if not tilemap:
		return

	var tile_pos: Vector2i = spawn_data.get("tile_pos", Vector2i.ZERO)
	if special_tiles.has(tile_pos):
		return

	var modifier: Dictionary = spawn_data.get("modifier", {})
	var world_pos: Vector2 = tilemap.map_to_local(tile_pos)
	var is_bonus: bool = bool(spawn_data.get("is_bonus", false))
	var spawn_fx: Node2D = null
	if is_bonus:
		spawn_fx = _create_bonus_spawn_animation(world_pos, modifier)

	await get_tree().create_timer(SPECIAL_TILE_SPAWN_ANIMATION_DURATION_SECONDS * SPECIAL_TILE_SPAWN_APPLY_RATIO).timeout

	special_tiles[tile_pos] = modifier
	if is_bonus:
		_create_bonus_visual_indicator(tile_pos, modifier)
	else:
		_create_malus_visual_indicator(tile_pos, modifier)

	tilemap.update_internals()
	if is_bonus:
		_trigger_special_tile_spawn_shake()

	var remaining_duration := SPECIAL_TILE_SPAWN_ANIMATION_DURATION_SECONDS * (1.0 - SPECIAL_TILE_SPAWN_APPLY_RATIO)
	if remaining_duration > 0.0:
		await get_tree().create_timer(remaining_duration).timeout

	if is_instance_valid(spawn_fx):
		spawn_fx.queue_free()


func _create_bonus_spawn_animation(world_pos: Vector2, modifier: Dictionary) -> Node2D:
	if BONUS_SPAWN_SCENE == null:
		return null

	var spawn_fx := BONUS_SPAWN_SCENE.instantiate() as Node2D
	if spawn_fx == null:
		return null

	spawn_fx.z_as_relative = false
	spawn_fx.z_index = int(world_pos.y) + 64
	spawn_fx.scale = Vector2.ONE * 1.12

	var spawn_tint: Color = Color.WHITE
	if modifier.has("color"):
		spawn_tint = (modifier["color"] as Color).lerp(Color.WHITE, SPECIAL_TILE_SPAWN_TINT_WHITE_BLEND)
	spawn_tint.a = 0.95
	spawn_fx.modulate = spawn_tint

	spawn_fx.position = world_pos + Vector2(0.0, -SPECIAL_TILE_SPAWN_DROP_HEIGHT_PIXELS)
	add_child(spawn_fx)

	var animated_sprite := spawn_fx.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if animated_sprite:
		animated_sprite.play("spawn")

	create_tween().tween_property(
		spawn_fx,
		"position",
		world_pos,
		SPECIAL_TILE_SPAWN_ANIMATION_DURATION_SECONDS
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	return spawn_fx

func _trigger_special_tile_spawn_shake() -> void:
	if Global.camera:
		Global.camera.shake_camera_with_strength(SPECIAL_TILE_SPAWN_SHAKE_STRENGTH)

func _ensure_special_tile_layer() -> void:
	if not tilemap:
		return

	while tilemap.get_layers_count() <= SPECIAL_TILE_LAYER_INDEX:
		tilemap.add_layer(-1)

	tilemap.set_layer_name(SPECIAL_TILE_LAYER_INDEX, BONUS_TILE_LAYER_NAME)
	tilemap.set_layer_y_sort_enabled(SPECIAL_TILE_LAYER_INDEX, false)
	tilemap.set_layer_z_index(SPECIAL_TILE_LAYER_INDEX, BONUS_TILE_LAYER_Z_INDEX)
	tilemap.set_layer_modulate(SPECIAL_TILE_LAYER_INDEX, Color.WHITE)

func _ensure_bonus_tile_scene_source() -> void:
	if not tilemap or not tilemap.tile_set:
		return
	if BONUS_TILE_SCENE == null:
		Log.trace(Log.Level.ERROR, "Bonus tile scene is not loaded")
		return
	if _bonus_tile_scene_source_id >= 0:
		return

	var scene_source := TileSetScenesCollectionSource.new()
	_bonus_tile_scene_tile_id = scene_source.create_scene_tile(BONUS_TILE_SCENE)
	_bonus_tile_scene_source_id = tilemap.tile_set.add_source(scene_source, tilemap.tile_set.get_next_source_id())

	if _bonus_tile_scene_source_id < 0 or not (tilemap.tile_set.get_source(_bonus_tile_scene_source_id) is TileSetScenesCollectionSource):
		Log.trace(Log.Level.ERROR, "Failed to create bonus tile scene source")
		_bonus_tile_scene_source_id = -1
		_bonus_tile_scene_tile_id = -1

func _ensure_malus_tile_scene_source() -> void:
	if not tilemap or not tilemap.tile_set:
		return
	if MALUS_TILE_SCENE == null:
		Log.trace(Log.Level.ERROR, "Malus tile scene is not loaded")
		return
	if _malus_tile_scene_source_id >= 0:
		return

	var scene_source := TileSetScenesCollectionSource.new()
	_malus_tile_scene_tile_id = scene_source.create_scene_tile(MALUS_TILE_SCENE)
	_malus_tile_scene_source_id = tilemap.tile_set.add_source(scene_source, tilemap.tile_set.get_next_source_id())

	if _malus_tile_scene_source_id < 0 or not (tilemap.tile_set.get_source(_malus_tile_scene_source_id) is TileSetScenesCollectionSource):
		Log.trace(Log.Level.ERROR, "Failed to create malus tile scene source")
		_malus_tile_scene_source_id = -1
		_malus_tile_scene_tile_id = -1

func _is_tile_buildable(coords: Vector2i) -> bool:
	if _placement_blocked_cells.has(coords):
		return false

	# 1. Check if the base tile is valid
	if tilemap.get_cell_source_id(0, coords) != BuildPlacement.VALID_SOURCE_ID or not tilemap.get_cell_atlas_coords(0, coords) in BuildPlacement.VALID_TILES:
		return false

	# 2. Check if there are obstacles on layer 1 (Water Rays, etc.)
	if tilemap.get_cell_atlas_coords(1, coords) != Vector2i(-1, -1):
		return false

	# 3. Check if there are props on layer 2 that might block (if layer 2 is used for blocking)

	# (Optionnel, selon votre projet. BuildPlacement ne semble pas vérifier le layer 2)

	# 4. Check if it's on an enemy path
	var world_pos = tilemap.map_to_local(coords)

	var placement_half_size: float = 12.5 # matching BuildPlacement.placement_half_size

	for path in paths:
		var closest_point = path.curve.get_closest_point(path.to_local(world_pos))
		var distance = world_pos.distance_to(path.to_global(closest_point))
		if distance < placement_half_size:
			return false

	return true


func _collect_placement_blockers(node: Node, blockers: Array[Node2D]) -> void:
	for child: Node in node.get_children():
		if _is_map_placement_blocker(child):
			blockers.append(child as Node2D)
		_collect_placement_blockers(child, blockers)


func _find_placement_blockers() -> Array[Node2D]:
	var blockers: Array[Node2D] = []
	_collect_placement_blockers(self, blockers)
	return blockers


func _get_placement_blocker_cells(blocker: Node2D) -> Array[Vector2i]:
	return blocker.call(&"get_blocked_cells", tilemap) as Array[Vector2i]


func _is_map_placement_blocker(node: Node) -> bool:
	return node.get_script() == MAP_PLACEMENT_BLOCKER_SCRIPT


func _register_placement_blockers() -> void:
	if tilemap == null:
		return

	_placement_blocked_cells.clear()
	for blocker: Node2D in _find_placement_blockers():
		for cell: Vector2i in _get_placement_blocker_cells(blocker):
			_placement_blocked_cells[cell] = true


func _sync_placement_blocked_cells_to_cursor() -> void:
	var placement_system: BuildPlacement = Global.cursor as BuildPlacement
	if placement_system == null:
		return

	for cell: Vector2i in _placement_blocked_cells.keys():
		placement_system.add_invalid_cell(cell)


func _initialize_active_paths() -> void:
	_active_paths_lookup.clear()

	for index in range(paths.size()):
		_active_paths_lookup[index] = true

	if paths.is_empty():
		return

	if initial_path_index < 0 or initial_path_index >= paths.size():
		Log.trace(Log.Level.WARN, "Invalid initial_path_index %d for map with %d paths. Falling back to 0." % [initial_path_index, paths.size()])
		initial_path_index = 0


func _is_valid_path_index(path_index: int) -> bool:
	if path_index < 0 or path_index >= paths.size():
		Log.trace(Log.Level.WARN, "Invalid path index %d for map with %d paths." % [path_index, paths.size()])
		return false

	return true
