## © [2026] A7 Studio. All rights reserved. Trademark.
##
## Base class for all enemy entities in the game.
## Handles enemy movement, health, damage, and state management.
class_name IEnemy
extends CharacterBody2D

## Emitted when the enemy dies, after the reward and the challenge notification
signal died
## Emitted when the enemy reaches the end of its path alive
signal escaped


# Enums
## Types of damage that can be applied
enum DamageType {
	DEFAULT,
	POISON,
	FIRE,
	STUN,
}

## Movement directions for the enemy
enum EnemyDirection {
	DOWN_LEFT,
	DOWN_RIGHT,
	UP_LEFT,
	UP_RIGHT,
}

## Possible states for the enemy
enum EnemyState {
	DEAD,  ## Enemy is dead
	FOLLOW_PATH,  ## Enemy is following a path
	PATH_FINISHED,  ## Enemy reached the end of its path
}

## Types of enemies available, the values are stored in scenes and must stay stable
enum EnemyType {
	BIG_DADDY = 0,
	DEFAULT = 1,
	RAT = 3,
}


# Constants
const ANIM_FADE_OUT := "fade_out"
const ANIM_WALK_DOWN := "walk_down"
const ANIM_WALK_UP := "walk_up"

## Flash and popup color of each damage type
const DAMAGE_COLORS: Dictionary[DamageType, Color] = {
	DamageType.DEFAULT: Color(1.0, 1.0, 1.0, 1), # White for better visibility
	DamageType.POISON: Color("#744187"), # Custom purple for poison
	DamageType.FIRE: Color(1.0, 0.6, 0.2, 1), # Brighter orange/fire
	DamageType.STUN: Color(1.0, 1.0, 0.0, 1), # Yellow for stun
}

## Multiplied with [member old_modulate] while being hit by Inferno Tower; red/orange feel.
const INFERNO_VISUAL_TINT: Color = Color(1.0, 0.7, 0.7, 1.0)

## Distance probed ahead on the path to anticipate direction changes.
const LOOK_AHEAD_DISTANCE: float = 15.0

## Walk direction for each 45 degree sector of the movement angle, starting at 0 (right) and turning clockwise on screen.
const OCTANT_DIRECTIONS: Array[EnemyDirection] = [
	EnemyDirection.UP_RIGHT,
	EnemyDirection.DOWN_RIGHT,
	EnemyDirection.DOWN_RIGHT,
	EnemyDirection.DOWN_LEFT,
	EnemyDirection.UP_LEFT,
	EnemyDirection.UP_LEFT,
	EnemyDirection.UP_RIGHT,
	EnemyDirection.UP_RIGHT,
]

## Multiplied with [member old_modulate] while poisoned; purple feel.
const POISON_VISUAL_TINT: Color = Color(0.85, 0.75, 0.9, 1.0)

## Multiplied with [member old_modulate] while slowed; matches slow-trap cyan/teal feel (slightly darker, bluish).
const SLOW_VISUAL_TINT: Color = Color(0.58, 0.78, 0.86, 1.0)

## Speed modifier key of the electrify effect.
const SPEED_KEY_ELECTRIFY: StringName = &"electrify"

## Stun star texture cached for performance.
const STUN_STAR_TEX := preload("res://assets/sprites/enemies/stunned_star.png")

## Multiplied with [member old_modulate] while stunned; yellow feel.
const STUN_VISUAL_TINT: Color = Color(1.0, 1.0, 0.6, 1.0)

## Visual refcount key of the Inferno Tower beam.
const VISUAL_KEY_INFERNO: StringName = &"inferno"

## Tint applied for each key pushed with [method push_visual].
const VISUAL_TINTS: Dictionary[StringName, Color] = {
	VISUAL_KEY_INFERNO: INFERNO_VISUAL_TINT,
}


## One poison stack: it deals [member damage] every [member interval] seconds for [member ticks_left] ticks.
class PoisonEffect extends RefCounted:
	var damage: float
	var interval: float
	var ticks_left: int
	## Seconds left before the next tick.
	var until_tick: float

	func _init(p_damage: float, p_ticks: int, p_interval: float) -> void:
		damage = p_damage
		interval = p_interval
		ticks_left = p_ticks
		until_tick = p_interval

	## Damage per second, used to pick the strongest stack.
	func power() -> float:
		return damage / interval


