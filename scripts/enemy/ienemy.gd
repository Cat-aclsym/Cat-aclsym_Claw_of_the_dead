class_name IEnemy extends CharacterBody2D
signal die

enum ENM_State {
	FOLLOW_PATH,
	DEAD,
	GIVE_DAMAGE
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
var path: PathFollow2D = null
var previous_point: Vector2
var is_dead: bool:
	get:
		return health == 0

var is_already_dead: bool = false

@onready var Sprite: Sprite2D = $Sprite2D
@onready var AnimPlayer: AnimationPlayer = Sprite.get_node("AnimationPlayer")

# core
func _ready():
	health = max_health
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


func check_next_point() -> bool:
	var points: Array = path.curve.get_baked_points()
	var current_position: Vector2 = path.position

	if current_position == points[path.get_closest_point_index() + 1]:
		return true
	else:
		return false


func follow_path(delta: float) -> void:
	var x_pos_difference: float = path.position.x - previous_point.x;
	var y_pos_difference: float = path.position.y - previous_point.y;
	
	# todo: fix image flip not working sometimes
	if x_pos_difference > 0.:
		Sprite.flip_h = false
	elif x_pos_difference < 0.:
		Sprite.flip_h = true

	previous_point = Vector2(path.position);

	if path.get_progress_ratio() >= 1:
		# Path finished
		_give_damage_state()
		return
	path.set_progress(path.get_progress() + (speed * delta))
	if y_pos_difference > 0.:
		AnimPlayer.play(walk_up_animation)
	elif y_pos_difference < 0.:
		AnimPlayer.play(walk_down_animation)


# internal
func _dead_state() -> void:
	# todo: add money to player
	# todo: play sound
	# todo: decrease enemy count
	_disappear() # todo: remove this (debug)
#	AnimPlayer.play("Death")
#	AnimPlayer.connect("animation_finished", self, "_on_animation_finished")


func _disappear() -> void:
	if (is_already_dead): 
		return
	
	die.emit()
	AnimPlayer.play(disappear_animation)
	is_already_dead = true


func _give_damage_state() -> void:
	# when the enemy arrives at the end of the Path
	_disappear()
	# todo: reduce player health


# signals
func _on_animation_player_animation_finished(anim_name: String) -> void:
	if(anim_name) == disappear_animation:
		queue_free()
		get_parent().queue_free()
