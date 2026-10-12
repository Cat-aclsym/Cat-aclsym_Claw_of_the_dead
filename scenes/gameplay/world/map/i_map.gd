## © [2026] A7 Studio. All rights reserved. Trademark.
##
## Base class for game maps. Manages tile-based map layout.
## @tutorial: See map_1.tscn for implementation example
class_name IMap
extends Node2D

const BONUS_KIND: String = "bonus"
const MALUS_KIND: String = "malus"
const BONUS_SPAWN_SCENE: PackedScene = preload("res://scenes/gameplay/world/map/bonus_spawn.tscn")
const SPECIAL_TILE_SCENES: Dictionary[String, PackedScene] = {
	BONUS_KIND: preload("res://scenes/gameplay/world/map/bonus_tile.tscn"),
	MALUS_KIND: preload("res://scenes/gameplay/world/map/malus_tile.tscn"),
}
## Tint of each special tile modifier, by kind then by modified stat.
const SPECIAL_TILE_MODIFIER_COLORS: Dictionary[String, Dictionary] = {
	BONUS_KIND: {
		"fire_rate": Color(0.2, 1.0, 0.2, 0.5),
		"damage": Color(0.2, 0.2, 1.0, 0.5),
		"reward_multiplier": Color(1.0, 0.8, 0.2, 0.5),
	},
	MALUS_KIND: {
		"fire_rate": Color(0.62, 0.18, 0.22, 0.5),
		"damage": Color(0.58, 0.30, 0.16, 0.5),
		"shoot_range": Color(0.42, 0.20, 0.48, 0.5),
	},
}
const BONUS_TILE_LAYER_NAME: String = "Special Bonus"
const BONUS_TILE_LAYER_Z_INDEX: int = -16
## Tile step used when the tilemap cannot provide one.
const DEFAULT_TILE_STEP_DISTANCE: float = 32.0
## Half of the 25x25 px placement box, towers cannot be placed closer than this to an enemy path.
const PLACEMENT_HALF_SIZE: float = 12.5
const SPECIAL_TILE_DEBUG_COLOR: Color = Color(0.2, 0.4, 1.0, 0.55)
const SPECIAL_TILE_DEBUG_EXCLUSION_COLOR: Color = Color(1.0, 0.2, 0.2, 0.35)
const SPECIAL_TILE_MAX_DISTANCE_TILES: float = 2.0
const SPECIAL_TILE_MIN_DISTANCE_BETWEEN_TILES: float = 2.0
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

@export var debug_show_spawnable_special_tiles: bool = false
@export var initial_camera_position: Vector2 = Vector2.ZERO
@export var initial_path_index: int = 0
@export var show_end_indicators: bool = true
@export var show_start_indicators: bool = true
@export_range(0.0, 100.0, 0.1) var special_tile_percentage: float = 2.0

## Invisible [TileMapLayer] that marks every tile where towers can be placed.
@export var placement_tilemap: TileMapLayer
## Optional square-grid props overlay (for example [TileMapProps]).
@export var props_tilemap: TileMapLayer
## Root [TileMapLayer] of the map layout, its child [TileMapLayer] nodes are the extra layers.
@export var tilemap: TileMapLayer

## Array of paths that enemies can follow
var paths: Array[Path2D] = []
var _active_paths_lookup: Dictionary[int, bool] = {}

var _debug_exclusion_overlays: Array[Node2D] = []
var _debug_spawnable_overlays: Array[Node2D] = []

## Cells covered by a [MapPlacementBlocker], computed on first use (the decorations never move).
var _blocked_cells: Dictionary[Vector2i, bool] = {}
var _blocked_cells_ready: bool = false
## Distance in pixels from a cell center to the nearest path, by cell. Covers every path, active or not.
var _path_distance_cache: Dictionary[Vector2i, float] = {}
var _special_tile_scene_source_ids: Dictionary[String, int] = {}
var _special_tile_scene_tile_ids: Dictionary[String, int] = {}
## Layer created at runtime on top of [member tilemap]'s tile set that hosts the bonus and malus scene tiles.
var _special_tile_layer: TileMapLayer = null

