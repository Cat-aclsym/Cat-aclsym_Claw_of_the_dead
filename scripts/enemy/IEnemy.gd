class_name IEnemy

extends CharacterBody2D

enum ENM_State {
	FOLLOW_PATH,
	DEAD,
	GIVE_DAMAGE
}

@onready var Sprite = $Sprite2D
@onready var AnimPlayer: AnimationPlayer = Sprite.get_node("AnimationPlayer")

var speed: float = 30
var health: float
var max_health: float = 100
var type: String = 'default'
var state: ENM_State = ENM_State.FOLLOW_PATH
var path: PathFollow2D = null
var previous_point: Vector2
var is_dead: bool:
	get:
		return health == 0
var disappearAnimation: String = "FadeOut"
var walkUpAnimation: String = "walk_up"
var walkDownAnimation: String = "walk_down"


func _ready():
	health = max_health


func _physics_process(delta):
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


func _dead_state():
	# todo: add money to player
	# todo: play sound
	# todo: decrease enemy count
	_disappear() # todo: remove this (debug)
#	AnimPlayer.play("Death")
#	AnimPlayer.connect("animation_finished", self, "_on_animation_finished")


func _disappear():
	AnimPlayer.play(disappearAnimation)


func _give_damage_state():
	# when the enemy arrives at the end of the Path
	_disappear()
	# todo: reduce player health
	pass


func _take_damage(damage: float):
	if(health - damage <= 0):
		health = 0
		_dead_state()
	else:
		health -= damage

func check_next_point() -> bool:
	var points = path.curve.get_baked_points()
	var current_position = path.position

	if current_position == points[path.get_closest_point_index() + 1]:
		return true
	else:
		return false

func follow_path(delta) -> void:
	var x_pos_difference = path.position.x - previous_point.x;
	var y_pos_difference = path.position.y - previous_point.y;
	
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
		AnimPlayer.play(walkUpAnimation)
	elif y_pos_difference < 0.:
		AnimPlayer.play(walkDownAnimation)


func _on_animation_player_animation_finished(anim_name):
	if(anim_name) == disappearAnimation:
		queue_free()
