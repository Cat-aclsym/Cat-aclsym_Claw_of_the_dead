## © [2026] A7 Studio. All rights reserved. Trademark.
##
## Placement cursor and validation for the build flow (towers, traps, upgrades).
## @tutorial: https://docs.godotengine.org/en/stable/tutorials/2d/2d_transforms.html
class_name BuildPlacement
extends Node2D

## Emitted when entering idle state
signal trigger_state_idle
## Emitted when entering build state
signal trigger_state_build
## Emitted when entering upgrade state
signal trigger_state_upgrade
## Emitted when a building has been successfully placed
signal building_placed(building: IBuilding)

const COLOR_OK := Color(1, 1, 1, 0.5)
const COLOR_KO := Color(1, 0.5, 0.5, 0.5)

const BUTTON_COLOR_ENABLED := Color(1, 1, 1, 1)
const BUTTON_COLOR_DISABLED := Color(0.5, 0.5, 0.5, 0.6)

const UP_OFFSET := Vector2i(-1, -1)
const RIGHT_OFFSET := Vector2i(0, -1)
const LEFT_OFFSET := Vector2i(-1, 0)
## Base TileMap constraints for ground-placed buildings (towers); traps use path rules instead.
const VALID_SOURCE_ID: int = 0 # Ground Grass
const VALID_TILES: Array[Vector2i] = [
	Vector2i(0, 0)
]

## States for the build / upgrade cursor.
enum CursorState {
	IDLE,  ## Default state
	BUILD,  ## Placing a new [IBuilding] preview
	UPGRADE  ## Tower upgrade mode
}

## Reference to the tilemap node
var tm_ref: TileMap = null

var _invalid_cells: Array[Vector2i] = []
var _is_dragging: bool = false
var _is_holding_click: bool = false
var _can_reposition_build_cursor: bool = true
var _last_tm_pos: Vector2i = Vector2i(-1, -1)
var _state: CursorState = CursorState.IDLE
var _preview_building: IBuilding = null

## The number of towers created
static var tower_count: int = 0

@onready var cancel_place_button: TextureButton = $PlaceHUD/HBoxContainer/CancelPlaceButton
@onready var cursor: AnimatedSprite2D = $cursor
@onready var place_button: TextureButton = $PlaceHUD/HBoxContainer/PlaceButton
@onready var place_hud: Control = $PlaceHUD
@onready var place_hud_content: BoxContainer = $PlaceHUD/HBoxContainer
@onready var placement_area: Area2D = $Area2D

@onready var signals: Array[Dictionary] = [
	{SignalUtil.WHO: place_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_place_button_pressed},
	{SignalUtil.WHO: place_button, SignalUtil.WHAT: "mouse_entered", SignalUtil.TO: _on_button_mouse_entered},
	{SignalUtil.WHO: place_button, SignalUtil.WHAT: "mouse_exited", SignalUtil.TO: _on_button_mouse_exited},
	{SignalUtil.WHO: cancel_place_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_cancel_place_button_pressed},
	{SignalUtil.WHO: cancel_place_button, SignalUtil.WHAT: "mouse_entered", SignalUtil.TO: _on_button_mouse_entered},
	{SignalUtil.WHO: cancel_place_button, SignalUtil.WHAT: "mouse_exited", SignalUtil.TO: _on_button_mouse_exited},
]

func _ready() -> void:
	assert(cancel_place_button != null, "cancel_place_button node not found")
	assert(cursor != null, "cursor node not found")
	assert(place_button != null, "place_button node not found")
	assert(place_hud != null, "place_hud node not found")
	assert(place_hud_content != null, "place_hud_content node not found")
	assert(placement_area != null, "placement_area node not found")
	Log.trace(Log.Level.DEBUG, "BuildPlacement ready: visible=%s state=%s level=%s" % [visible, _state, ILevel.current_level])

	Global.cursor = self
	visible = false
	place_hud.visible = false
	SignalUtil.connects(signals)

	ButtonEffects.apply(place_button)
	ButtonEffects.apply(cancel_place_button)

	if ILevel.current_level:
		var level_signals: Array[Dictionary] = [
			{SignalUtil.WHO: ILevel.current_level, SignalUtil.WHAT: "stats_updated", SignalUtil.TO: _on_level_stats_updated}
		]
		SignalUtil.connects(level_signals)

