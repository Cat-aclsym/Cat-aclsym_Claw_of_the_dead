class_name IEnemy extends CharacterBody2D

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

var disappear_animation: String = "FadeOut"
var walk_up_animation: String = "walk_up"
var walk_down_animation: String = "walk_down"

var health: float
var state: ENM_State = ENM_State.FOLLOW_PATH
var path_follow: PathFollow2D = null
var path: Path2D = null
var direction: ENM_Direction = ENM_Direction.UP_RIGHT
var is_dead: bool:
	get:
		return health == 0
var current_point_id: int = 0
var path_points_size: int

@onready var Sprite: Sprite2D = $Sprite2D
@onready var AnimPlayer: AnimationPlayer = Sprite.get_node("AnimationPlayer")


# core
func _ready():
	health = max_health
	path_points_size = path.curve.get_baked_points().size()
	_get_path_direction()
	current_point_id += 1
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
			pass

	follow_path(delta)
	#_take_damage(1)
	#print(health)


# functionnal
func take_damage(damage: float) -> void:
	if(health - damage <= 0):
		health = 0
		_dead_state()
	else:
		health -= damage


func _get_path_direction():
	var x_pos_difference: float = path.curve.get_point_position(current_point_id).x - path.curve.get_point_position(current_point_id+1).x;
	var y_pos_difference: float = path.curve.get_point_position(current_point_id).y - path.curve.get_point_position(current_point_id+1).y;

	# todo: fix image flip not working sometimes
	if x_pos_difference > 0.:
		if y_pos_difference < 0.:
			direction = ENM_Direction.DOWN_RIGHT  # Moving right down
		elif y_pos_difference > 0.:
			direction = ENM_Direction.UP_RIGHT  # Moving right up
	elif x_pos_difference < 0.:
		if y_pos_difference < 0.:
			direction = ENM_Direction.DOWN_LEFT  # Moving left down
		elif y_pos_difference > 0.:
			direction = ENM_Direction.UP_LEFT  # Moving left up


func _update_direction():
	print(current_point_id)
	print(path_follow.position, path.curve.get_point_position(current_point_id+1))
	if path_follow.position == path.curve.get_point_position(current_point_id+1):
		print("changed direction")
		_get_path_direction()
		current_point_id += 1


func follow_path(delta: float) -> void:
	if path_follow.get_progress_ratio() >= 1:
		# Path finished
		_give_damage_state()
		return
	path_follow.set_progress(path_follow.get_progress() + (speed * delta))
	_update_direction()
	_walk()


func _walk():
	match direction:
		ENM_Direction.UP_RIGHT:
			Sprite.flip_h = false
			AnimPlayer.play(walk_up_animation)
		ENM_Direction.UP_LEFT:
			Sprite.flip_h = true
			AnimPlayer.play(walk_up_animation)
		ENM_Direction.DOWN_RIGHT:
			Sprite.flip_h = false
			AnimPlayer.play(walk_down_animation)
		ENM_Direction.DOWN_LEFT:
			Sprite.flip_h = true
			AnimPlayer.play(walk_down_animation)
		_:
			pass


# internal
func _dead_state() -> void:
	# todo: add money to player
	# todo: play sound
	# todo: decrease enemy count
	_disappear() # todo: remove this (debug)
#	AnimPlayer.play("Death")
#	AnimPlayer.connect("animation_finished", self, "_on_animation_finished")


func _disappear() -> void:
	AnimPlayer.play(disappear_animation)


func _give_damage_state() -> void:
	# when the enemy arrives at the end of the Path
	_disappear()
	# todo: reduce player health


# signals
func _on_animation_player_animation_finished(anim_name: String) -> void:
	if(anim_name) == disappear_animation:
		queue_free()
		get_parent().queue_free()