## Dictionary of special tiles (position -> modifier data)
var special_tiles: Dictionary[Vector2i, Dictionary] = {}
var _pending_special_tile_spawns: Array[Dictionary] = []

@onready var camera: Camera2D = $Camera2D

# core
func _ready() -> void:
	_load_paths()
	_create_path_indicators()
	_ensure_special_tile_layer()
	_ensure_special_tile_scene_source(BONUS_KIND)
	_ensure_special_tile_scene_source(MALUS_KIND)

	# If the cursor is not yet initialized, wait a frame
	if not _try_assign_tilemap_to_cursor():
		_try_assign_tilemap_to_cursor.call_deferred()

	_setup_camera_limits()

	if is_instance_valid(placement_tilemap):
		placement_tilemap.visible = false

	# Generate special tiles immediately
	_generate_special_tiles()

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

## Used rect of [param root] merged with its child [TileMapLayer] nodes (the extent of the former multi-layer TileMap).
static func get_combined_used_rect(root: TileMapLayer) -> Rect2i:
	var rect: Rect2i = Rect2i()
	var layers: Array[Node] = root.get_children()
	layers.push_front(root)
	for node: Node in layers:
		var layer: TileMapLayer = node as TileMapLayer
		if layer == null:
			continue
		var layer_rect: Rect2i = layer.get_used_rect()
		if not layer_rect.has_area():
			continue
		rect = layer_rect if not rect.has_area() else rect.merge(layer_rect)
	return rect

func get_tower_by_name(tower_name: String) -> ITower:
	for child in get_children():
		if child is ITower:
			var tower: ITower = child as ITower
			if tower.name == tower_name:
				return tower
	return null


## Toggles visibility of the placement [TileMapLayer] for debugging.
## Returns true when now visible, false when hidden.
func toggle_placement_debug_overlay() -> bool:
	if not is_instance_valid(placement_tilemap):
		return false
	placement_tilemap.visible = not placement_tilemap.visible
	return placement_tilemap.visible


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


## Returns the cells where no tower can be placed because a [MapPlacementBlocker] decoration covers them, as a set.
func get_blocked_cells() -> Dictionary[Vector2i, bool]:
	if not _blocked_cells_ready and tilemap:
		_blocked_cells_ready = true
		for blocker: Node in find_children("*", "MapPlacementBlocker", true, false):
			_blocked_cells.merge((blocker as MapPlacementBlocker).get_blocked_cells(tilemap))

	return _blocked_cells


## Distance in pixels from the center of [param cell] to the nearest path (every path counts, active or not).
## Cached per cell, [constant INF] when the map has no path.
func get_path_distance(cell: Vector2i) -> float:
	if _path_distance_cache.has(cell):
		return _path_distance_cache[cell]

	var world_pos: Vector2 = tilemap.to_global(tilemap.map_to_local(cell))
	var min_distance: float = INF
	for path: Path2D in paths:
		if not path.curve:
			continue

		var closest_point: Vector2 = path.curve.get_closest_point(path.to_local(world_pos))
		min_distance = minf(min_distance, world_pos.distance_to(path.to_global(closest_point)))

	_path_distance_cache[cell] = min_distance
	return min_distance


## Returns a random active path, or null if none are active.
func get_random_active_path() -> Path2D:
	var active_paths: Array[Path2D] = get_active_paths()
	if active_paths.is_empty():
		return null

	return active_paths[randi() % active_paths.size()]


## Distance in pixels between two horizontally adjacent tile centers.
func get_tile_step_distance() -> float:
	if not tilemap:
		return DEFAULT_TILE_STEP_DISTANCE

	var step_distance: float = tilemap.map_to_local(Vector2i.ZERO).distance_to(tilemap.map_to_local(Vector2i(1, 0)))
	return step_distance if step_distance > 0.0 else DEFAULT_TILE_STEP_DISTANCE


## Returns true when the path index is currently active.
func is_path_active(path_index: int) -> bool:
	return _active_paths_lookup.has(path_index)


