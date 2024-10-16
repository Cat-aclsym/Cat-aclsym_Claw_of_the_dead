class_name IEnemy
extends CharacterBody2D

signal die
signal camera_effect(effect: String)

const ANIM_FADE_OUT := "fade_out"
const ANIM_WALK_UP := "walk_up"
const ANIM_WALK_DOWN := "walk_down"

enum EnemyState {
	FOLLOW_PATH,
	DEAD,
	GIVE_DAMAGE
}

enum EnemyDirection {
	UP_RIGHT,
	UP_LEFT,
	DOWN_RIGHT,
	DOWN_LEFT
}

enum EnemyType {
	DEFAULT,
	BIG_DADDY,
	FAT
}


const DAMAGES: Dictionary = {
	"default": {"color": Color(0.7, 0.5, 0.5, 1)},
	"poison": {"color": Color(0.7, 0.5, 0.7, 1)}
}

@export var speed: float = 30
@export var max_health: float = 20
@export var type: EnemyType = EnemyType.DEFAULT


var active_poison_timers: Array = []
var current_point_id: int = 0
var direction: EnemyDirection = EnemyDirection.UP_RIGHT
var health: float
var is_already_dead: bool = false
var path: Path2D = null
var path_follow: PathFollow2D = null
var poison_timer_execution_count: int = 0
var state: EnemyState = EnemyState.FOLLOW_PATH

@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var poison_particle: GPUParticles2D = $GPUParticles2D
@onready var popup_score_spawner: PopupSpawner = $PopupScoreSpawner
@onready var sprite: Sprite2D = $Sprite2D
@onready var old_modulate: Color = sprite.modulate
@onready var path_points_size: int = path.curve.point_count


# core
func _ready():
	if type == EnemyType.FAT:
		camera_effect.connect(Global.camera.handle_effect)
		camera_effect.emit('shake')

	health = max_health
	_set_path_direction()


func _physics_process(delta: float) -> void:
	if is_already_dead: return
	if Global.paused: return

	_update_z_index()

	match state:
		EnemyState.FOLLOW_PATH:
			follow_path(delta)
		EnemyState.DEAD:
			_dead_state()
		EnemyState.GIVE_DAMAGE:
			_give_damage_state()
		_:
			Log.trace(Log.Level.WARN, "{0} unknown EnemyState : {1}".format([name, state]))

	# handle poison particles
	poison_particle.emitting = not active_poison_timers.is_empty()


# public
func take_damage(damage: float, damage_type: String) -> void:
	if is_already_dead: return
	_damage_effect(DAMAGES[damage_type]["color"])
	if health - damage <= 0:
		health = 0
		state = EnemyState.DEAD
	else:
		health -= damage


func follow_path(delta: float) -> void:
	if path_follow.get_progress_ratio() >= 1:  ## Path is finished
		state = EnemyState.GIVE_DAMAGE
		return

	path_follow.set_progress(path_follow.get_progress() + (speed * delta))
	_update_direction()
	_walk()


func add_poison_effect(damage: float, total_execution: int, interval: float) -> void:
	# add a timer to the active_poison_timers array
	var poison_timer := Timer.new()
	add_child(poison_timer)
	poison_timer.set_wait_time(interval)
	poison_timer.set_one_shot(false)
	poison_timer.start()
	active_poison_timers.append({"timer": poison_timer, "damage": damage, "total_execution": total_execution, "interval": interval, "current_execution": 0})
	# connect the timer to the _on_poison_timer_timeout function
	poison_timer.timeout.connect(func(): _on_poison_timer_timeout(poison_timer))


# private
func _damage_effect(color: Color):
	sprite.modulate = color
	await get_tree().create_timer(0.1).timeout
	sprite.modulate = old_modulate


func _set_path_direction() -> void:
	var x_pos_difference: float = path.curve.get_point_position(current_point_id).x - path.curve.get_point_position(current_point_id + 1).x;
	var y_pos_difference: float = path.curve.get_point_position(current_point_id).y - path.curve.get_point_position(current_point_id + 1).y;

	var is_going_up := y_pos_difference > 0
	var is_going_down := y_pos_difference < 0
	var is_going_right := x_pos_difference < 0
	var is_going_left := x_pos_difference > 0

	if is_going_right:
		if is_going_down:
			direction = EnemyDirection.DOWN_RIGHT
		elif is_going_up:
			direction = EnemyDirection.UP_RIGHT
	elif is_going_left:
		if is_going_down:
			direction = EnemyDirection.DOWN_LEFT
		elif is_going_up:
			direction = EnemyDirection.UP_LEFT



