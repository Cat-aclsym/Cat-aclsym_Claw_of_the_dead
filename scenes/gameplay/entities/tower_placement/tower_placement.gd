## © [2024] A7 Studio. All rights reserved. Trademark.
##
## Handles tower placement mechanics in the game.
## [br]
## This class manages tower placement, validation, and state management for building and upgrading towers.
## @tutorial: https://docs.godotengine.org/en/stable/tutorials/2d/2d_transforms.html
class_name TowerPlacement
extends Node2D

## Emitted when entering idle state
signal trigger_state_idle
## Emitted when entering build state
signal trigger_state_build
## Emitted when entering upgrade state
signal trigger_state_upgrade

const COLOR_OK := Color(1, 1, 1, 0.5)
const COLOR_KO := Color(1, 0.5, 0.5, 0.5)

const UP_OFFSET := Vector2i(-1, -1)
const RIGHT_OFFSET := Vector2i(0, -1)
const LEFT_OFFSET := Vector2i(-1, 0)
const VALID_TILES: Array[Vector2i] = [
	Vector2i(0, 1)
]

## States for the tower placement cursor
enum CursorState {
	IDLE,  ## Default state
	BUILD,  ## Tower placement state
	UPGRADE  ## Tower upgrade state
}

## Reference to the map node
var map_ref: IMap = null
## Reference to the tilemap node
var tm_ref: TileMap = null

var _invalid_cells: Array[Vector2i] = []
var _is_dragging: bool = false
var _is_holding_click: bool = false
var _is_move_tower_available: bool = true
var _state: CursorState = CursorState.IDLE
var _tower: ITower = null

## The number of towers created
static var tower_count: int = 0

@onready var cancel_place_button: TextureButton = $PlaceHUD/HBoxContainer/CancelPlaceButton
@onready var cursor: AnimatedSprite2D = $cursor
@onready var place_button: TextureButton = $PlaceHUD/HBoxContainer/PlaceButton
@onready var place_hud: Control = $PlaceHUD
@onready var place_hud_content: BoxContainer = $PlaceHUD/HBoxContainer

@onready var signals: Array[Dictionary] = [
	{SignalUtil.WHO: place_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_place_button_pressed},
	{SignalUtil.WHO: place_button, SignalUtil.WHAT: "mouse_entered", SignalUtil.TO: _on_button_mouse_entered},
	{SignalUtil.WHO: place_button, SignalUtil.WHAT: "mouse_exited", SignalUtil.TO: _on_button_mouse_exited},
	{SignalUtil.WHO: cancel_place_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_cancel_place_button_pressed},
	{SignalUtil.WHO: cancel_place_button, SignalUtil.WHAT: "mouse_entered", SignalUtil.TO: _on_button_mouse_entered},
	{SignalUtil.WHO: cancel_place_button, SignalUtil.WHAT: "mouse_exited", SignalUtil.TO: _on_button_mouse_exited},
]

# core
func _ready() -> void:
	Global.cursor = self
	visible = false
	place_hud.visible = false
	SignalUtil.connects(signals)

func _input(event: InputEvent) -> void:
	if _state == CursorState.BUILD:
		_state_build_input(event)

## Change the current state of the tower placement system
## [br]
## [param new_state] The state to change to
## [param args] Additional arguments for the state change
func change_state(new_state: CursorState, args: Array = []) -> void:
	match new_state:
		CursorState.IDLE:
			trigger_state_idle.emit()
			_state = new_state
			visible = false
		CursorState.BUILD:
			if _state != CursorState.IDLE:
				Log.trace(Log.Level.WARN, "Cannot change cursor state from BUILD to IDLE")
				return
			assert(args.size() == 1)
			assert(args[0] is ITower)

			trigger_state_build.emit()
			_state = new_state
			visible = true
			_state_build(args[0] as ITower)

		CursorState.UPGRADE:
			if _state != CursorState.IDLE:
				Log.trace(Log.Level.WARN, "Cannot change cursor state from UPGRADE to IDLE")
				return
			trigger_state_upgrade.emit()
			_state = new_state
			visible = true

	_update()