func _unhandled_input(event: InputEvent) -> void:
	if Global.paused:
		return

	if _state == CursorState.BUILD:
		_state_build_input(event)

## Adds a cell to the invalid cells list
func add_invalid_cell(tm_pos: Vector2i) -> void:
	if not tm_pos in _invalid_cells:
		_invalid_cells.append(tm_pos)
		Log.trace(Log.Level.INFO, "Cell {0} is now occupied".format([tm_pos]))

## Change the current state of the build placement cursor.
## [br]
## [param new_state] The state to change to
## [param args] Additional arguments for the state change
func change_state(new_state: CursorState, args: Array = []) -> void:
	Log.trace(Log.Level.DEBUG, "BuildPlacement change_state requested: %s -> %s args=%s" % [_state, new_state, args])
	match new_state:
		CursorState.IDLE:
			trigger_state_idle.emit()
			_state = new_state
			visible = false

			# Re-enable on-map tower UI (buttons / hover)
			_set_placed_tower_ui_enabled(true)
		CursorState.BUILD:
			assert(args.size() == 1)
			assert(args[0] is IBuilding)
			if _state == CursorState.BUILD:
				_state_build(args[0], true)
				_update()
				return
			if _state != CursorState.IDLE:
				Log.trace(Log.Level.WARN, "Cannot enter BUILD state: current state is not IDLE")
				return

			trigger_state_build.emit()
			Log.trace(Log.Level.DEBUG, "BuildPlacement trigger_state_build emitted")
			_state = new_state
			visible = true

			if ILevel.current_level and not ILevel.current_level.stats_updated.is_connected(_on_level_stats_updated):
				ILevel.current_level.stats_updated.connect(_on_level_stats_updated)

			_set_placed_tower_ui_enabled(false)

			_state_build(args[0])

		CursorState.UPGRADE:
			if _state != CursorState.IDLE:
				Log.trace(Log.Level.WARN, "Cannot enter UPGRADE state: current state is not IDLE")
				return
			trigger_state_upgrade.emit()
			Log.trace(Log.Level.DEBUG, "BuildPlacement trigger_state_upgrade emitted")
			_state = new_state
			visible = true

	_update()

## Removes a cell from the invalid cells list so a building can be placed there again.
func remove_invalid_cell(tm_pos: Vector2i) -> void:
	var removed_any: bool = false
	while tm_pos in _invalid_cells:
		_invalid_cells.erase(tm_pos)
		removed_any = true
	if removed_any:
		Log.trace(Log.Level.INFO, "Cell {0} is now free for building".format([tm_pos]))