## Whether the placement box centered on [param cell] overlaps an enemy path.
func is_cell_on_path(cell: Vector2i) -> bool:
	return get_path_distance(cell) < PLACEMENT_HALF_SIZE


## Replaces current active paths with the provided indices.
func set_active_paths_only(path_indices: Array[int]) -> void:
	_active_paths_lookup.clear()

	for path_index in path_indices:
		if _is_valid_path_index(path_index):
			_active_paths_lookup[path_index] = true

	if _active_paths_lookup.is_empty():
		Log.trace(Log.Level.WARN, "Map has no active paths after set_active_paths_only().")

## Returns true if a tower can be placed on [param coords].
## Authoritative source is the invisible placement [TileMapLayer] painted by the level designer,
## minus the cells covered by a [MapPlacementBlocker] and the cells too close to an enemy path.
func is_tile_buildable(coords: Vector2i) -> bool:
	if placement_tilemap == null:
		return false
	if placement_tilemap.get_cell_source_id(coords) == -1:
		return false
	if get_blocked_cells().has(coords):
		return false

	return not is_cell_on_path(coords)

# private

## Loads path nodes from the Paths node
func _load_paths() -> void:
	if not has_node("Paths"):
		Log.trace(Log.Level.WARN, "No Paths node found in map")
		return

	paths.clear()
	_path_distance_cache.clear()
	var children: Array[Node] = $Paths.get_children()

	for child in children:
		if (child is Path2D):
			paths.append(child as Path2D)

	_initialize_active_paths()

func _create_path_indicators() -> void:
	for path in paths:
		var curve: Curve2D = path.curve
		if curve.get_point_count() < 2:
			continue

		if show_start_indicators:
			var start_pos: Vector2 = path.to_global(curve.get_point_position(0))
			_instantiate_indicator(start_pos, Color(0.1, 0.9, 0.1), PathIndicator.PointType.START)

		if show_end_indicators:
			var end_pos: Vector2 = path.to_global(curve.get_point_position(curve.get_point_count() - 1))
			_instantiate_indicator(end_pos, Color(0.9, 0.1, 0.1), PathIndicator.PointType.END)

func _instantiate_indicator(global_pos: Vector2, color: Color, point_type: PathIndicator.PointType) -> void:
	var indicator: PathIndicator = PathIndicator.new()
	indicator.position = to_local(global_pos)
	indicator.base_color = color
	indicator.type = point_type
	indicator.z_index = 1 # Above the ground tiles
	add_child(indicator)

func _generate_special_tiles() -> void:
	if not tilemap:
		return

	var buildable_tiles: Array[Vector2i] = []
	var used_rect: Rect2i = get_combined_used_rect(tilemap)

	for x in range(used_rect.position.x, used_rect.end.x):
		for y in range(used_rect.position.y, used_rect.end.y):
			var coords := Vector2i(x, y)
			if is_tile_buildable(coords):
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
		_clear_debug_overlays(_debug_exclusion_overlays)
		_clear_debug_overlays(_debug_spawnable_overlays)

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

	_clear_debug_overlays(_debug_exclusion_overlays)

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

	var bonus_types: Array[Dictionary] = _build_special_tile_modifiers(BONUS_KIND)
	var malus_types: Array[Dictionary] = _build_special_tile_modifiers(MALUS_KIND)

	var selected_bonus_tiles: Array[Vector2i] = []
	for i in range(bonus_tile_count):
		var tile_pos: Vector2i = selected_special_tiles.pop_back()
		selected_bonus_tiles.append(tile_pos)
		var modifier: Dictionary = bonus_types[i % bonus_types.size()]
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
		var tile_pos: Vector2i = malus_tiles[i]
		var modifier: Dictionary = malus_types[i % malus_types.size()]
		_pending_special_tile_spawns.append({
			"tile_pos": tile_pos,
			"modifier": modifier,
			"is_bonus": false
		})
		if debug_show_spawnable_special_tiles:
			_show_debug_exclusion_tiles_around(tile_pos)
		Log.trace(Log.Level.INFO, "Queued malus tile at {0}: {1}".format([tile_pos, modifier["label"]]))

