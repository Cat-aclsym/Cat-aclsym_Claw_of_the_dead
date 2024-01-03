extends CharacterBody2D

enum ENM_State {
	FOLLOW_PATH,
	DEAD,
	GIVE_DAMAGE
}

@onready var Sprite = $Sprite2D
@onready var AnimPlayer = Sprite.get_node("AnimationPlayer")
@onready var Path = get_parent()
@onready var previous_point: Vector2 = Vector2(Path.position)

var speed: float = 50
var health: float
var max_health: float = 100
var state: ENM_State = ENM_State.FOLLOW_PATH


func _ready():
	health = max_health


func _physics_process(delta):
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


func _die():
	# play death animation, wait for it to finish, then queue_free()
	#todo: add death animation
	#AnimPlayer.play("Death")
	#await AnimPlayer.animation_finished
	queue_free()


func _disappear():
	# play disappear animation with fade and queue free
	# fade opacity to 0 in 1 second
	AnimPlayer.play("FadeOut")
	await AnimPlayer.animation_finished
	queue_free()
	pass


func _give_damage_state():
	# when the enemy arrives at the end of the Path
	_disappear()
	# queue free
	# reduce player health
	# dead animation
	pass


func _take_damage(damage: float):
	if(health - damage <= 0):
		health = 0
		_die()
	else:
		health -= damage

func _dead_state():
	# play death animation, wait for it to finish, then queue_free()
	# todo: add money
	# todo: play sound
	# todo: decrease enemy count
	$AnimationPlayer.play("Death")
	await $AnimationPlayer.animation_finished
	queue_free()


func follow_path(delta) -> void:
	var x_pos_difference = Path.position.x - previous_point.x;
	var y_pos_difference = Path.position.y - previous_point.y;

	# todo: fix image flip not working sometimes
	if x_pos_difference > 0:
		Sprite.flip_h = false
	elif x_pos_difference < 0:
		Sprite.flip_h = true

	previous_point = Vector2(Path.position);

	if Path.get_progress_ratio() >= 1:
		# Path finished
		_give_damage_state()
		return
	Path.set_progress(Path.get_progress() + (speed * delta))
	# todo: walk animation
