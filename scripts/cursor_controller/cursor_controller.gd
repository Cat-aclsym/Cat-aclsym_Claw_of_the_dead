class_name CursorController
extends Node2D

signal trigger_state_idle
signal trigger_state_build
signal trigger_state_upgrade

# TODO :
# state machine : idle / build / upgrade OK
# fix offset ~~
# placement tour
	# apparition tour OK
	# modification argent OK
	# trigger que si placement ok ~~
	# griser tour si placement ko ~~
# BONUS :
# menu amelioration
# amelioration
# destruction (vente)

const COLOR_OK := Color(1, 1, 1, 0.5)
const COLOR_KO := Color(1, 0.5, 0.5, 0.5)
const UP_OFFSET := Vector2i(-1, -1)
const RIGHT_OFFSET := Vector2i(0, -1)
const LEFT_OFFSET := Vector2i(-1, 0)
const VALID_TILES := [
	Vector2i(0, 1)
]

enum CURSOR_STATE {
	IDLE,
	BUILD,
	UPGRADE
}

var map_ref: IMap = null
var tm_ref: TileMap = null
var _state: CURSOR_STATE = CURSOR_STATE.IDLE
var _tower: ITower = null
var _is_mouse_available: bool = true
var _invalid_cells: Array = []
var _last_pos := Vector2.ZERO

@onready var cursor: AnimatedSprite2D = $cursor
@onready var PlaceHUD: Control = $PlaceHUD
@onready var PlaceHUDContent: BoxContainer = $PlaceHUD/HBoxContainer


# core
func _ready() -> void:
	Global.cursor = self
	visible = false
	PlaceHUD.visible = false


func _input(event: InputEvent) -> void:
	if _state == CURSOR_STATE.BUILD:
		_state_build_input(event)


# functionnal
func change_state(new_state: CURSOR_STATE, args: Array = []) -> void:
	match new_state:
		CURSOR_STATE.IDLE:
			trigger_state_idle.emit()
			_state = new_state
			visible = false
		CURSOR_STATE.BUILD:
			if _state != CURSOR_STATE.IDLE:
				Log.warning("Cannot change cursor state from BUILD to IDLE")
				return
			assert(args.size() == 1)
			assert(args[0] is ITower)

			trigger_state_build.emit()
			_state = new_state
			visible = true
			_state_build(args[0] as ITower)

		CURSOR_STATE.UPGRADE:
			if _state != CURSOR_STATE.IDLE:
				Log.warning("Cannot change cursor state from UPGRADE to IDLE")
				return
			trigger_state_upgrade.emit()
			_state = new_state
			visible = true
	
	_update()


# internal
func _update() -> void:
	_handle_state()


func _handle_state() -> void:
	match _state:
		CURSOR_STATE.IDLE:
			_state_idle()
		CURSOR_STATE.BUILD:
			_state_build()
		CURSOR_STATE.UPGRADE:
			_state_upgrade()


func _set_cursor_position(pos: Vector2 = get_global_mouse_position()) -> void:
	var a: Vector2i = tm_ref.local_to_map(pos)
	var b: Vector2 = tm_ref.map_to_local(a)
	b -= Vector2(0, 8)
	cursor.position = b
	cursor.visible = true
	PlaceHUD.visible = true

	PlaceHUD.position = b
	PlaceHUD.position.x -= PlaceHUDContent.size.x * PlaceHUD.scale.x / 2
	PlaceHUD.position.y += PlaceHUDContent.size.y * PlaceHUD.scale.y / 2
	
	if _last_pos == b:
		_build()
	else:
		_last_pos = b


func _state_build(tower: ITower = null) -> void:
	# add tower ghost
	if tower:
		_tower = tower.duplicate()
		_tower.deactivate = true
		add_child(_tower)
		# Avoid placing tower same frame as the tower is selected
		#await get_tree().create_timer(0.1).timeout

	# make tower ghost follow cursor
	_tower.position = cursor.position - Vector2(0, 16)

	# change tower ghost color depending of placement
	_tower.modulate = COLOR_OK if _is_buildable(_tower.position) else COLOR_KO


func _state_build_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and not Global.PC_DEBUG:
		if event.pressed:
			_set_cursor_position(event.position)
			_update()
	# debug
	elif event is InputEventMouseButton and Global.PC_DEBUG:
		if not _is_mouse_available:
			return
		if event.is_pressed() and event.button_index == MouseButton.MOUSE_BUTTON_LEFT:
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
	PlaceHUD.visible = false
	_tower.queue_free()
	_tower = null
	change_state(CURSOR_STATE.IDLE)
	_last_pos = Vector2.ZERO


func _build() -> void:
	if !_is_buildable(_tower.position):
		return

	var new_tower: ITower = _tower.duplicate()
	new_tower.deactivate = false
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
	_is_mouse_available = false


func _on_button_mouse_exited() -> void:
	_is_mouse_available = true
