## © [2024] A7 Studio. All rights reserved. Trademark.
##
## Base class for all enemy entities in the game.
## Handles enemy movement, health, damage, and state management.
class_name IEnemy
extends CharacterBody2D

## Emitted when the enemy dies
signal die
## Emitted to trigger camera effects
## [param effect] The name of the effect to trigger
signal camera_effect(effect: String)


# Enums
## Possible states for the enemy
enum EnemyState {
	DEAD,  ## Enemy is dead
	FOLLOW_PATH,  ## Enemy is following a path
	PATH_FINISHED,  ## Enemy reached the end of its path
}

## Movement directions for the enemy
enum EnemyDirection {
	DOWN_LEFT,
	DOWN_RIGHT,
	UP_LEFT,
	UP_RIGHT,
}

## Types of enemies available
enum EnemyType {
	BIG_DADDY,
	DEFAULT,
	FAT,
	RAT
}

## Types of damage that can be applied
enum DamageType {
	DEFAULT,
	POISON,
	FIRE,
}


# Constants
const ANIM_FADE_OUT := "fade_out"
const ANIM_WALK_UP := "walk_up"
const ANIM_WALK_DOWN := "walk_down"

## Damage configuration for different damage types
const DAMAGES: Dictionary = {
	DamageType.DEFAULT: {"color": Color(1.0, 1.0, 1.0, 1)}, # White for better visibility
	DamageType.POISON: {"color": Color(0.4, 1.0, 0.4, 1)}, # Brighter green
	DamageType.FIRE: {"color": Color(1.0, 0.6, 0.2, 1)},   # Brighter orange/fire
}


# Exported variables
@export var enemy_id: String = ""
@export var type: EnemyType = EnemyType.DEFAULT

# Public variables
var active_poison_timers: Array[Dictionary] = []
var current_animation: String = ""
var direction: EnemyDirection = EnemyDirection.UP_RIGHT
var health: float
var is_already_dead: bool = false
var last_damage_type: DamageType = DamageType.DEFAULT
var max_health: float = 0.0
var path: Path2D = null
var path_follow: PathFollow2D = null
var poison_timer_execution_count: int = 0
var previous_position: Vector2 = Vector2.ZERO
var speed: float = 0.0
var state: EnemyState = EnemyState.FOLLOW_PATH

## Must be placed first as it is used in other onready variables
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var health_bar: EnemyHealthBar = $HealthBar
@onready var old_modulate: Color = sprite.modulate
@onready var path_points_size: int = path.curve.point_count
@onready var poison_particle: GPUParticles2D = $GPUParticles2D
@onready var popup_score_spawner: PopupSpawner = $PopupScoreSpawner
@onready var stats_db = get_node("/root/StatsDB")

## Store the last source of damage
var last_source: Variant = null


# Built-in functions
func _ready() -> void:
	add_to_group("enemies")
	_apply_stats_override()
	if type == EnemyType.FAT or type == EnemyType.BIG_DADDY:
		camera_effect.connect(Global.camera.handle_effect)
		camera_effect.emit('shake')

	health = max_health

	# Wait one frame to ensure PathFollow2D is properly positioned
	await get_tree().process_frame

	# Initialize previous position and direction correctly
	previous_position = path_follow.global_position

	# Force initial animation to match direction
	_walk()


func _physics_process(delta: float) -> void:
	if is_already_dead or Global.paused:
		return

	_update_z_index()

	match state:
		EnemyState.FOLLOW_PATH:
			follow_path(delta)
		EnemyState.DEAD:
			_dead_state()
		EnemyState.PATH_FINISHED:
			_path_finished_state()
		_:
			Log.trace(Log.Level.WARN, "{0} unknown EnemyState : {1}".format([name, state]))

	poison_particle.emitting = not active_poison_timers.is_empty()


# Public functions
## Apply damage to the enemy
## [br]
## [param damage] Amount of damage to apply
## [param damage_type] Type of damage being applied
func take_damage(damage: float, damage_type: DamageType, source: Variant = null) -> void:
	if is_already_dead:
		return

	last_damage_type = damage_type
	last_source = source
	_damage_effect(DAMAGES[damage_type]["color"])
	
	if popup_score_spawner:
		popup_score_spawner.display_damage(damage, DAMAGES[damage_type]["color"])

	if source:
		ChallengeManager.notify_enemy_hit(self, source)

	if health - damage <= 0:
		health = 0.0
		state = EnemyState.DEAD
	else:
		health -= damage

	if health_bar:
		health_bar.update_health(health, max_health)


