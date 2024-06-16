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

enum CURSOR_STATE {
	IDLE,
	BUILD,
	UPGRADE
}

var map_ref: IMap = null
var tm_ref: TileMap = null
var _state: CURSOR_STATE = CURSOR_STATE.IDLE
var _tower: ITower = null

@onready var cursor: AnimatedSprite2D = $cursor
@onready var PlaceHUD: CanvasLayer = $PlaceHUD
@onready var PlaceHUDContent: BoxContainer = $PlaceHUD/HBoxContainer


func _ready() -> void:
	Global.cursor = self
	visible = false
	PlaceHUD.visible = false


func _process(_delta: float) -> void:
	_handle_state()


func _input(event: InputEvent) -> void:
	if _state == CURSOR_STATE.IDLE: return
	elif event is InputEventScreenTouch:
		if event.pressed:
			_set_cursor_position(event.position)
	elif event is InputEventMouseButton:
		if event.button_index == MouseButton.MOUSE_BUTTON_WHEEL_UP:
			_set_cursor_position()
		elif event.button_index == MouseButton.MOUSE_BUTTON_WHEEL_DOWN:
			_set_cursor_position()
		if event.button_index == MouseButton.MOUSE_BUTTON_LEFT:
			_set_cursor_position()
		elif event.button_index == MouseButton.MOUSE_BUTTON_RIGHT:
			_cancel_build()


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


func _handle_state() -> void:
	match _state:
		CURSOR_STATE.IDLE:
			_state_idle()
		CURSOR_STATE.BUILD:
			_state_build()
		CURSOR_STATE.UPGRADE:
			_state_upgrade()


func _set_cursor_position(position: Vector2 = get_global_mouse_position()) -> void:
	var a: Vector2i = tm_ref.local_to_map(position)
	var b: Vector2 = tm_ref.map_to_local(a)
	b -= Vector2(0, 8)
	cursor.position = b
	cursor.visible = true
	PlaceHUD.visible = true

	PlaceHUD.offset = get_global_transform_with_canvas() * b
	PlaceHUD.offset.x -= PlaceHUDContent.size.x / 2
	PlaceHUD.offset.y += PlaceHUDContent.size.y / 2


func _state_build(tower: ITower = null) -> void:
	# add tower ghost
	if tower:
		_tower = tower.duplicate()
		_tower.deactivate = true
		add_child(_tower)
		# Avoid placing tower same frame as the tower is selected
		await get_tree().create_timer(0.1).timeout

	# make tower ghost follow cursor
	_tower.position = cursor.position - Vector2(0, 16)

	# change tower ghost color depending of placement
	if _is_buildable(_tower.position):
		_tower.modulate = COLOR_OK
	else:
		_tower.modulate = COLOR_KO

# handle inputs
	if Input.is_action_just_pressed("place_tower"):
		_set_cursor_position()
#		_build()
#	if Input.is_action_just_pressed("rmb"):
#		_cancel_build()


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


func _build() -> void:
	if !_is_buildable(_tower.position):
		return

	var new_tower: ITower = _tower.duplicate()
	new_tower.deactivate = false
	new_tower.modulate = Color(1, 1, 1, 1)
	map_ref.add_child(new_tower)

	ILevel.current_level.coins -= _tower.cost

	_cancel_build()


func _is_buildable(pos: Vector2) -> bool:
	if ILevel.current_level.coins < _tower.cost:
		return false

	#var atlas_coords: Vector2 = tm_ref.get_cell_atlas_coords(0, tm_ref.local_to_map(pos))
	#Log.debug("atlas coords = {0}; buildable = {1}".format([atlas_coords, true]))

	return true


func _on_place_button_pressed() -> void:
	_build()


func _on_cancel_place_button_pressed() -> void:
	_cancel_build()
