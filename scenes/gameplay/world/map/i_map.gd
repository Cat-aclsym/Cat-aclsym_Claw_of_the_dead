## © [2024] A7 Studio. All rights reserved. Trademark.
##
## Base class for game maps. Manages tile-based map layout.
## @tutorial: See map_1.tscn for implementation example
class_name IMap
extends Node2D

## Reference to the TileMap node for map layout
@export var tilemap: TileMap

## Array of paths that enemies can follow
var paths: Array[Path2D] = []

## Dictionary of special tiles (position -> modifier data)
var special_tiles: Dictionary = {}

@onready var camera: Camera2D = $Camera2D

# core
func _ready() -> void:
	_load_paths()
	_create_path_indicators()

	var placement_system = Global.get("cursor")
	if placement_system:
		placement_system.tm_ref = tilemap
	else:
		# If cursor is not yet initialized, wait a frame
		call_deferred("_assign_tilemap_to_cursor")
	
	# Generate special tiles immediately
	_generate_special_tiles()

func _assign_tilemap_to_cursor() -> void:
	var placement_system = Global.get("cursor")
	if placement_system:
		placement_system.tm_ref = tilemap

#public
func get_tower_by_name(tower_name: String) -> ITower:
	for child in get_children():
		if child is ITower:
			var tower: ITower = child as ITower
			if tower.name == tower_name:
				return tower
	return null

# private

## Loads path nodes from the Paths node
func _load_paths() -> void:
	if not has_node("Paths"):
		Log.trace(Log.Level.WARN, "No Paths node found in map")
		return
		
	var children: Array[Node] = $Paths.get_children()

	for child in children:
		if (child is Path2D):
			paths.append(child as Path2D)

func _create_path_indicators() -> void:
	for path in paths:
		var curve = path.curve
		if curve.get_point_count() < 2:
			continue
		
		# Start point
		var start_pos = path.to_global(curve.get_point_position(0))
		_instantiate_indicator(start_pos, Color(0.1, 0.9, 0.1), PathIndicator.PointType.START)
		
		# End point
		var end_pos = path.to_global(curve.get_point_position(curve.get_point_count() - 1))
		_instantiate_indicator(end_pos, Color(0.9, 0.1, 0.1), PathIndicator.PointType.END)

func _instantiate_indicator(global_pos: Vector2, color: Color, type: PathIndicator.PointType) -> void:
	var indicator = PathIndicator.new()
	indicator.position = to_local(global_pos)
	indicator.base_color = color
	indicator.type = type
	indicator.z_index = 1 # Above the ground tiles
	add_child(indicator)

func _generate_special_tiles() -> void:
	if not tilemap:
		return
	
	var buildable_tiles: Array[Vector2i] = []
	var used_rect := tilemap.get_used_rect()
	
	# Find all buildable tiles
	for x in range(used_rect.position.x, used_rect.end.x):
		for y in range(used_rect.position.y, used_rect.end.y):
			var coords := Vector2i(x, y)
			if _is_tile_buildable(coords):
				buildable_tiles.append(coords)
	
	Log.trace(Log.Level.INFO, "Found {0} buildable tiles for special tiles".format([buildable_tiles.size()]))
	
	if buildable_tiles.size() < 6:
		Log.trace(Log.Level.WARN, "Not enough buildable tiles for special tiles")
		return
	
	buildable_tiles.shuffle()
	
	var bonus_types = [
		{"fire_rate": 1.3, "color": Color(0.2, 1.0, 0.2, 0.5), "label": "SPEED+"},
		{"damage": 1.3, "color": Color(0.2, 0.2, 1.0, 0.5), "label": "DMG+"},
		{"reward_multiplier": 1.5, "color": Color(1.0, 0.8, 0.2, 0.5), "label": "GOLD+"}
	]
	
	var malus_types = [
		{"fire_rate": 0.7, "color": Color(1.0, 0.2, 0.2, 0.5), "label": "SPEED-"},
		{"damage": 0.7, "color": Color(1.0, 0.5, 0.2, 0.5), "label": "DMG-"},
		{"shoot_range": 0.7, "color": Color(0.8, 0.2, 0.8, 0.5), "label": "RANGE-"}
	]
	
	# Place 3 bonuses
	for i in range(3):
		var tile_pos = buildable_tiles.pop_back()
		var modifier = bonus_types[i % bonus_types.size()]
		special_tiles[tile_pos] = modifier
		_create_visual_indicator(tile_pos, modifier)
		Log.trace(Log.Level.INFO, "Generated bonus tile at {0}: {1}".format([tile_pos, modifier["label"]]))
		
	# Place 3 maluses
	for i in range(3):
		var tile_pos = buildable_tiles.pop_back()
		var modifier = malus_types[i % malus_types.size()]
		special_tiles[tile_pos] = modifier
		_create_visual_indicator(tile_pos, modifier)
		Log.trace(Log.Level.INFO, "Generated malus tile at {0}: {1}".format([tile_pos, modifier["label"]]))

func _create_visual_indicator(tile_pos: Vector2i, modifier: Dictionary) -> void:
	var world_pos = tilemap.map_to_local(tile_pos)
	
	# Create a diamond shape that matches the isometric tile (64x32)
	var poly = Polygon2D.new()
	var half_width = 32.0
	var half_height = 16.0
	
	# Points for the diamond shape
	var points = PackedVector2Array([
		Vector2(0, -half_height), # Top
		Vector2(half_width, 0),   # Right
		Vector2(0, half_height),  # Bottom
		Vector2(-half_width, 0)   # Left
	])
	
	poly.polygon = points
	poly.color = modifier["color"]
	poly.color.a = 0.4 # Slightly more opaque for the "filter" effect
	poly.position = world_pos
	poly.z_index = 0 # Just above the ground
	add_child(poly)
	
	# Add a pulse effect to the tile filter
	var tween = create_tween().set_loops()
	tween.tween_property(poly, "color:a", 0.7, 1.5).set_trans(Tween.TRANS_SINE)
	tween.tween_property(poly, "color:a", 0.4, 1.5).set_trans(Tween.TRANS_SINE)
	
	# Add a label with better styling, slightly above the tile
	var label = Label.new()
	label.text = modifier["label"]
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 4)
	label.position = world_pos - Vector2(20, 20) # Positioned slightly higher
	label.z_index = 1 # Above the filter
	add_child(label)

func _is_tile_buildable(coords: Vector2i) -> bool:
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