## Update enemy position along its path
## [br]
## [param delta] Time since last frame
func follow_path(delta: float) -> void:
	if path_follow.get_progress_ratio() >= 1.0:
		state = EnemyState.PATH_FINISHED
		return

	path_follow.set_progress(path_follow.get_progress() + (speed * delta))

	# Always update direction, regardless of path position
	_update_direction()
	_walk()


## Add a poison effect to the enemy
## [br]
## [param damage] Damage per tick
## [param total_execution] Number of times to apply damage
## [param interval] Time between damage ticks
func add_poison_effect(damage: float, total_execution: int, interval: float) -> void:
	var poison_timer := Timer.new()
	add_child(poison_timer)
	poison_timer.set_wait_time(interval)
	poison_timer.set_one_shot(false)
	poison_timer.start()

	active_poison_timers.append({
		"timer": poison_timer,
		"damage": damage,
		"total_execution": total_execution,
		"interval": interval,
		"current_execution": 0
	})

	poison_timer.timeout.connect(func(): _on_poison_timer_timeout(poison_timer))


# Private functions
## Apply a damage effect to the enemy sprite
func _damage_effect(color: Color) -> void:
	sprite.modulate = color
	await get_tree().create_timer(0.1).timeout
	sprite.modulate = old_modulate

## Update the direction of the enemy based on movement
func _update_direction() -> void:
	var current_pos: Vector2 = path_follow.global_position
	var movement: Vector2 = current_pos - previous_position

	# Check actual movement with low threshold
	if movement.length() > 0.1:
		_determine_direction_from_movement(movement)

	# Look ahead on path when near the end
	elif path_follow.get_progress_ratio() > 0.85:
		_check_direction_ahead()

	# Store current position for next frame
	previous_position = current_pos

## Determine direction based on movement vector
func _determine_direction_from_movement(movement: Vector2) -> void:
	# Use angle-based direction detection for precision
	var angle: float = movement.angle()

	# Convert angle to direction
	if angle >= -PI/8 and angle < PI/8:  # Right
		direction = EnemyDirection.UP_RIGHT
	elif angle >= PI/8 and angle < 3*PI/8:  # Down-right
		direction = EnemyDirection.DOWN_RIGHT
	elif angle >= 3*PI/8 and angle < 5*PI/8:  # Down
		direction = EnemyDirection.DOWN_RIGHT
	elif angle >= 5*PI/8 and angle < 7*PI/8:  # Down-left
		direction = EnemyDirection.DOWN_LEFT
	elif angle >= 7*PI/8 or angle < -7*PI/8:  # Left
		direction = EnemyDirection.UP_LEFT
	elif angle >= -7*PI/8 and angle < -5*PI/8:  # Up-left
		direction = EnemyDirection.UP_LEFT
	elif angle >= -5*PI/8 and angle < -3*PI/8:  # Up
		direction = EnemyDirection.UP_RIGHT
	elif angle >= -3*PI/8 and angle < -PI/8:  # Up-right
		direction = EnemyDirection.UP_RIGHT

## Look ahead on the path to detect upcoming direction changes
func _check_direction_ahead() -> void:
	var current_progress := path_follow.get_progress()
	var look_ahead_distance := 15.0

	# Look ahead on path
	var original_progress := path_follow.get_progress()
	path_follow.set_progress(current_progress + look_ahead_distance)
	var ahead_pos := path_follow.global_position
	path_follow.set_progress(original_progress)

	var look_ahead_movement := ahead_pos - path_follow.global_position

	if look_ahead_movement.length() > 1.0:
		_determine_direction_from_movement(look_ahead_movement)