# private
func _update() -> void:
	_handle_state()

func _handle_state() -> void:
	match _state:
		CursorState.IDLE:
			_state_idle()
		CursorState.BUILD:
			_state_build()
		CursorState.UPGRADE:
			_state_upgrade()

func _set_cursor_position(pos: Vector2 = get_global_mouse_position()) -> void:
	var map_pos: Vector2i = tm_ref.local_to_map(pos)
	var local_pos: Vector2 = tm_ref.map_to_local(map_pos)
	local_pos -= Vector2(0, 8)

	cursor.position = local_pos
	cursor.visible = true
	place_hud.visible = true
	place_hud.position = local_pos

## Handles the build state logic, such as tower placement and validation
func _state_build(tower: ITower = null) -> void:
	if tower:
		_tower = tower.duplicate()
		_tower.state = ITower.TowerState.BUILDING
		add_child(_tower)
		await get_tree().create_timer(0.1).timeout

	_tower.position = cursor.position - Vector2(0, 16)
	_tower.modulate = COLOR_OK if _is_buildable(_tower.position) else COLOR_KO

## Handles the build state input events, such as mouse clicks and drags
func _state_build_input(event: InputEvent) -> void:
	if event is InputEventScreenDrag or event is InputEventMouseMotion:
		if _is_holding_click and not _is_dragging:
			_is_dragging = true

	if event is InputEventScreenTouch and OS.has_feature("mobile"):
		if event.is_released() and _is_move_tower_available:
			_is_holding_click = false

			if _is_dragging:
				_is_dragging = false
				return

			var pos: Vector2 = tm_ref.get_global_transform_with_canvas().affine_inverse() * event.position
			_set_cursor_position(pos)
			_update()
	elif event is InputEventMouseButton and not OS.has_feature("mobile"):
		if not _is_move_tower_available:
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

func _cancel_build() -> void:
	cursor.visible = false
	place_hud.visible = false
	_tower.queue_free()
	_tower = null
	change_state(CursorState.IDLE)

func _build() -> void:
	if not _is_buildable(_tower.position):
		return

	_is_move_tower_available = false

	var new_tower: ITower = _tower.duplicate()
	new_tower.state = ITower.TowerState.ACTIVE
	new_tower.modulate = Color(1, 1, 1, 1)
	new_tower.name = "tower_%d" % tower_count
	map_ref.add_child(new_tower)
	tower_count += 1


	ILevel.current_level.coins -= _tower.cost

	var tm_pos: Array[Vector2i] = [
		tm_ref.local_to_map(new_tower.position),
		tm_ref.local_to_map(new_tower.position) - UP_OFFSET,
		tm_ref.local_to_map(new_tower.position) - RIGHT_OFFSET,
		tm_ref.local_to_map(new_tower.position) - LEFT_OFFSET,
	]

	for p in tm_pos:
		_invalid_cells.append(p)

	_cancel_build()
	_is_move_tower_available = true

func _is_buildable(pos: Vector2) -> bool:
	if ILevel.current_level.coins < _tower.cost:
		return false

	var tm_pos: Array[Vector2i] = [
		tm_ref.local_to_map(pos),
		tm_ref.local_to_map(pos) - UP_OFFSET,
		tm_ref.local_to_map(pos) - RIGHT_OFFSET,
		tm_ref.local_to_map(pos) - LEFT_OFFSET,
	]

	for p in tm_pos:
		if not tm_ref.get_cell_atlas_coords(0, p) in VALID_TILES or p in _invalid_cells:
			return false

		if tm_ref.get_cell_atlas_coords(1, p) != Vector2i(-1, -1):
			return false

	return true

func _on_place_button_pressed() -> void:
	_build()

func _on_cancel_place_button_pressed() -> void:
	_cancel_build()

func _on_button_mouse_entered() -> void:
	_is_move_tower_available = false

func _on_button_mouse_exited() -> void:
	_is_move_tower_available = true