# Exported variables
@export var enemy_id: String = ""
@export var type: EnemyType = EnemyType.DEFAULT

# Public variables
## Speed without any modifier, from [StatsDB].
var base_speed: float = 0.0

var current_animation: String = ""
var direction: EnemyDirection = EnemyDirection.UP_RIGHT
## Health removed from the level when this enemy escapes, from [StatsDB].
var escape_damage: int = 0
var health: float
var is_already_dead: bool = false

## Whether the enemy is currently stunned
var is_stunned: bool = false
var last_damage_type: DamageType = DamageType.DEFAULT

## Store the last source of damage
var last_source: Variant = null
var max_health: float = 0.0
var path: Path2D = null
var path_follow: PathFollow2D = null
var previous_position: Vector2 = Vector2.ZERO
## Coins given when this enemy dies, from [StatsDB].
var reward: int = 0
## Current speed: [member base_speed] times every speed modifier.
var speed: float = 0.0
var state: EnemyState = EnemyState.FOLLOW_PATH
## Seconds a trap stays disabled when this enemy walks over it (0 for the enemies that don't defuse traps), from [StatsDB].
var trap_disable_duration: float = 0.0

# Private variables
var _damage_tween: Tween
var _electrified: bool = false
var _electrify_remaining: float = 0.0
var _electrify_source: Variant = null
var _electrify_tick_damage: float = 0.0
var _electrify_tick_interval: float = 0.0
var _electrify_tick_remaining: float = 0.0
## Tower that dealt the last damage, resolved when the damage is taken because the bullet may be freed before the death.
var _killer_tower: ITower = null
var _poisons: Array[PoisonEffect] = []
## Multiplier of each active speed effect, keyed by effect.
var _speed_modifiers: Dictionary[StringName, float] = {}
var _stun_stars: Array[Sprite2D] = []
## Stacked visual effects, each [method push_visual] must be paired with a [method pop_visual].
var _visual_counts: Dictionary[StringName, int] = {}

## Must be placed first as it is used in other onready variables
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var health_bar: EnemyHealthBar = $HealthBar
@onready var old_modulate: Color = sprite.modulate
@onready var poison_particle: GPUParticles2D = $GPUParticles2D
@onready var popup_score_spawner: PopupSpawner = $PopupScoreSpawner


# Built-in functions
func _ready() -> void:
	assert(path != null, "IEnemy.path must be assigned before the enemy enters the tree")
	add_to_group("enemies")
	_apply_stats_override()
	poison_particle.emitting = false
	poison_particle.visible = false
	if type == EnemyType.BIG_DADDY and is_instance_valid(Global.camera):
		Global.camera.handle_effect("shake")

	health = max_health

	# Wait one frame to ensure PathFollow2D is properly positioned
	await get_tree().process_frame
	if not is_inside_tree():
		return

	# Initialize previous position and direction correctly
	previous_position = path_follow.global_position

	# Force initial animation to match direction
	_walk()


func _physics_process(delta: float) -> void:
	if is_already_dead or Global.paused:
		return

	_process_electrify(delta)
	_process_poisons(delta)
	_update_z_index()

	match state:
		EnemyState.FOLLOW_PATH:
			follow_path(delta)
		EnemyState.DEAD:
			_dead_state()
		EnemyState.PATH_FINISHED:
			_path_finished_state()

	if is_stunned:
		_update_stun_stars()


# Public functions
## Add a poison effect to the enemy
## [br]
## [param damage] Damage per tick
## [param total_execution] Number of times to apply damage
## [param interval] Time between damage ticks
func add_poison_effect(damage: float, total_execution: int, interval: float) -> void:
	_poisons.append(PoisonEffect.new(damage, total_execution, maxf(interval, 0.05)))
	_refresh_poison_visual()