func _build() -> void:
	Log.trace(Log.Level.DEBUG, "BuildPlacement _build start: preview=%s state=%s level=%s" % [_preview_building, _state, ILevel.current_level])
	if not _is_buildable(cursor.position):
		Log.trace(Log.Level.DEBUG, "BuildPlacement _build aborted: not buildable at position=%s" % cursor.position)
		return

	_can_reposition_build_cursor = false

	var new_entity: Node2D = _preview_building.duplicate()
	new_entity.modulate = Color(1, 1, 1, 1)

	var current_level: ILevel = ILevel.current_level
	var tm_pos: Vector2i = tm_ref.local_to_map(tm_ref.to_local(cursor.global_position))

	if new_entity is ITower:
		var new_tower := new_entity as ITower
		new_tower.state = ITower.TowerState.ACTIVE
		new_tower.show_range(false, false) # Hide range instantly on the placed tower
		tower_count += 1
		new_tower.name = "t%d" % tower_count
		if "tile_pos" in new_tower:
			new_tower.tile_pos = tm_pos

		if current_level and current_level.map:
			var map: IMap = current_level.map
			map.add_child(new_tower)
			if map.special_tiles.has(tm_pos):
				var modifier: Dictionary = map.special_tiles[tm_pos]
				new_tower.apply_special_modifier(modifier)
		else:
			get_parent().add_child(new_tower)

	elif new_entity is ITrap:
		var new_trap := new_entity as ITrap
		new_trap.state = ITrap.TrapState.ACTIVE
		if current_level and current_level.map:
			current_level.map.add_child(new_trap)
		else:
			get_parent().add_child(new_trap)

	if new_entity is IBuilding:
		var placed_building: IBuilding = new_entity as IBuilding
		Log.trace(Log.Level.INFO, "BuildPlacement building placed: %s kind=%s" % [placed_building, placed_building.get_building_kind()])
		ChallengeManager.notify_building_placed(placed_building)
		building_placed.emit(placed_building)
		Log.trace(Log.Level.DEBUG, "BuildPlacement building_placed emitted")

	add_invalid_cell(tm_pos)
	ILevel.current_level.coins -= _preview_building.cost

	_cancel_build()
	_can_reposition_build_cursor = true

func _cancel_build() -> void:
	Log.trace(Log.Level.DEBUG, "BuildPlacement cancel build: preview=%s" % _preview_building)
	cursor.visible = false
	place_hud.visible = false
	if _preview_building:
		var t: IBuilding = _preview_building
		_preview_building = null # Clear reference immediately
		t.cancel_build_preview()

		var tween: Tween = create_tween()
		tween.tween_property(t, "modulate:a", 0.0, 0.2)
		tween.tween_callback(t.queue_free)

	_last_tm_pos = Vector2i(-1, -1)
	change_state(CursorState.IDLE)

## Nearest map cell to [param origin_cell] where [param template] can be placed (4-neighbour BFS within padded used rect).
func _find_nearest_valid_build_cell(origin_cell: Vector2i, template: IBuilding) -> Vector2i:
	if not tm_ref:
		return origin_cell
	var bounds: Rect2i = Rect2i(tm_ref.get_used_rect()).grow(8)
	var visited: Dictionary = {}
	var queue: Array[Vector2i] = [origin_cell]
	visited[origin_cell] = true
	var head: int = 0
	const NEIGHBOURS: Array[Vector2i] = [
		Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)
	]
	while head < queue.size():
		var c: Vector2i = queue[head]
		head += 1
		if _is_template_buildable_at_map_cell(c, template):
			return c
		for d: Vector2i in NEIGHBOURS:
			var n: Vector2i = c + d
			if not bounds.has_point(n):
				continue
			if visited.has(n):
				continue
			visited[n] = true
			queue.append(n)
	return origin_cell

## World position to start the build preview (camera center or map center).
func _get_initial_build_position() -> Vector2:
	var camera: Camera2D = get_viewport().get_camera_2d()
	if camera:
		var world_position: Vector2 = camera.get_screen_center_position()
		return world_position

	if tm_ref:
		var map_rect: Rect2i = tm_ref.get_used_rect()
		var map_center: Vector2i = map_rect.position + (map_rect.size / 2)
		return tm_ref.map_to_local(map_center)

	return Vector2.ZERO

func _handle_state() -> void:
	match _state:
		CursorState.IDLE:
			_state_idle()
		CursorState.BUILD:
			_state_build()
		CursorState.UPGRADE:
			_state_upgrade()

func _is_buildable(pos: Vector2) -> bool:
	if _preview_building.get_building_kind() == IBuilding.BuildingKind.TRAP:
		return _is_trap_buildable(pos)
	return _is_ground_building_placeable(pos)

