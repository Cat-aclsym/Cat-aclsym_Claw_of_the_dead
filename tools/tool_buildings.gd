## © [2026] A7 Studio. All rights reserved. Trademark.
##
## Places towers and traps on a map without the build cursor, for [code]golden_run[/code] and [code]bench_combat[/code].
## [br]Same steps as [method BuildPlacement._build], minus the coin cost.
## [br]Maps without painted placement cells (levels 3 to 8) have no buildable cell, the towers then stand on the cells next to the paths.
class_name ToolBuildings
extends RefCounted


## Distance in cells around each sampled path point where the fallback looks for cells.
const FALLBACK_RADIUS_CELLS: int = 3
## Distance in pixels between two sampled path points.
const FALLBACK_SAMPLE_STEP: float = 16.0


## Cells where a tower can be placed, nearest to an enemy path first, then by coordinates.
## [br]Without any placement cell on the map, the cells next to a path (outside of the placement box of the path) are used.
static func get_buildable_cells(map: IMap) -> Array[Vector2i]:
	var cells: Array[Vector2i] = _scan(map, func(cell: Vector2i) -> bool: return map.is_tile_buildable(cell))
	if cells.is_empty():
		cells = _near_paths(map, func(cell: Vector2i) -> bool: return not map.is_cell_on_path(cell))
	cells.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		var distance_a: float = map.get_path_distance(a)
		var distance_b: float = map.get_path_distance(b)
		if distance_a != distance_b:
			return distance_a < distance_b
		return a.x < b.x or (a.x == b.x and a.y < b.y)
	)
	return cells


## Cells covered by an enemy path (where traps go), sorted by coordinates.
static func get_path_cells(map: IMap) -> Array[Vector2i]:
	var cells: Array[Vector2i] = _scan(map, func(cell: Vector2i) -> bool: return map.is_cell_on_path(cell))
	if cells.is_empty():
		cells = _near_paths(map, func(cell: Vector2i) -> bool: return map.is_cell_on_path(cell))
	cells.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.x < b.x or (a.x == b.x and a.y < b.y))
	return cells


## Reads the [code]--key=value[/code] arguments given after [code]--[/code] on the command line.
static func parse_user_args() -> Dictionary[String, String]:
	var args: Dictionary[String, String] = {}
	for argument: String in OS.get_cmdline_user_args():
		var parts: PackedStringArray = argument.trim_prefix("--").split("=", true, 1)
		if parts.size() == 2:
			args[parts[0]] = parts[1]
	return args


## Instantiates the tower [param tower_id] on [param cell], active, with the [param upgrade_ids] applied in order.
static func place_tower(map: IMap, tower_id: String, cell: Vector2i, upgrade_ids: PackedStringArray = []) -> ITower:
	var tower: ITower = _instantiate(StatsDB.get_tower(tower_id)) as ITower
	tower.state = ITower.TowerState.ACTIVE
	_add(map, tower, cell)
	if map.special_tiles.has(cell):
		tower.apply_special_modifier(map.special_tiles[cell])
	for upgrade_id: String in upgrade_ids:
		tower.pending_upgrade_id = upgrade_id
		tower.apply_upgrade()
	ChallengeManager.notify_building_placed(tower)
	return tower


## Instantiates the trap [param trap_id] on [param cell], active, and notifies the challenges like a regular placement.
static func place_trap(map: IMap, trap_id: String, cell: Vector2i) -> ITrap:
	var trap: ITrap = _instantiate(StatsDB.get_trap(trap_id)) as ITrap
	trap.state = ITrap.TrapState.ACTIVE
	_add(map, trap, cell)
	ChallengeManager.notify_building_placed(trap)
	return trap


static func _add(map: IMap, building: IBuilding, cell: Vector2i) -> void:
	building.tile_pos = cell
	var cell_position: Vector2 = map.to_local(map.tilemap.to_global(map.tilemap.map_to_local(cell)))
	building.position = cell_position - Vector2(0.0, building.get_placement_vertical_offset())
	map.add_child(building)
	if is_instance_valid(Global.cursor):
		Global.cursor.add_invalid_cell(cell)


static func _instantiate(stats: Dictionary) -> Node:
	var scene: PackedScene = StatsDB.load_packed_scene(str(stats.get("scene", "")))
	assert(scene != null, "No scene in the stats entry %s" % [stats])
	return scene.instantiate()


## Cells within [constant FALLBACK_RADIUS_CELLS] of points sampled along every path, accepted by [param filter].
static func _near_paths(map: IMap, filter: Callable) -> Array[Vector2i]:
	var seen: Dictionary[Vector2i, bool] = {}
	for path: Path2D in map.paths:
		var curve: Curve2D = path.curve
		for step: int in int(curve.get_baked_length() / FALLBACK_SAMPLE_STEP):
			var point: Vector2 = path.to_global(curve.sample_baked(step * FALLBACK_SAMPLE_STEP))
			var center: Vector2i = map.tilemap.local_to_map(map.tilemap.to_local(point))
			for dx: int in range(-FALLBACK_RADIUS_CELLS, FALLBACK_RADIUS_CELLS + 1):
				for dy: int in range(-FALLBACK_RADIUS_CELLS, FALLBACK_RADIUS_CELLS + 1):
					seen[center + Vector2i(dx, dy)] = true
	var cells: Array[Vector2i] = []
	for cell: Vector2i in seen:
		if filter.call(cell):
			cells.append(cell)
	return cells


## Cells of the map used rect, in x then y order, accepted by [param filter].
static func _scan(map: IMap, filter: Callable) -> Array[Vector2i]:
	var rect: Rect2i = IMap.get_combined_used_rect(map.tilemap)
	var cells: Array[Vector2i] = []
	for x: int in range(rect.position.x, rect.end.x):
		for y: int in range(rect.position.y, rect.end.y):
			var cell: Vector2i = Vector2i(x, y)
			if filter.call(cell):
				cells.append(cell)
	return cells