## Applies an electrified debuff: temporary slow + periodic electric damage.
func apply_electrify_effect(duration: float, slow_amount: float, tick_damage: float, tick_interval: float, source: Variant = null) -> void:
	if duration <= 0.0:
		return

	var normalized_slow: float = clampf(slow_amount, 0.0, 0.95)
	var normalized_interval: float = maxf(0.05, tick_interval)
	var multiplier: float = 1.0 - normalized_slow

	_electrified = true
	# Keep the strongest slow when the effect is refreshed.
	if multiplier < _speed_modifiers.get(SPEED_KEY_ELECTRIFY, INF):
		set_speed_modifier(SPEED_KEY_ELECTRIFY, multiplier)

	_electrify_remaining = maxf(_electrify_remaining, duration)
	_electrify_tick_damage = maxf(_electrify_tick_damage, tick_damage)
	_electrify_tick_interval = normalized_interval
	_electrify_tick_remaining = minf(_electrify_tick_remaining if _electrify_tick_remaining > 0.0 else normalized_interval, normalized_interval)
	_electrify_source = source


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


## Returns true while enemy is under electrified effect.
func is_electrified() -> bool:
	return _electrified


## Removes one stacked visual effect, see [method push_visual].
func pop_visual(key: StringName) -> void:
	var count: int = _visual_counts.get(key, 0) - 1
	if count > 0:
		_visual_counts[key] = count
	else:
		_visual_counts.erase(key)
	_apply_idle_modulate()


## Adds one stacked visual effect, see [constant VISUAL_TINTS] for the keys that tint the sprite.
func push_visual(key: StringName) -> void:
	_visual_counts[key] = _visual_counts.get(key, 0) + 1
	_apply_idle_modulate()


## Removes the speed modifier of [param key] and restores the speed it was lowering.
func remove_speed_modifier(key: StringName) -> void:
	if _speed_modifiers.erase(key):
		_on_speed_modifiers_changed()


## Sets the speed multiplier of [param key], replacing the previous one of the same key.
## [br]The speed is [member base_speed] times every multiplier, so effects of different keys stack and restore the base speed once all are removed.
func set_speed_modifier(key: StringName, multiplier: float) -> void:
	_speed_modifiers[key] = multiplier
	_on_speed_modifiers_changed()


## Applies a stun effect to the enemy.
## [param duration] How long the stun lasts in seconds.
func stun(duration: float) -> void:
	if is_already_dead or is_stunned:
		return

	is_stunned = true
	sprite.pause() # Freeze the walking animation
	_create_stun_stars()
	_apply_idle_modulate() # Apply yellow tint immediately
	_damage_effect(DAMAGE_COLORS[DamageType.STUN])

	var stun_tween: Tween = create_tween()
	stun_tween.tween_interval(duration)
	stun_tween.tween_callback(_begin_stun_fade)


## Apply damage to the enemy
## [br]
## [param damage] Amount of damage to apply
## [param damage_type] Type of damage being applied
## [param source] What dealt the damage: a bullet, a tower or a trap
func take_damage(damage: float, damage_type: DamageType, source: Variant = null) -> void:
	if is_already_dead:
		return

	last_damage_type = damage_type
	last_source = source
	_killer_tower = _resolve_source_tower(source)
	var damage_color: Color = DAMAGE_COLORS[damage_type]
	_damage_effect(damage_color)

	if popup_score_spawner:
		popup_score_spawner.display_damage(damage, damage_color, _killer_tower)

	if source:
		ChallengeManager.notify_enemy_hit(self, source)

	if health - damage <= 0:
		health = 0.0
		state = EnemyState.DEAD
	else:
		health -= damage

	if health_bar:
		health_bar.update_health(health, max_health)


# Private functions
func _apply_idle_modulate() -> void:
	if is_node_ready():
		sprite.modulate = _idle_modulate()


func _apply_stats_override() -> void:
	if enemy_id.is_empty():
		return
	if not StatsDB.has_enemy(enemy_id):
		Log.trace(Log.Level.ERROR, "StatsDB missing enemy id: %s" % enemy_id)
		return
	var data: Dictionary = StatsDB.get_enemy(enemy_id)
	if data.has("max_health"):
		max_health = float(data["max_health"])
	if data.has("speed"):
		base_speed = float(data["speed"])
		_recompute_speed()
	reward = int(data.get("reward", 0))
	escape_damage = int(data.get("escape_damage", 0))
	# The extra keys write the properties of the same name, declared by the enemy scripts that need them
	StatsDB.apply_fields(self, data.get("extra", {}))


