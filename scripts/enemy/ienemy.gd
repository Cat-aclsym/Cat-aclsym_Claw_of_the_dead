class_name IEnemy
extends CharacterBody2D

signal die
signal camera_effect(effect: String)

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
	FAT
}


var DAMAGE: Dictionary = {
	"default": {"color": Color(0.7, 0.5, 0.5, 1)},
	"poison": {"color": Color(0.7, 0.5, 0.7, 1)}
}

@export var speed: float = 30
@export var max_health: float = 20
@export var type: ENM_Type = ENM_Type.DEFAULT


var active_poison_timers: Array = []
var current_point_id: int = 0
var direction: ENM_Direction = ENM_Direction.UP_RIGHT
var health: float
var is_already_dead: bool = false
var path: Path2D = null
var path_follow: PathFollow2D = null
var poison_timer_execution_count: int = 0
var state: ENM_State = ENM_State.FOLLOW_PATH

@onready var AnimPlayer: AnimationPlayer = $AnimationPlayer
@onready var CollisionShape: CollisionShape2D = $CollisionShape2D
@onready var PoisionParticles: GPUParticles2D = $GPUParticles2D
@onready var PopupScoreSpawner: PopupSpawner = $PopupScoreSpawner
@onready var Sprite: Sprite2D = $Sprite2D
@onready var old_modulate: Color = Sprite.modulate
@onready var path_points_size: int = path.curve.point_count


# core
func _ready():
	if type == ENM_Type.FAT:
		camera_effect.connect(Global.camera.handle_effect)
		camera_effect.emit('shake')

	health = max_health
	_set_path_direction()
	AnimPlayer.animation_changed.connect(_on_animation_player_animation_finished)


func _physics_process(delta: float) -> void:
	if is_already_dead: return
	if Global.paused: return

	_update_z_index()

	match state:
		ENM_State.FOLLOW_PATH:
			follow_path(delta)
		ENM_State.DEAD:
			_dead_state()
		ENM_State.GIVE_DAMAGE:
			_give_damage_state()
		_:
			Log.trace(Log.Level.WARN, "{0} unknown ENM_State : {1}".format([name, state]))

	# handle poison particles
	PoisionParticles.emitting = not active_poison_timers.is_empty()


func _damage_effect(color: Color):
	Sprite.modulate = color
	await get_tree().create_timer(0.1).timeout
	Sprite.modulate = old_modulate


# functionnal
func take_damage(damage: float, damage_type: String) -> void:
	if is_already_dead: return
	_damage_effect(DAMAGE[damage_type]["color"])
	if health - damage <= 0:
		health = 0
		state = ENM_State.DEAD
	else:
		health -= damage


func follow_path(delta: float) -> void:
	if path_follow.get_progress_ratio() >= 1:  ## Path is finished
		state = ENM_State.GIVE_DAMAGE
		return

	path_follow.set_progress(path_follow.get_progress() + (speed * delta))
	_update_direction()
	_walk()


func add_poison_effect(damage: float, total_execution: int, interval: float) -> void:
	# add a timer to the active_poison_timers array
	var poison_timer: Timer = Timer.new()
	add_child(poison_timer)
	poison_timer.set_wait_time(interval)
	poison_timer.set_one_shot(false)
	poison_timer.start()
	active_poison_timers.append({"timer": poison_timer, "damage": damage, "total_execution": total_execution, "interval": interval, "current_execution": 0})
	# connect the timer to the _on_poison_timer_timeout function
	poison_timer.timeout.connect(func(): _on_poison_timer_timeout(poison_timer))


# internal
func _set_path_direction() -> void:
	var x_pos_difference: float = path.curve.get_point_position(current_point_id).x - path.curve.get_point_position(current_point_id + 1).x;
	var y_pos_difference: float = path.curve.get_point_position(current_point_id).y - path.curve.get_point_position(current_point_id + 1).y;

	var is_going_up: bool = y_pos_difference > 0
	var is_going_down: bool = y_pos_difference < 0
	var is_going_right: bool = x_pos_difference < 0
	var is_going_left: bool = x_pos_difference > 0

	if is_going_right:
		if is_going_down:
			direction = ENM_Direction.DOWN_RIGHT
		elif is_going_up:
			direction = ENM_Direction.UP_RIGHT
	elif is_going_left:
		if is_going_down:
			direction = ENM_Direction.DOWN_LEFT
		elif is_going_up:
			direction = ENM_Direction.UP_LEFT



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
			Log.trace(Log.Level.WARN, "{0}::_walk() direction does not match ENM_Direction enum".format([name]))


func _disappear() -> void:
	if is_already_dead: return
	die.emit()
	AnimPlayer.play(ANIM_FADE_OUT)
	is_already_dead = true


func _dead_state() -> void:
	if ILevel.current_level == null:
		Log.trace(Log.Level.ERROR, "Current level is null, aborting.")
		return
	var money_reward: int = 10
	ILevel.current_level.coins += money_reward
	PopupScoreSpawner.score("+%s$" % [int(money_reward)])
	_disappear()
	# disable the collision shape
	CollisionShape.set_deferred("disabled", true)


func _give_damage_state() -> void:
	# when the enemy arrives at the end of the Path
	_disappear()
	if ILevel.current_level == null:
		Log.trace(Log.Level.ERROR, "Current level is null, aborting.")
		return

	# if boss insta death
	if type == ENM_Type.BIG_DADDY or type == ENM_Type.FAT:
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


func _on_animation_player_animation_finished(anim_name: String) -> void:
	if anim_name == ANIM_FADE_OUT:
		queue_free()
		get_parent().queue_free()
