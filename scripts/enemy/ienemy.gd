class_name IEnemy extends CharacterBody2D
signal die

const ANIM_FADE_OUT: String = "fade_out"
const ANIM_WALK_UP: String = "walk_up"
const ANIM_WALK_DOWN: String = "walk_down"

enum ENM_State {
	FOLLOW_PATH,
	DEAD,
	GIVE_DAMAGE
}

enum ENM_Direction {
	UP_RIGHT,
	UP_LEFT,
	DOWN_RIGHT,
	DOWN_LEFT
}

enum ENM_Type {
	DEFAULT,
	BIG_DADDY,
}

@export var speed: float = 30
@export var max_health: float = 100
@export var type: ENM_Type = ENM_Type.DEFAULT

var health: float
var state: ENM_State = ENM_State.FOLLOW_PATH
var path_follow: PathFollow2D = null
var path: Path2D = null
var direction: ENM_Direction = ENM_Direction.UP_RIGHT
var is_dead: bool:
	get:
		return health == 0
var is_already_dead: bool = false
var current_point_id: int = 0
var path_points_size: int

@onready var Sprite: Sprite2D = $Sprite2D
@onready var AnimPlayer: AnimationPlayer = $AnimationPlayer


# core
func _ready():
	health = max_health
	path_points_size = path.curve.point_count
	_get_path_direction()
	AnimPlayer.connect("animation_finished", _on_animation_player_animation_finished)


func _physics_process(delta: float) -> void:
	if(is_dead): return
	match state:
		ENM_State.FOLLOW_PATH:
			follow_path(delta)
		ENM_State.DEAD:
			_dead_state()
		ENM_State.GIVE_DAMAGE:
			_give_damage_state()
		_:
			Log.warning("{0} unknown ENM_State : {1}".format([name, state]))


# functionnal
func take_damage(damage: float) -> void:
	if(health - damage <= 0):
		health = 0
		_dead_state()
	else:
		health -= damage


func follow_path(delta: float) -> void:
	if path_follow.get_progress_ratio() >= 1: # Path finished
		_give_damage_state()
		return
	
	path_follow.set_progress(path_follow.get_progress() + (speed * delta))
	_update_direction()
	_walk()


# internal
func _get_path_direction():
	var x_pos_difference: float = path.curve.get_point_position(current_point_id).x - path.curve.get_point_position(current_point_id + 1).x;
	var y_pos_difference: float = path.curve.get_point_position(current_point_id).y - path.curve.get_point_position(current_point_id + 1).y;
	
	if x_pos_difference < 0.:
		if y_pos_difference < 0.:
			direction = ENM_Direction.DOWN_RIGHT
		elif y_pos_difference > 0.:
			direction = ENM_Direction.UP_RIGHT
	elif x_pos_difference > 0.:
		if y_pos_difference < 0.:
			direction = ENM_Direction.DOWN_LEFT
		elif y_pos_difference > 0.:
			direction = ENM_Direction.UP_LEFT


func _update_direction():
	if current_point_id == path_points_size - 2:
		return
		
	if (
		round(path_follow.position) == round(path.curve.get_point_position(current_point_id+1)) 
		&& path.curve.get_closest_point(path_follow.position) != path.curve.get_point_position(current_point_id)
	):
		#Log.debug("{0}::_update_direction() parent = {1} changed direction = {2}".format([name, get_parent().name, direction]))
		current_point_id += 1
		_get_path_direction()
		

func _walk():
	match direction:
		ENM_Direction.UP_RIGHT:
			Sprite.flip_h = false
			AnimPlayer.play(ANIM_WALK_UP)
		ENM_Direction.UP_LEFT:
			Sprite.flip_h = true
			AnimPlayer.play(ANIM_WALK_UP)
		ENM_Direction.DOWN_RIGHT:
			Sprite.flip_h = false
			AnimPlayer.play(ANIM_WALK_DOWN)
		ENM_Direction.DOWN_LEFT:
			Sprite.flip_h = true
			AnimPlayer.play(ANIM_WALK_DOWN)
		_:
			Log.warning("{0}::_walk() direction does not match ENM_Direction enum".format([name]))


func _disappear() -> void:
	if (is_already_dead):
		return

	die.emit()
	AnimPlayer.play(ANIM_FADE_OUT)
	is_already_dead = true


func _dead_state() -> void:
	# todo: add money to player
	# todo: play sound
	# todo: decrease enemy count
	_disappear()


func _give_damage_state() -> void:
	# when the enemy arrives at the end of the Path
	_disappear()
	# todo: reduce player health


# signals
func _on_animation_player_animation_finished(anim_name: String) -> void:
	if (anim_name == ANIM_FADE_OUT):
		queue_free()
		get_parent().queue_free()
