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
var _state := CURSOR_STATE.IDLE
var _tower: ITower = null

@onready var cursor = $cursor


func _ready() -> void:
	Global.cursor = self


func _process(delta: float) -> void:
	_handle_state()


func change_state(new_state: CURSOR_STATE, args: Array = []) -> void:
	Log.debug("Try changing state from '{0}' to '{1}'".format([_state, new_state]))
	match new_state:
		CURSOR_STATE.IDLE:
			_state = new_state
			trigger_state_idle.emit()
			_state = new_state
		CURSOR_STATE.BUILD:
			if _state != CURSOR_STATE.IDLE:
				Log.debug("State change fail")
				return 
			assert(args.size() == 1)
			assert(args[0] is ITower)
		
			trigger_state_build.emit()
			_state = new_state
			_state_build(args[0] as ITower)
		
		CURSOR_STATE.UPGRADE:
			if _state != CURSOR_STATE.IDLE:
				Log.debug("State change fail")
				return 
			trigger_state_upgrade.emit()
			_state = new_state
			
			
func _handle_state() -> void:
	match _state:
		CURSOR_STATE.IDLE:
			_state_idle()
		CURSOR_STATE.BUILD:
			_state_build()
		CURSOR_STATE.UPGRADE:
			_state_upgrade()



func _state_idle() -> void:
	pass


func _state_build(tower: ITower = null) -> void:
	# add tower ghost
	if tower:
		_tower = tower.duplicate()
		_tower.deactivate = true
		add_child(_tower)
		Log.debug("New tower")
	
	# display cursor
	cursor.visible = true
	var a = tm_ref.local_to_map(get_global_mouse_position())
	var b = tm_ref.map_to_local(a)
	b -= Vector2(0, 8)
	cursor.position = b
	
	# make tower ghost follow cursor
	_tower.position = cursor.position - Vector2(0, 16)
	
	# change tower ghost color depending of placement
	if _is_buildable(_tower.position):
		_tower.modulate = COLOR_OK
	else:
		_tower.modulate = COLOR_KO
		
	# handle inputs
	if Input.is_action_just_pressed("lmb"):
		_is_buildable(_tower.position)
		#_build()
	if Input.is_action_just_pressed("rmb"):
		_cancel_build()
	

func _state_upgrade() -> void:
	pass
	

func _cancel_build() -> void:
	cursor.visible = false
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
		
	var atlas_coords: Vector2 = tm_ref.get_cell_atlas_coords(0, tm_ref.local_to_map(pos))
	Log.debug("atlas coords = {0}; buildable = {1}".format([atlas_coords, true]))	
		
	return true