func _update_direction() -> void:
	if current_point_id == path_points_size - 2:
		return

	if (
		round(path_follow.position) == round(path.curve.get_point_position(current_point_id + 1)) &&
		path.curve.get_closest_point(path_follow.position) != path.curve.get_point_position(current_point_id)
	):
		current_point_id += 1
		_set_path_direction()


func _walk():
	match direction:
		EnemyDirection.UP_RIGHT:
			sprite.flip_h = false
			anim_player.play(ANIM_WALK_UP)
		EnemyDirection.UP_LEFT:
			sprite.flip_h = true
			anim_player.play(ANIM_WALK_UP)
		EnemyDirection.DOWN_RIGHT:
			sprite.flip_h = false
			anim_player.play(ANIM_WALK_DOWN)
		EnemyDirection.DOWN_LEFT:
			sprite.flip_h = true
			anim_player.play(ANIM_WALK_DOWN)
		_:
			Log.trace(Log.Level.WARN, "{0}::_walk() direction does not match EnemyDirection enum".format([name]))


func _disappear() -> void:
	if is_already_dead: return
	die.emit()
	anim_player.play(ANIM_FADE_OUT)
	is_already_dead = true


func _dead_state() -> void:
	if ILevel.current_level == null:
		Log.trace(Log.Level.ERROR, "Current level is null, aborting.")
		return
	var money_reward: int = 10
	ILevel.current_level.coins += money_reward
	popup_score_spawner.score("+%s$" % [int(money_reward)])
	_disappear()
	collision_shape.set_deferred("disabled", true)

	# wait for the animation to finish
	await anim_player.animation_finished
	queue_free()
	path_follow.queue_free()


func _give_damage_state() -> void:
	# when the enemy arrives at the end of the Path
	_disappear()
	if ILevel.current_level == null:
		Log.trace(Log.Level.ERROR, "Current level is null, aborting.")
		return

	# if boss insta death
	if type == EnemyType.BIG_DADDY or type == EnemyType.FAT:
		ILevel.current_level.health = 0
	else:
		ILevel.current_level.health -= ceil(health/2)


## Function to check the z position of the tower and adapt the z index of the tower.
func _update_z_index() -> void:
	var y_position: int = int(global_position.y)
	z_index = y_position if y_position else 0


# signals
func _on_poison_timer_timeout(timer: Timer):
	# get the timer that called the function
	var timer_index: int = -1
	for i in range(active_poison_timers.size()):
		if active_poison_timers[i]["timer"] == timer:
			timer_index = i
			break
	active_poison_timers[timer_index]["current_execution"] += 1

	# track the highest timer in active_poison_timers based on the ratio of damage/interval
	var highest_timer_ratio: float = 0
	var highest_timer_index: int = 0
	var _highest_timer: Timer = null
	for i in range(active_poison_timers.size()):
		var ratio: float = (active_poison_timers[i]["damage"] * active_poison_timers[i]["total_execution"]) / (active_poison_timers[i]["total_execution"] * active_poison_timers[i]["interval"])
		if ratio > highest_timer_ratio:
			highest_timer_ratio = ratio
			highest_timer_index = i
			_highest_timer = active_poison_timers[i]["timer"]

	# check if the timer is the highest
	if timer_index == highest_timer_index:
		# apply the poison damage
		take_damage(active_poison_timers[highest_timer_index]["damage"], "poison")
		# check if the poison has reached its total_execution
		if active_poison_timers[highest_timer_index]["current_execution"] >= active_poison_timers[highest_timer_index]["total_execution"]:
			# remove the timer from the active_poison_timers array
			active_poison_timers.remove_at(timer_index)
			# stop the timer
			timer.stop()
			# remove the timer from the scene
			timer.queue_free()
		else:
			# start the next execution
			timer.start()