## Builds the tile modifiers of [param kind] from [StatsDB] in their declared order. Each modifier maps its stat to
## a multiplier and carries its tint, its (translated) label and whether it is a malus.
func _build_special_tile_modifiers(kind: String) -> Array[Dictionary]:
	var colors: Dictionary = SPECIAL_TILE_MODIFIER_COLORS[kind]
	var modifiers: Array[Dictionary] = []
	for entry: Dictionary in StatsDB.get_tile_modifiers(kind):
		var stat: String = entry["stat"]
		modifiers.append({
			stat: float(entry["multiplier"]),
			"color": colors.get(stat, Color.WHITE),
			"label": tr("TILE.%s.%s" % [kind.to_upper(), stat.to_upper()]),
			"is_malus": kind == MALUS_KIND,
		})
	return modifiers

func _get_malus_tiles_around_bonus(bonus_tiles: Array[Vector2i], spawnable_tiles: Array[Vector2i]) -> Array[Vector2i]:
	var spawnable_lookup: Dictionary[Vector2i, bool] = {}
	for tile_pos in spawnable_tiles:
		spawnable_lookup[tile_pos] = true

	var bonus_lookup: Dictionary[Vector2i, bool] = {}
	for tile_pos in bonus_tiles:
		bonus_lookup[tile_pos] = true

	var malus_lookup: Dictionary[Vector2i, bool] = {}
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
	for tile_pos: Vector2i in malus_lookup.keys():
		malus_tiles.append(tile_pos)

	return malus_tiles

func _is_special_tile_spawnable(candidate: Vector2i, already_selected: Array[Vector2i]) -> bool:
	for other in already_selected:
		if candidate.distance_to(other) < SPECIAL_TILE_MIN_DISTANCE_BETWEEN_TILES:
			return false
	return true

func _clear_debug_overlays(overlays: Array[Node2D]) -> void:
	for node in overlays:
		if is_instance_valid(node):
			node.queue_free()
	overlays.clear()

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

func _get_tutorial_hint_tile() -> Vector2i:
	var hint: TutorialPlacementHint = find_child("TutorialPlacementHint", true, false) as TutorialPlacementHint
	if not is_instance_valid(hint) or not is_instance_valid(tilemap):
		return Vector2i(-99999, -99999)
	var local_pos: Vector2 = tilemap.to_local(hint.global_position)
	return tilemap.local_to_map(local_pos)

func _get_spawnable_special_tiles(buildable_tiles: Array[Vector2i]) -> Array[Vector2i]:
	var max_distance_to_path: float = get_tile_step_distance() * SPECIAL_TILE_MAX_DISTANCE_TILES
	var tutorial_tile: Vector2i = _get_tutorial_hint_tile()

	var spawnable_tiles: Array[Vector2i] = []
	for coords in buildable_tiles:
		if coords.distance_to(tutorial_tile) < 2.0:
			continue

		if get_path_distance(coords) <= max_distance_to_path:
			spawnable_tiles.append(coords)

	return spawnable_tiles

func _clear_special_tile_layer() -> void:
	if is_instance_valid(_special_tile_layer):
		_special_tile_layer.clear()

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
	_clear_debug_overlays(_debug_spawnable_overlays)
	for tile_pos in spawnable_tiles:
		_create_debug_tile_overlay(tile_pos, SPECIAL_TILE_DEBUG_COLOR, _debug_spawnable_overlays)

func _place_special_tile_cell(kind: String, tile_pos: Vector2i) -> void:
	if not tilemap:
		return

	var source_id: int = _special_tile_scene_source_ids.get(kind, -1)
	if source_id < 0:
		Log.trace(Log.Level.ERROR, "%s tile scene source is not ready" % kind.capitalize())
		return

	_special_tile_layer.set_cell(tile_pos, source_id, Vector2i.ZERO, _special_tile_scene_tile_ids[kind])

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
	_place_special_tile_cell(BONUS_KIND if is_bonus else MALUS_KIND, tile_pos)

	_special_tile_layer.update_internals()
	if is_bonus:
		_trigger_special_tile_spawn_shake()

	var remaining_duration := SPECIAL_TILE_SPAWN_ANIMATION_DURATION_SECONDS * (1.0 - SPECIAL_TILE_SPAWN_APPLY_RATIO)
	if remaining_duration > 0.0:
		await get_tree().create_timer(remaining_duration).timeout

	if is_instance_valid(spawn_fx):
		spawn_fx.queue_free()


