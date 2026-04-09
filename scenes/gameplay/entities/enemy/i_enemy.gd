## © [2026] A7 Studio. All rights reserved. Trademark.
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
	STUN,
}


# Constants
const ANIM_FADE_OUT := "fade_out"
const ANIM_WALK_UP := "walk_up"
const ANIM_WALK_DOWN := "walk_down"

## Damage configuration for different damage types
const DAMAGES: Dictionary = {
	DamageType.DEFAULT: {"color": Color(1.0, 1.0, 1.0, 1)}, # White for better visibility
	DamageType.POISON: {"color": Color("#744187")}, # Custom purple for poison
	DamageType.FIRE: {"color": Color(1.0, 0.6, 0.2, 1)},   # Brighter orange/fire
	DamageType.STUN: {"color": Color(1.0, 1.0, 0.0, 1)},   # Yellow for stun
}

## Multiplied with [member old_modulate] while slowed; matches slow-trap cyan/teal feel (slightly darker, bluish).
const SLOW_VISUAL_TINT: Color = Color(0.58, 0.78, 0.86, 1.0)

## Multiplied with [member old_modulate] while poisoned; purple feel.
const POISON_VISUAL_TINT: Color = Color(0.85, 0.75, 0.9, 1.0)

## Multiplied with [member old_modulate] while stunned; yellow feel.
const STUN_VISUAL_TINT: Color = Color(1.0, 1.0, 0.6, 1.0)

## Multiplied with [member old_modulate] while being hit by Inferno Tower; red/orange feel.
const INFERNO_VISUAL_TINT: Color = Color(1.0, 0.7, 0.7, 1.0)

## Stun star texture cached for performance.
const STUN_STAR_TEX := preload("res://assets/gameplay/enemies/Stunned_Star.png")


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

## Whether the enemy is currently stunned
var is_stunned: bool = false

## Array to store stun stars visual nodes
var _stun_stars: Array[Sprite2D] = []

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

var _damage_tween: Tween

## Stacked slow visuals (traps, debuffs); each source must pair pop with push.
var _slow_visual_refcount: int = 0
## Stacked inferno visuals; each beam must pair pop with push.
var _inferno_visual_refcount: int = 0
var _electrified: bool = false
var _electrify_base_speed: float = 0.0
var _electrify_speed_factor: float = 1.0
var _electrify_remaining: float = 0.0
var _electrify_tick_damage: float = 0.0
var _electrify_tick_interval: float = 0.0
var _electrify_tick_remaining: float = 0.0


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

	_process_electrify(delta)
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
	poison_particle.visible = poison_particle.emitting
	
	if is_stunned:
		_update_stun_stars(delta)


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
	if is_stunned:
		_process_stun_shake()
		return

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
	_apply_idle_modulate() # Apply violet tint immediately


## Removes one stacked slow visual tint (e.g. leaving a slow zone).
func pop_slow_visual() -> void:
	_slow_visual_refcount = maxi(0, _slow_visual_refcount - 1)
	_apply_idle_modulate()


## Adds one stacked slow visual tint (e.g. entering a slow zone).
func push_slow_visual() -> void:
	_slow_visual_refcount += 1
	_apply_idle_modulate()


## Removes one stacked inferno visual tint.
func pop_inferno_visual() -> void:
	_inferno_visual_refcount = maxi(0, _inferno_visual_refcount - 1)
	_apply_idle_modulate()


## Adds one stacked inferno visual tint.
func push_inferno_visual() -> void:
	_inferno_visual_refcount += 1
	_apply_idle_modulate()

## Returns true while enemy is under electrified effect.
func is_electrified() -> bool:
	return _electrified

## Applies an electrified debuff: temporary slow + periodic electric damage.
func apply_electrify_effect(duration: float, slow_amount: float, tick_damage: float, tick_interval: float, _source: Variant = null) -> void:
	if duration <= 0.0:
		return

	var normalized_slow: float = clampf(slow_amount, 0.0, 0.95)
	var normalized_interval: float = maxf(0.05, tick_interval)

	if not _electrified:
		_electrified = true
		_electrify_base_speed = speed
		_electrify_speed_factor = (1.0 - normalized_slow)
		speed = _electrify_base_speed * _electrify_speed_factor
		push_slow_visual()
	else:
		# Keep the strongest slow when effect is refreshed.
		var refreshed_factor: float = (1.0 - normalized_slow)
		if refreshed_factor < _electrify_speed_factor:
			_electrify_speed_factor = refreshed_factor
			speed = _electrify_base_speed * _electrify_speed_factor

	_electrify_remaining = maxf(_electrify_remaining, duration)
	_electrify_tick_damage = maxf(_electrify_tick_damage, tick_damage)
	_electrify_tick_interval = normalized_interval
	_electrify_tick_remaining = minf(_electrify_tick_remaining if _electrify_tick_remaining > 0.0 else normalized_interval, normalized_interval)


## Applies a stun effect to the enemy.
## [param duration] How long the stun lasts in seconds.
func stun(duration: float) -> void:
	if is_already_dead or is_stunned:
		return
	
	is_stunned = true
	sprite.pause() # Freeze the walking animation
	_create_stun_stars()
	_apply_idle_modulate() # Apply yellow tint immediately
	_damage_effect(DAMAGES[DamageType.STUN]["color"])
	
	var timer := get_tree().create_timer(duration)
	timer.timeout.connect(func() -> void:
		# Fade out stars
		var fade_tween := create_tween()
		fade_tween.set_parallel(true)
		for star in _stun_stars:
			if is_instance_valid(star):
				fade_tween.tween_property(star, "modulate:a", 0.0, 0.5)
		
		# Wait for the stars fade to finish
		# to set is_stunned to false, which will refresh the modulate
		fade_tween.finished.connect(func() -> void:
			is_stunned = false
			sprite.play() # Resume the walking animation
			_remove_stun_stars()
			sprite.offset = Vector2.ZERO
			_apply_idle_modulate()
		)
	)


