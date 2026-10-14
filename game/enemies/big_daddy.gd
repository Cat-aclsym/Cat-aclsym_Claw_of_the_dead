## © [2026] A7 Studio. All rights reserved. Trademark.
##
## Specific implementation for the Big Daddy enemy, adding shooting capabilities.
## [br]Each attack disables the target tower once: the first projectile of the attack window is the only one that hits.
## The other projectiles of the window are a visual stream without collision.
class_name BigDaddy
extends IEnemy

# Enums
# Attack Cycle State
enum AttackCycleState {
	NONE,      # Not in an attack cycle, or cooldown finished
	PRE_ATTACK,  # Waiting before attack
	ATTACKING,   # Actively shooting
	POST_ATTACK, # Waiting after attack
	COOLDOWN     # Waiting before next attack cycle can start
}

# Constants
## Time between two visual stream projectiles while attacking (visual only, not a stat).
const STREAM_INTERVAL: float = 0.02

# Exported variables
@export_subgroup("Shooting Configuration")
## The projectile scene to be instantiated by the enemy
@export var projectile_scene: PackedScene = null

var attack_cooldown: float = 0.0
var attack_duration: float = 0.0
var post_attack_delay: float = 0.0
## Runtime stats loaded from StatsDB (JSON); defaults kept neutral here
var pre_attack_delay: float = 0.0

# Public variables
## The current target tower
var current_target: StaticBody2D = null
## Runtime stats loaded from StatsDB (JSON); defaults kept neutral here
var shoot_range: float = 0.0
var tower_disable_duration: float = 0.0
## Array to store towers currently within range
var towers_in_range: Array[StaticBody2D] = []

# Private variables
var _attack_cooldown_timer: Timer
var _attack_duration_timer: Timer
var _current_attack_cycle_state: AttackCycleState = AttackCycleState.NONE
## Every timer of the attack cycle, built in [method _ready].
var _cycle_timers: Array[Timer] = []
## Whether the gameplay projectile of the current attack window was already fired
var _hit_fired: bool = false
var _post_attack_timer: Timer
var _pre_attack_timer: Timer

# Onready variables
## The area 2D node for the enemy to detect towers in range
@onready var range_area: Area2D = $RangeArea
## The collision shape 2D node for the range detection
@onready var range_collision_shape: CollisionShape2D = $RangeArea/CollisionShape2D
## The timer spawning the visual stream projectiles while attacking
@onready var stream_timer: Timer = $StreamTimer

# Built-in functions
func _ready() -> void:
	super._ready() # Applies the stats, the extra ones (shoot_range, delays) are needed below

	# Configure Range Area
	assert(range_area and range_collision_shape and range_collision_shape.shape is CircleShape2D)
	range_collision_shape.shape.radius = shoot_range
	SignalUtil.connects([
		{SignalUtil.WHO: range_area, SignalUtil.WHAT: "body_entered", SignalUtil.TO: _on_range_area_body_entered},
		{SignalUtil.WHO: range_area, SignalUtil.WHAT: "body_exited", SignalUtil.TO: _on_range_area_body_exited},
	])

	# Configure the stream timer (DO NOT START IT HERE. It's controlled by attack cycle)
	assert(stream_timer)
	stream_timer.wait_time = STREAM_INTERVAL
	SignalUtil.connects([
		{SignalUtil.WHO: stream_timer, SignalUtil.WHAT: "timeout", SignalUtil.TO: _shoot},
		{SignalUtil.WHO: Global, SignalUtil.WHAT: "pause_changed", SignalUtil.TO: _on_pause_changed},
	])

	# Create and configure Attack Cycle Timers
	_pre_attack_timer = _add_cycle_timer("PreAttackTimer", _on_pre_attack_timer_timeout)
	_attack_duration_timer = _add_cycle_timer("AttackDurationTimer", _on_attack_duration_timer_timeout)
	_post_attack_timer = _add_cycle_timer("PostAttackTimer", _on_post_attack_timer_timeout)
	_attack_cooldown_timer = _add_cycle_timer("AttackCooldownTimer", _on_attack_cooldown_timer_timeout)
	_cycle_timers = [_pre_attack_timer, _attack_duration_timer, _post_attack_timer, _attack_cooldown_timer, stream_timer]
	_on_pause_changed(Global.paused)

	# Initial check for targets already in range
	_find_new_target()