func _create_bonus_spawn_animation(world_pos: Vector2, modifier: Dictionary) -> Node2D:
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

	if is_instance_valid(_special_tile_layer):
		return

	# Sibling of the map layers, so special tiles find their IMap through get_parent().
	_special_tile_layer = TileMapLayer.new()
	_special_tile_layer.name = BONUS_TILE_LAYER_NAME
	_special_tile_layer.tile_set = tilemap.tile_set
	_special_tile_layer.transform = tilemap.transform
	_special_tile_layer.y_sort_enabled = false
	_special_tile_layer.z_index = BONUS_TILE_LAYER_Z_INDEX
	add_child(_special_tile_layer)

func _ensure_special_tile_scene_source(kind: String) -> void:
	if not tilemap or not tilemap.tile_set:
		return
	if _special_tile_scene_source_ids.get(kind, -1) >= 0:
		return

	# The tile set is a resource shared by every instance of the map, reuse the source of a previous load.
	for index: int in tilemap.tile_set.get_source_count():
		var existing_id: int = tilemap.tile_set.get_source_id(index)
		var existing: TileSetScenesCollectionSource = tilemap.tile_set.get_source(existing_id) as TileSetScenesCollectionSource
		if existing != null and existing.get_scene_tiles_count() == 1 and existing.get_scene_tile_scene(existing.get_scene_tile_id(0)) == SPECIAL_TILE_SCENES[kind]:
			_special_tile_scene_source_ids[kind] = existing_id
			_special_tile_scene_tile_ids[kind] = existing.get_scene_tile_id(0)
			return

	var scene_source := TileSetScenesCollectionSource.new()
	var tile_id: int = scene_source.create_scene_tile(SPECIAL_TILE_SCENES[kind])
	var source_id: int = tilemap.tile_set.add_source(scene_source, tilemap.tile_set.get_next_source_id())

	if source_id < 0 or not (tilemap.tile_set.get_source(source_id) is TileSetScenesCollectionSource):
		Log.trace(Log.Level.ERROR, "Failed to create %s tile scene source" % kind)
		return

	_special_tile_scene_source_ids[kind] = source_id
	_special_tile_scene_tile_ids[kind] = tile_id

func _try_assign_tilemap_to_cursor() -> bool:
	if not is_instance_valid(Global.cursor):
		return false

	Global.cursor.tm_ref = tilemap
	return true


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


func _setup_camera_limits() -> void:
	if camera == null or tilemap == null:
		return

	var used_rect: Rect2i = get_combined_used_rect(tilemap)
	var corners: Array[Vector2i] = [
		used_rect.position,
		used_rect.position + Vector2i(used_rect.size.x, 0),
		used_rect.position + Vector2i(0, used_rect.size.y),
		used_rect.position + used_rect.size,
	]

	var min_x: float = INF
	var min_y: float = INF
	var max_x: float = -INF
	var max_y: float = -INF

	for corner: Vector2i in corners:
		var world_pos: Vector2 = tilemap.to_global(tilemap.map_to_local(corner))
		min_x = min(min_x, world_pos.x)
		min_y = min(min_y, world_pos.y)
		max_x = max(max_x, world_pos.x)
		max_y = max(max_y, world_pos.y)

	var padding: int = 64
	camera.limit_left = int(min_x) - padding
	camera.limit_top = int(min_y) - padding
	camera.limit_right = int(max_x) + padding
	camera.limit_bottom = int(max_y)

	if initial_camera_position != Vector2.ZERO:
		camera.position = initial_camera_position
	else:
		camera.position = Vector2((min_x + max_x) / 2.0, min_y + (max_y - min_y) * 0.25)