# Private functions
func _process_electrify(delta: float) -> void:
	if not _electrified:
		return

	_electrify_remaining -= delta
	_electrify_tick_remaining -= delta

	if _electrify_tick_remaining <= 0.0 and _electrify_tick_damage > 0.0:
		take_damage(_electrify_tick_damage, DamageType.DEFAULT)
		_electrify_tick_remaining = _electrify_tick_interval

	if _electrify_remaining <= 0.0:
		_clear_electrify_effect()

func _clear_electrify_effect() -> void:
	if not _electrified:
		return

	_electrified = false
	speed = _electrify_base_speed
	_electrify_base_speed = 0.0
	_electrify_speed_factor = 1.0
	_electrify_remaining = 0.0
	_electrify_tick_damage = 0.0
	_electrify_tick_interval = 0.0
	_electrify_tick_remaining = 0.0
	pop_slow_visual()

func _apply_idle_modulate() -> void:
	sprite.modulate = _idle_modulate()


func _create_stun_stars() -> void:
	_remove_stun_stars() # Safety
	for i in range(3):
		var star := Sprite2D.new()
		star.texture = STUN_STAR_TEX
		star.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		add_child(star)
		_stun_stars.append(star)


func _remove_stun_stars() -> void:
	for star in _stun_stars:
		if is_instance_valid(star):
			star.queue_free()
	_stun_stars.clear()


func _update_stun_stars(delta: float) -> void:
	if _stun_stars.is_empty():
		return
	
	var time := Time.get_ticks_msec() / 1000.0
	var radius_x := 15.0
	var radius_y := 5.0 # Isometric perspective
	var center_offset := Vector2(0, -30) # Above head
	
	for i in range(_stun_stars.size()):
		var angle := time * 5.0 + (i * PI * 2.0 / 3.0)
		_stun_stars[i].position = center_offset + Vector2(
			cos(angle) * radius_x,
			sin(angle) * radius_y
		)
		# Small scale effect to simulate depth
		# We use a base scale of 0.30 as requested
		var base_s := 0.30
		var s := base_s * (0.7 + (sin(angle) + 1.0) * 0.15)
		_stun_stars[i].scale = Vector2(s, s)
		# Z-index adjustment based on position in orbit
		_stun_stars[i].z_index = z_index + (1 if sin(angle) > 0 else -1)


func _process_stun_shake() -> void:
	if not is_stunned:
		return
	var shake_offset := 1.0
	sprite.offset = Vector2(
		randf_range(-shake_offset, shake_offset),
		randf_range(-shake_offset, shake_offset)
	)


## Sprite color when not flashing damage; includes slow tint when slow stacks are active.
func _idle_modulate() -> Color:
	var tint: Color = old_modulate
	if _slow_visual_refcount > 0:
		tint *= SLOW_VISUAL_TINT
	if not active_poison_timers.is_empty():
		tint *= POISON_VISUAL_TINT
	if is_stunned:
		tint *= STUN_VISUAL_TINT
	if _inferno_visual_refcount > 0:
		tint *= INFERNO_VISUAL_TINT
	return tint


## Apply a damage effect to the enemy sprite
func _damage_effect(color: Color) -> void:
	if last_source is ITower and last_source.tower_id == "bat_09":
		# Effet réduit pour l'Inferno Tower
		sprite.modulate = color.lerp(old_modulate, 0.7)
		await get_tree().create_timer(0.05).timeout
		sprite.modulate = _idle_modulate()
		return

	sprite.modulate = color
	await get_tree().create_timer(0.1).timeout
	sprite.modulate = _idle_modulate()
	if not is_instance_valid(sprite) or not is_inside_tree():
		return

	if _damage_tween:
		_damage_tween.kill()

	_damage_tween = create_tween()
	
	# Flash color: white/glowing white or colored based on damage type
	var flash_color = Color(2.5, 2.5, 2.5, 1.0)
	if color != Color.WHITE and color != Color(1, 1, 1, 1):
		flash_color = color.lightened(0.5)
		flash_color.a = 1.0

	# Apply initial state immediately
	sprite.modulate = flash_color
	sprite.offset.x = 4.0
	
	# Wait a tiny bit then tween back
	_damage_tween.tween_interval(0.04)
	_damage_tween.set_parallel(true)
	_damage_tween.tween_property(sprite, "modulate", _idle_modulate(), 0.15)
	_damage_tween.tween_property(sprite, "offset:x", 0.0, 0.15).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

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

	# Apply reward multiplier when the killing [IBullet] was fired by a tower ([member IBullet.tower_owner]).
	# [code]last_source[/code] may already be freed (bullet [method queue_free] after hit) — check validity before [code]is[/code].
	if is_instance_valid(last_source) and last_source is IBullet:
		var killing_bullet: IBullet = last_source
		var owner_tower: ITower = killing_bullet.tower_owner
		if is_instance_valid(owner_tower):
			money_reward = int(money_reward * owner_tower.reward_multiplier)

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
		ILevel.current_level.health -= 5


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
			_apply_idle_modulate() # Refresh visual tint when a poison timer ends
		else:
			timer.start()