func _physics_process(delta: float) -> void:
	if is_already_dead:
		if _current_attack_cycle_state != AttackCycleState.NONE:
			_stop_all_attack_timers_and_reset_state()
		return
	# The attack cycle keeps its state, its timers are paused by _on_pause_changed
	if Global.paused:
		return

	# Attack Cycle Logic
	if current_target and _current_attack_cycle_state == AttackCycleState.NONE:
		Log.trace(Log.Level.DEBUG, "BigDaddy: Target '%s' in range, starting attack cycle." % current_target.name)
		_current_attack_cycle_state = AttackCycleState.PRE_ATTACK
		_pre_attack_timer.start(pre_attack_delay)
	elif not current_target and \
	   (_current_attack_cycle_state == AttackCycleState.PRE_ATTACK or \
		_current_attack_cycle_state == AttackCycleState.ATTACKING):
		Log.trace(Log.Level.DEBUG, "BigDaddy: Target lost during pre-attack/attack. Interrupting.")
		_interrupt_attack_cycle()

	# Movement Logic
	var should_move: bool = true
	match _current_attack_cycle_state:
		AttackCycleState.PRE_ATTACK, AttackCycleState.ATTACKING, AttackCycleState.POST_ATTACK:
			should_move = false
		_:
			should_move = true

	if should_move:
		super._physics_process(delta)

# Private functions
func _add_cycle_timer(timer_name: String, on_timeout: Callable) -> Timer:
	var timer: Timer = Timer.new()
	timer.name = timer_name
	timer.one_shot = true
	SignalUtil.connects([{SignalUtil.WHO: timer, SignalUtil.WHAT: "timeout", SignalUtil.TO: on_timeout}])
	add_child(timer)
	return timer


## Checks that the current target is an active tower, otherwise interrupts the attack and looks for another target.
func _can_hit_current_target() -> bool:
	# current_target is a body (e.g. "TowerBody"). Get its parent ITower for state check.
	var tower_script_node: ITower = current_target.get_parent() as ITower

	if not tower_script_node:
		Log.trace(Log.Level.ERROR, "BigDaddy: current_target '%s' (body) does not have an ITower parent. Critical issue. Interrupting attack." % current_target.name)
		_interrupt_attack_cycle() # Stop current attack cycle
		# Remove the invalid body from the list before forgetting it, otherwise it stays there
		towers_in_range.erase(current_target)
		current_target = null
		_find_new_target() # Try to recover by finding a new target
		return false

	if tower_script_node.state != ITower.TowerState.ACTIVE:
		var current_state_name: String = ITower.TowerState.keys()[tower_script_node.state]
		Log.trace(Log.Level.DEBUG, "BigDaddy: Tower '%s' (parent of '%s') is no longer ACTIVE (state: %s). Aborting shot." % [tower_script_node.name, current_target.name, current_state_name])
		_interrupt_attack_cycle()
		current_target = null # Clear this non-active target
		# No need to remove from towers_in_range here, _find_new_target will filter it out next time.
		_find_new_target() # Find a new one.
		return false
	return true


func _find_new_target() -> void:
	var old_target_body: StaticBody2D = current_target # current_target is the body
	var closest_tower_body: StaticBody2D = null # This will be the body node (e.g. TowerBody)
	var min_dist_sq: float = INF

	for detected_body in towers_in_range: # detected_body is from range_area
		if not is_instance_valid(detected_body):
			continue

		var tower_script_node: ITower = detected_body.get_parent() as ITower
		if not tower_script_node:
			Log.trace(Log.Level.WARN, "BigDaddy: Body '%s' in towers_in_range (group 'towers') does not have ITower as parent. Skipping." % detected_body.name)
			continue

		if tower_script_node.state != ITower.TowerState.ACTIVE:
			continue

		# Target is active, proceed with distance check
		var dist_sq: float = global_position.distance_squared_to(detected_body.global_position)
		if dist_sq < min_dist_sq:
			min_dist_sq = dist_sq
			closest_tower_body = detected_body

	current_target = closest_tower_body # current_target is the body (e.g. "TowerBody")
	if old_target_body != current_target:
		Log.trace(Log.Level.DEBUG, "BigDaddy: Target changed to %s." % [current_target.name if current_target else "none"])


func _interrupt_attack_cycle() -> void:
	Log.trace(Log.Level.DEBUG, "BigDaddy: Interrupting attack cycle.")
	for timer: Timer in _cycle_timers:
		timer.stop()

	_current_attack_cycle_state = AttackCycleState.COOLDOWN
	_attack_cooldown_timer.start(attack_cooldown)


func _on_attack_cooldown_timer_timeout() -> void:
	if _current_attack_cycle_state != AttackCycleState.COOLDOWN:
		return
	Log.trace(Log.Level.DEBUG, "BigDaddy: Attack cooldown finished. State back to NONE.")
	_current_attack_cycle_state = AttackCycleState.NONE


