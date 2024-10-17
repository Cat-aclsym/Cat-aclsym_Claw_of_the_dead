## © [2024] A7 Studio. All rights reserved. Trademark.
class_name CursorController
extends Node2D

signal trigger_state_idle
signal trigger_state_build
signal trigger_state_upgrade

const COLOR_OK := Color(1, 1, 1, 0.5)
const COLOR_KO := Color(1, 0.5, 0.5, 0.5)
const UP_OFFSET := Vector2i(-1, -1)
const RIGHT_OFFSET := Vector2i(0, -1)
const LEFT_OFFSET := Vector2i(-1, 0)
const VALID_TILES: Array[Vector2i] = [
	Vector2i(0, 1)
]

enum CursorState {
	IDLE,
	BUILD,
	UPGRADE
}

var map_ref: IMap = null
var tm_ref: TileMap = null

var _state: CursorState = CursorState.IDLE
var _tower: ITower = null
var _is_move_tower_available: bool = true
var _invalid_cells: Array = []
var _is_dragging: bool = false
var _is_holding_click: bool = false

@onready var cursor: AnimatedSprite2D = $cursor
@onready var place_hud: Control = $PlaceHUD
@onready var place_hud_content: BoxContainer = $PlaceHUD/HBoxContainer


# core
func _ready() -> void:
	Global.cursor = self
	visible = false
	place_hud.visible = false


func _input(event: InputEvent) -> void:
	if _state == CursorState.BUILD:
		_state_build_input(event)


# public
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
	var a: Vector2i = tm_ref.local_to_map(pos)
	var b: Vector2 = tm_ref.map_to_local(a)
	b -= Vector2(0, 8)
	cursor.position = b
	cursor.visible = true
	place_hud.visible = true

	place_hud.position = b


func _state_build(tower: ITower = null) -> void:
	# add tower ghost
	if tower:
		_tower = tower.duplicate()
		_tower.state = ITower.TowerState.BUILDING
		add_child(_tower)
		# Avoid placing tower same frame as the tower is selected
		await get_tree().create_timer(0.1).timeout

	# make tower ghost follow cursor
	_tower.position = cursor.position - Vector2(0, 16)

	# change tower ghost color depending of placement
	_tower.modulate = COLOR_OK if _is_buildable(_tower.position) else COLOR_KO


func _state_build_input(event: InputEvent) -> void:
	if event is InputEventScreenDrag or event is InputEventMouseMotion:
		# Check if the drag is long enough to be considered a drag
		if _is_holding_click:
			if not _is_dragging:
				_is_dragging = true

	if event is InputEventScreenTouch and OS.has_feature("mobile"):
		if event.is_released() and _is_move_tower_available:
			_is_holding_click = false

			if _is_dragging:
				_is_dragging = false
				return

			# Fix event position
			var pos: Vector2 = tm_ref.get_global_transform_with_canvas().affine_inverse() * event.position
			_set_cursor_position(pos)
			_update()
	# debug
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
	if !_is_buildable(_tower.position):
		return

	_is_move_tower_available = false

	var new_tower: ITower = _tower.duplicate()
	new_tower.state = ITower.TowerState.ACTIVE
	new_tower.modulate = Color(1, 1, 1, 1)
	map_ref.add_child(new_tower)

	ILevel.current_level.coins -= _tower.cost

	var tm_pos: Array = [
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

	var tm_pos: Array = [
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


# signals
func _on_place_button_pressed() -> void:
	_build()


func _on_cancel_place_button_pressed() -> void:
	_cancel_build()


func _on_button_mouse_entered() -> void:
	_is_move_tower_available = false


func _on_button_mouse_exited() -> void:
	_is_move_tower_available = true


# event


# setget