func _is_ground_building_placeable(pos: Vector2, building: IBuilding = null) -> bool:
	var b: IBuilding = building if building != null else _preview_building
	if b == null:
		return false
	if ILevel.current_level.coins < b.cost:
		return false

	var tm_pos: Vector2i = tm_ref.local_to_map(pos)

	if tm_pos in _invalid_cells:
		return false

	var source_id: int = tm_ref.get_cell_source_id(0, tm_pos)
	if source_id != VALID_SOURCE_ID:
		return false

	var atlas_coords: Vector2i = tm_ref.get_cell_atlas_coords(0, tm_pos)
	if not atlas_coords in VALID_TILES:
		return false

	if tm_ref.get_cell_atlas_coords(1, tm_pos) != Vector2i(-1, -1):
		return false

	if _is_position_on_path(pos):
		return false

	return true

## Whether the placement area at [param pos] overlaps an enemy path.
## [br]Uses half-size 12.5 px (25×25 placement box) versus distance to each [Path2D].
func _is_position_on_path(pos: Vector2) -> bool:
	if not ILevel.current_level:
		return false

	var level: ILevel = ILevel.current_level
	if not "map" in level or not level.map:
		return false

	var paths: Array[Path2D] = level.map.paths
	var placement_half_size: float = 12.5

	for path: Path2D in paths:
		var closest_point: Vector2 = path.curve.get_closest_point(path.to_local(pos))
		var distance: float = pos.distance_to(path.to_global(closest_point))

		if distance < placement_half_size:
			return true

	return false

## Whether [param template] can be built at tile [param cell] (tilemap-local center).
func _is_template_buildable_at_map_cell(cell: Vector2i, template: IBuilding) -> bool:
	var pos: Vector2 = tm_ref.map_to_local(cell)
	if template.get_building_kind() == IBuilding.BuildingKind.TRAP:
		return _is_trap_buildable(pos, template)
	return _is_ground_building_placeable(pos, template)

func _is_trap_buildable(pos: Vector2, building: IBuilding = null) -> bool:
	var b: IBuilding = building if building != null else _preview_building
	if b == null:
		return false
	if ILevel.current_level.coins < b.cost:
		return false

	var tm_pos: Vector2i = tm_ref.local_to_map(pos)

	if not _is_position_on_path(pos):
		return false

	if tm_pos in _invalid_cells:
		return false

	return true

func _on_button_mouse_entered() -> void:
	_can_reposition_build_cursor = false

func _on_button_mouse_exited() -> void:
	_can_reposition_build_cursor = true

func _on_cancel_place_button_pressed() -> void:
	_cancel_build()

func _on_level_stats_updated() -> void:
	if _state == CursorState.BUILD and _preview_building:
		var is_buildable := _is_buildable(cursor.position)
		_preview_building.modulate = COLOR_OK if is_buildable else COLOR_KO
		_update_place_button_state(is_buildable)

func _on_place_button_pressed() -> void:
	_build()

func _set_cursor_position(pos: Vector2 = get_global_mouse_position()) -> void:
	var map_pos: Vector2i = tm_ref.local_to_map(pos)
	var local_pos: Vector2 = tm_ref.map_to_local(map_pos)

	cursor.position = local_pos
	cursor.visible = true
	place_hud.visible = true
	place_hud.position = local_pos

	placement_area.position = local_pos

func _set_placed_tower_ui_enabled(enabled: bool) -> void:
	if not ILevel.current_level:
		return

	var level: ILevel = ILevel.current_level
	if not "map" in level or not level.map:
		return

	var towers: Array[Node] = get_tree().get_nodes_in_group("towers")
	for tower_body: Node in towers:
		if tower_body.get_parent() is ITower:
			var tower: ITower = tower_body.get_parent()
			if tower.button:
				tower.button.disabled = not enabled
			if tower.hover_box and tower.hover_box.get_parent():
				var hover_area: Area2D = tower.hover_box.get_parent()
				hover_area.monitoring = enabled
				hover_area.monitorable = enabled
				hover_area.input_pickable = enabled