func _on_attack_duration_timer_timeout() -> void:
	if _current_attack_cycle_state != AttackCycleState.ATTACKING:
		return
	Log.trace(Log.Level.DEBUG, "BigDaddy: Attack duration finished. Starting POST_ATTACK.")
	_current_attack_cycle_state = AttackCycleState.POST_ATTACK
	_post_attack_timer.start(post_attack_delay)
	stream_timer.stop()


## Pauses the attack cycle timers with the game and resumes them where they stopped.
func _on_pause_changed(is_paused: bool) -> void:
	for timer: Timer in _cycle_timers:
		timer.paused = is_paused


func _on_post_attack_timer_timeout() -> void:
	if _current_attack_cycle_state != AttackCycleState.POST_ATTACK:
		return
	Log.trace(Log.Level.DEBUG, "BigDaddy: Post-attack delay finished. Starting COOLDOWN.")
	_current_attack_cycle_state = AttackCycleState.COOLDOWN
	_attack_cooldown_timer.start(attack_cooldown)


func _on_pre_attack_timer_timeout() -> void:
	if _current_attack_cycle_state != AttackCycleState.PRE_ATTACK or not current_target:
		if _current_attack_cycle_state == AttackCycleState.PRE_ATTACK: # Only interrupt if we were in pre_attack
			Log.trace(Log.Level.DEBUG, "BigDaddy: Target lost or state changed during pre_attack_delay. Interrupting.")
			_interrupt_attack_cycle()
		return
	Log.trace(Log.Level.DEBUG, "BigDaddy: Pre-attack delay finished. Starting ATTACKING.")
	_current_attack_cycle_state = AttackCycleState.ATTACKING
	_hit_fired = false
	_attack_duration_timer.start(attack_duration)
	# The first shot of the window is the gameplay hit, the timer then streams the visual projectiles
	_shoot()
	if _current_attack_cycle_state == AttackCycleState.ATTACKING:
		stream_timer.start()


func _on_range_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("towers") and body is StaticBody2D:
		var tower_body := body as StaticBody2D
		if not tower_body in towers_in_range:
			towers_in_range.append(tower_body)
			Log.trace(Log.Level.DEBUG, "BigDaddy: Tower '%s' entered range. Total in range: %s" % [tower_body.name, towers_in_range.size()])
			if not current_target:
				_find_new_target()


func _on_range_area_body_exited(body: Node2D) -> void:
	if body is StaticBody2D and body in towers_in_range:
		towers_in_range.erase(body as StaticBody2D)
		Log.trace(Log.Level.DEBUG, "BigDaddy: Tower '%s' exited range. Total in range: %s" % [body.name, towers_in_range.size()])
		if body == current_target:
			current_target = null
			_find_new_target()


## Fires one projectile at the current target. The first one of an attack window hits for real, the next ones are visual only.
func _shoot() -> void:
	if is_already_dead or _current_attack_cycle_state != AttackCycleState.ATTACKING:
		return

	if not is_instance_valid(current_target): # current_target is the body
		_find_new_target() # This will now only find bodies of ACTIVE towers
		if not current_target: # Still no target body
			return

	# The visual stream only needs a target position, only the gameplay hit checks that the tower can still be hit
	if not _hit_fired and not _can_hit_current_target():
		return

	if not projectile_scene:
		Log.trace(Log.Level.ERROR, "BigDaddy: Missing projectile scene!")
		return

	var projectile: EnemyProjectile = projectile_scene.instantiate() as EnemyProjectile
	var direction_to_target: Vector2 = global_position.direction_to(current_target.global_position)
	var is_visual_only: bool = _hit_fired
	var travel_time: float = global_position.distance_to(current_target.global_position) / projectile.speed
	projectile.init(direction_to_target, tower_disable_duration, is_visual_only, travel_time)

	if is_instance_valid(ILevel.current_level):
		ILevel.current_level.add_child(projectile)
		projectile.z_index = 100
	elif get_parent():
		get_parent().add_child(projectile)
		Log.trace(Log.Level.WARN, "BigDaddy: no current level. Adding projectile to get_parent().")
	else:
		Log.trace(Log.Level.ERROR, "BigDaddy: Cannot add projectile, no parent and no current level.")
		projectile.queue_free()
		return

	projectile.global_position = global_position
	_hit_fired = true


func _stop_all_attack_timers_and_reset_state() -> void:
	for timer: Timer in _cycle_timers:
		timer.stop()
	_current_attack_cycle_state = AttackCycleState.NONE
