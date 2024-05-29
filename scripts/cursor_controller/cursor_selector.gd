extends Node2D
signal trigger_state_idle
signal trigger_state_build
signal trigger_state_upgrade

# TODO :
# state machine : idle / build / upgrade
# fix offset
# placement tour
	# apparition tour
	# modification argent
	# trigger que si placement ok
	# griser tour si placement pas ok
# BONUS :
# menu amelioration
# amelioration
# destruction (vente)

enum CURSOR_STATE {
	IDLE,
	BUILD,
	UPGRADE
}

var _state := CURSOR_STATE.BUILD

@onready var cursor = $cursor


func _process(delta: float) -> void:
	_handle_state()


func _handle_state() -> void:
	match _state:
		CURSOR_STATE.IDLE:
			_state_idle()
		CURSOR_STATE.BUILD:
			_state_build()
		CURSOR_STATE.UPGRADE:
			_state_upgrade()


func _change_state(new_state: CURSOR_STATE) -> void:
	pass


func _state_idle() -> void:
	pass


func _state_build() -> void:
	cursor.position = get_global_mouse_position()
	var p: Vector2 = cursor.position
	var s := Vector2(32, 32)
	p = floor(p / s) * s + (s / 2)
	cursor.position = p


func _state_upgrade() -> void:
	pass