## Update the enemy sprite animation based on the direction
func _walk() -> void:
	var target_animation: String
	var should_flip: bool

	match direction:
		EnemyDirection.UP_RIGHT:
			target_animation = ANIM_WALK_UP
			should_flip = true
		EnemyDirection.UP_LEFT:
			target_animation = ANIM_WALK_UP
			should_flip = false
		EnemyDirection.DOWN_RIGHT:
			target_animation = ANIM_WALK_DOWN
			should_flip = true
		EnemyDirection.DOWN_LEFT:
			target_animation = ANIM_WALK_DOWN
			should_flip = false
		_:
			Log.trace(Log.Level.WARN, "{0}::_walk() direction does not match EnemyDirection enum".format([name]))
			return

	# Only change animation if it's different from current one to prevent stuttering
	if current_animation != target_animation:
		sprite.play(target_animation)
		current_animation = target_animation

	# Only change flip if necessary to prevent stuttering
	if sprite.flip_h != should_flip:
		sprite.flip_h = should_flip

## Make the enemy disappear, then remove it from the scene
func _disappear() -> void:
	if is_already_dead:
		return

	die.emit()
	ChallengeManager.notify_enemy_died(self, last_damage_type)
	# anim_player.play(ANIM_FADE_OUT)  # Remove the comment when the animation is implemented
	is_already_dead = true
	collision_shape.set_deferred("disabled", true)

	# await anim_player.animation_finished # Remove the comment when the animation is implemented
	queue_free()
	path_follow.queue_free()

## Handle the enemy's death state
func _dead_state() -> void:
	if ILevel.current_level == null:
		Log.trace(Log.Level.ERROR, "Current level is null, aborting.")
		return

	var money_reward: int = 10
	
	# Apply reward multiplier if the killer was a tower
	if last_source is IBullet and last_source.tower_owner != null:
		money_reward = int(money_reward * last_source.tower_owner.reward_multiplier)
		
	ILevel.current_level.coins += money_reward
	_disappear()

## Handle the enemy reaching the end of its path
func _path_finished_state() -> void:
	_disappear()
	if ILevel.current_level == null:
		Log.trace(Log.Level.ERROR, "Current level is null, aborting.")
		return

	if type == EnemyType.BIG_DADDY or type == EnemyType.FAT:
		ILevel.current_level.health = 0
	else:
		ILevel.current_level.health -= ceil(health / 2)


func _apply_stats_override() -> void:
	if enemy_id.is_empty() or stats_db == null:
		return
	if not stats_db.has_enemy(enemy_id):
		Log.trace(Log.Level.ERROR, "StatsDB missing enemy id: %s" % enemy_id)
		return
	var data: Dictionary = stats_db.get_enemy(enemy_id)
	Log.trace(Log.Level.INFO, "Applying enemy stats from StatsDB for %s: %s" % [enemy_id, data])
	var hp = data.get("max_health", null)
	var spd = data.get("speed", null)
	if hp != null:
		max_health = float(hp)
	if spd != null:
		speed = float(spd)

## Update the z-index of the enemy based on its position
func _update_z_index() -> void:
	var y_position: int = int(global_position.y)
	z_index = y_position if y_position else 0

## Handle the poison effect timer
func _on_poison_timer_timeout(timer: Timer) -> void:
	var timer_index: int = -1
	for i in range(active_poison_timers.size()):
		if active_poison_timers[i]["timer"] == timer:
			timer_index = i
			break

	active_poison_timers[timer_index]["current_execution"] += 1

	var highest_timer_ratio: float = 0.0
	var highest_timer_index: int = 0
	var _highest_timer: Timer = null

	for i in range(active_poison_timers.size()):
		var ratio: float = (active_poison_timers[i]["damage"] * active_poison_timers[i]["total_execution"]) / (active_poison_timers[i]["total_execution"] * active_poison_timers[i]["interval"])
		if ratio > highest_timer_ratio:
			highest_timer_ratio = ratio
			highest_timer_index = i
			_highest_timer = active_poison_timers[i]["timer"]

	if timer_index == highest_timer_index:
		take_damage(active_poison_timers[highest_timer_index]["damage"], DamageType.POISON)
		if active_poison_timers[highest_timer_index]["current_execution"] >= active_poison_timers[highest_timer_index]["total_execution"]:
			active_poison_timers.remove_at(timer_index)
			timer.stop()
			timer.queue_free()
		else:
			timer.start()