## Build-mode frame: follow cursor, tint preview, validate tile.
## [param template] New building template to preview.
## [param keep_current_cursor_position] Keep current selected tile when replacing preview.
func _state_build(template: Node2D = null, keep_current_cursor_position: bool = false) -> void:
	if template:
		var tpl: IBuilding = template as IBuilding
		if not keep_current_cursor_position:
			var initial_global: Vector2 = _get_initial_build_position()
			if tm_ref:
				var origin_cell: Vector2i = tm_ref.local_to_map(tm_ref.to_local(initial_global))
				var best_cell: Vector2i = _find_nearest_valid_build_cell(origin_cell, tpl)
				_set_cursor_position(tm_ref.map_to_local(best_cell))
			else:
				_set_cursor_position(initial_global)

		if _preview_building:
			_preview_building.queue_free()
		_preview_building = template.duplicate() as IBuilding
		_preview_building.enter_build_preview()
		_preview_building.position = cursor.position - Vector2(0, _preview_building.get_placement_vertical_offset())
		add_child(_preview_building)
		template.free()

	if _preview_building == null:
		return

	_preview_building.position = cursor.position - Vector2(0, _preview_building.get_placement_vertical_offset())
	var tm_pos: Vector2i = tm_ref.local_to_map(cursor.global_position)

	if tm_pos != _last_tm_pos:
		_last_tm_pos = tm_pos
		var current_level: ILevel = ILevel.current_level
		if current_level and current_level.map:
			var map: IMap = current_level.map
			if map.special_tiles.has(tm_pos):
				var modifier: Dictionary = map.special_tiles[tm_pos]
				if "apply_special_modifier" in _preview_building:
					_preview_building.apply_special_modifier(modifier)
			elif "apply_special_modifier" in _preview_building:
				_preview_building.apply_special_modifier({})

	var is_buildable := _is_buildable(cursor.position)
	_preview_building.modulate = COLOR_OK if is_buildable else COLOR_KO
	_update_place_button_state(is_buildable)

	if _preview_building is ITower and (_preview_building as ITower).hover_box and (_preview_building as ITower).hover_box.get_parent():
		var hover_area: Area2D = (_preview_building as ITower).hover_box.get_parent()
		hover_area.monitoring = false
		hover_area.monitorable = false
		hover_area.input_pickable = false

func _state_build_input(event: InputEvent) -> void:
	if event is InputEventScreenDrag or event is InputEventMouseMotion:
		if _is_holding_click and not _is_dragging:
			_is_dragging = true

	if event is InputEventScreenTouch and OS.has_feature("mobile"):
		if event.is_released() and _can_reposition_build_cursor:
			_is_holding_click = false

			if _is_dragging:
				_is_dragging = false
				return

			var pos: Vector2 = tm_ref.get_global_transform_with_canvas().affine_inverse() * event.position
			_set_cursor_position(pos)
			_update()
	elif event is InputEventMouseButton and not OS.has_feature("mobile"):
		if not _can_reposition_build_cursor:
			return

		if event.is_pressed() and event.button_index == MouseButton.MOUSE_BUTTON_LEFT:
			_is_holding_click = true

		if event.is_released() and event.button_index == MouseButton.MOUSE_BUTTON_LEFT:
			_is_holding_click = false
			if _is_dragging:
				_is_dragging = false
				return

			_set_cursor_position()
			_update()
		elif event.button_index == MouseButton.MOUSE_BUTTON_RIGHT:
			_cancel_build()

func _state_idle() -> void:
	pass

func _state_upgrade() -> void:
	pass

func _update() -> void:
	_handle_state()

func _update_place_button_state(can_build: bool) -> void:
	if can_build:
		place_button.modulate = BUTTON_COLOR_ENABLED
		place_button.disabled = false
	else:
		place_button.modulate = BUTTON_COLOR_DISABLED
		place_button.disabled = true