func _begin_stun_fade() -> void:
	var fade_tween: Tween = create_tween()
	fade_tween.set_parallel(true)
	for star: Sprite2D in _stun_stars:
		fade_tween.tween_property(star, "modulate:a", 0.0, 0.5)

	# Once the stars are faded, is_stunned becomes false and the modulate is refreshed
	fade_tween.chain().tween_callback(_end_stun)


func _check_direction_ahead() -> void:
	var curve: Curve2D = path.curve
	var progress: float = path_follow.get_progress()
	var ahead: Vector2 = curve.sample_baked(progress + LOOK_AHEAD_DISTANCE) - curve.sample_baked(progress)
	var look_ahead_movement: Vector2 = path.global_transform.basis_xform(ahead)

	if look_ahead_movement.length() > 1.0:
		_determine_direction_from_movement(look_ahead_movement)


func _clear_electrify_effect() -> void:
	if not _electrified:
		return

	_electrified = false
	_electrify_remaining = 0.0
	_electrify_tick_damage = 0.0
	_electrify_tick_interval = 0.0
	_electrify_tick_remaining = 0.0
	_electrify_source = null
	remove_speed_modifier(SPEED_KEY_ELECTRIFY)


func _create_stun_stars() -> void:
	_remove_stun_stars() # Safety
	for i in range(3):
		var star := Sprite2D.new()
		star.texture = STUN_STAR_TEX
		star.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		add_child(star)
		_stun_stars.append(star)


## Apply a damage effect to the enemy sprite: [param color] right away, then a bright flash that fades back to the idle color.
func _damage_effect(color: Color) -> void:
	if _damage_tween:
		_damage_tween.kill()
	_damage_tween = create_tween()

	if is_instance_valid(last_source) and last_source is ITower and last_source.use_short_damage_flash:
		# Reduced effect for specific towers (e.g. Inferno Tower)
		sprite.modulate = color.lerp(old_modulate, 0.7)
		_damage_tween.tween_interval(0.05)
		_damage_tween.tween_callback(_apply_idle_modulate)
		return

	# Flash color: white/glowing white or colored based on damage type
	var flash_color: Color = Color(2.5, 2.5, 2.5, 1.0)
	if color != Color.WHITE:
		flash_color = color.lightened(0.5)
		flash_color.a = 1.0

	sprite.modulate = color
	_damage_tween.tween_interval(0.1)
	_damage_tween.tween_callback(_flash.bind(flash_color))
	_damage_tween.tween_interval(0.04)
	_damage_tween.tween_property(sprite, "modulate", _idle_modulate(), 0.15)
	_damage_tween.parallel().tween_property(sprite, "offset:x", 0.0, 0.15).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	_damage_tween.tween_callback(_apply_idle_modulate)


## Handle the enemy's death state
func _dead_state() -> void:
	var money_reward: int = reward
	var killer: Variant = last_source if is_instance_valid(last_source) else null

	# Apply the reward multiplier of the tower that dealt the killing damage
	if is_instance_valid(_killer_tower):
		money_reward = int(reward * _killer_tower.reward_multiplier)
		killer = _killer_tower

	if is_instance_valid(ILevel.current_level):
		ILevel.current_level.coins += money_reward
	else:
		Log.trace(Log.Level.WARN, "%s died without an active level, no reward given." % name)

	ChallengeManager.notify_enemy_died(self, last_damage_type, killer)
	died.emit()
	_remove_from_play()


## Determine direction based on movement vector
func _determine_direction_from_movement(movement: Vector2) -> void:
	var octant: int = posmod(floori(movement.angle() / (PI / 4.0) + 0.5), 8)
	direction = OCTANT_DIRECTIONS[octant]


func _end_stun() -> void:
	is_stunned = false
	sprite.play() # Resume the walking animation
	_remove_stun_stars()
	sprite.offset = Vector2.ZERO
	_apply_idle_modulate()


func _flash(color: Color) -> void:
	sprite.modulate = color
	sprite.offset.x = 4.0


## Sprite color when not flashing damage; includes the slow, poison, stun and pushed visual tints.
func _idle_modulate() -> Color:
	var tint: Color = old_modulate
	for multiplier: float in _speed_modifiers.values():
		if multiplier < 1.0:
			tint *= SLOW_VISUAL_TINT
			break
	if not _poisons.is_empty():
		tint *= POISON_VISUAL_TINT
	if is_stunned:
		tint *= STUN_VISUAL_TINT
	for key: StringName in _visual_counts:
		var visual_tint: Color = VISUAL_TINTS.get(key, Color.WHITE)
		tint *= visual_tint
	return tint


func _on_speed_modifiers_changed() -> void:
	_recompute_speed()
	_apply_idle_modulate()


## Handle the enemy reaching the end of its path
func _path_finished_state() -> void:
	ChallengeManager.notify_enemy_escaped(self)
	escaped.emit()

	if is_instance_valid(ILevel.current_level):
		if type == EnemyType.BIG_DADDY:
			# A boss escaping is an instant defeat.
			ILevel.current_level.health = 0
		else:
			ILevel.current_level.health -= escape_damage
	else:
		Log.trace(Log.Level.WARN, "%s escaped without an active level." % name)

	_remove_from_play()


func _process_electrify(delta: float) -> void:
	if not _electrified:
		return

	_electrify_remaining -= delta
	_electrify_tick_remaining -= delta

	if _electrify_tick_remaining <= 0.0 and _electrify_tick_damage > 0.0:
		take_damage(_electrify_tick_damage, DamageType.DEFAULT, _electrify_source)
		_electrify_tick_remaining = _electrify_tick_interval

	if _electrify_remaining <= 0.0:
		_clear_electrify_effect()


## Advances every poison stack. Only the strongest stack deals damage on its ticks, but all of them count down and expire.
func _process_poisons(delta: float) -> void:
	if _poisons.is_empty():
		return

	var strongest: PoisonEffect = _poisons[0]
	for effect: PoisonEffect in _poisons:
		if effect.power() > strongest.power():
			strongest = effect

	var expired: Array[PoisonEffect] = []
	for effect: PoisonEffect in _poisons:
		effect.until_tick -= delta
		if effect.until_tick > 0.0:
			continue

		effect.until_tick += effect.interval
		effect.ticks_left -= 1
		if effect == strongest:
			take_damage(effect.damage, DamageType.POISON)
		if effect.ticks_left <= 0:
			expired.append(effect)

	if expired.is_empty():
		return

	for effect: PoisonEffect in expired:
		_poisons.erase(effect)
	_refresh_poison_visual()


func _process_stun_shake() -> void:
	if not is_stunned:
		return
	var shake_offset := 1.0
	sprite.offset = Vector2(
		randf_range(-shake_offset, shake_offset),
		randf_range(-shake_offset, shake_offset)
	)


func _recompute_speed() -> void:
	var multiplier: float = 1.0
	for value: float in _speed_modifiers.values():
		multiplier *= value
	speed = maxf(0.0, base_speed * multiplier)


func _refresh_poison_visual() -> void:
	var poisoned: bool = not _poisons.is_empty()
	poison_particle.emitting = poisoned
	poison_particle.visible = poisoned
	_apply_idle_modulate()


## Takes the enemy out of the game, the [PathFollow2D] parent frees the enemy with it.
func _remove_from_play() -> void:
	if is_already_dead:
		return

	is_already_dead = true
	collision_shape.set_deferred("disabled", true)
	if is_instance_valid(path_follow):
		path_follow.queue_free()
	else:
		queue_free()


func _remove_stun_stars() -> void:
	for star in _stun_stars:
		if is_instance_valid(star):
			star.queue_free()
	_stun_stars.clear()


## Returns the tower behind [param source]: the owner of a bullet, the tower itself, or null for traps and other sources.
func _resolve_source_tower(source: Variant) -> ITower:
	if not is_instance_valid(source):
		return null
	if source is IBullet:
		return (source as IBullet).tower_owner
	if source is ITower:
		return source as ITower
	return null


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


func _update_stun_stars() -> void:
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


## Update the z-index of the enemy based on its position, only written when the pixel row changes
func _update_z_index() -> void:
	var new_z: int = DepthSort.z_from_y(global_position.y)
	if new_z != z_index:
		z_index = new_z


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

	# Only change animation if it's different from current one to prevent stuttering
	if current_animation != target_animation:
		sprite.play(target_animation)
		current_animation = target_animation

	# Only change flip if necessary to prevent stuttering
	if sprite.flip_h != should_flip:
		sprite.flip_h = should_flip
