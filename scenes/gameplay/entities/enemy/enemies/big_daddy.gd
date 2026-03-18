## © [2024] A7 Studio. All rights reserved. Trademark.
##
## Specific implementation for the Big Daddy enemy, adding shooting capabilities.
class_name BigDaddy
extends IEnemy

@export_subgroup("Shooting Configuration")
## The projectile scene to be instantiated by the enemy
@export var projectile_scene: PackedScene = null
## Runtime stats loaded from StatsDB (JSON); defaults kept neutral here
var shoot_range: float = 0.0
var fire_rate: float = 0.0
var tower_disable_duration: float = 0.0

@export_subgroup("Attack Cycle Configuration")
## Runtime stats loaded from StatsDB (JSON); defaults kept neutral here
var pre_attack_delay: float = 0.0
var attack_duration: float = 0.0
var post_attack_delay: float = 0.0
var attack_cooldown: float = 0.0


# Onready variables
## The area 2D node for the enemy to detect towers in range
@onready var range_area: Area2D = $RangeArea
## The collision shape 2D node for the range detection
@onready var range_collision_shape: CollisionShape2D = $RangeArea/CollisionShape2D
## The timer for the fire rate of the enemy to shoot projectiles
@onready var fire_rate_timer: Timer = $FireRateTimer

# Attack Cycle Timers (created in _ready)
var _pre_attack_timer: Timer
var _attack_duration_timer: Timer
var _post_attack_timer: Timer
var _attack_cooldown_timer: Timer

# Attack Cycle State
enum AttackCycleState {
	NONE,      # Not in an attack cycle, or cooldown finished
	PRE_ATTACK,  # Waiting before attack
	ATTACKING,   # Actively shooting
	POST_ATTACK, # Waiting after attack
	COOLDOWN     # Waiting before next attack cycle can start
}
var _current_attack_cycle_state: AttackCycleState = AttackCycleState.NONE

# Variables
## Array to store towers currently within range
var towers_in_range: Array[Node2D] = []
## The current target tower
var current_target: Node2D = null


func _ready() -> void:
	_apply_extra_stats_override()
	super._ready() # Call the parent class's _ready function

	# Ensure nodes are ready before connecting signals or configuring them
	await ready

	# Configure Range Area
	assert(range_area and range_collision_shape and range_collision_shape.shape is CircleShape2D)
	Log.trace(Log.Level.INFO, "BigDaddy: Setting range to %s" % shoot_range)
	range_collision_shape.shape.radius = shoot_range
	# range_area.body_entered.connect(_on_range_area_body_entered) # already connected in IEnemy
	range_area.body_exited.connect(_on_range_area_body_exited)

	# Configure Fire Rate Timer (DO NOT START IT HERE. It's controlled by attack cycle)
	assert(fire_rate_timer)
	fire_rate_timer.wait_time = 1.0 / max(fire_rate, 0.01) # Avoid division by zero
	fire_rate_timer.timeout.connect(_shoot)
	# fire_rate_timer.start() # REMOVED: Controlled by attack cycle state

	# Create and configure Attack Cycle Timers
	_pre_attack_timer = Timer.new()
	_pre_attack_timer.name = "PreAttackTimer"
	_pre_attack_timer.one_shot = true
	_pre_attack_timer.timeout.connect(_on_pre_attack_timer_timeout)
	add_child(_pre_attack_timer)

	_attack_duration_timer = Timer.new()
	_attack_duration_timer.name = "AttackDurationTimer"
	_attack_duration_timer.one_shot = true
	_attack_duration_timer.timeout.connect(_on_attack_duration_timer_timeout)
	add_child(_attack_duration_timer)

	_post_attack_timer = Timer.new()
	_post_attack_timer.name = "PostAttackTimer"
	_post_attack_timer.one_shot = true
	_post_attack_timer.timeout.connect(_on_post_attack_timer_timeout)
	add_child(_post_attack_timer)

	_attack_cooldown_timer = Timer.new()
	_attack_cooldown_timer.name = "AttackCooldownTimer"
	_attack_cooldown_timer.one_shot = true
	_attack_cooldown_timer.timeout.connect(_on_attack_cooldown_timer_timeout)
	add_child(_attack_cooldown_timer)

	# Initial check for targets already in range
	_find_new_target()


func _apply_extra_stats_override() -> void:
	if enemy_id.is_empty() or stats_db == null:
		return
	if not stats_db.has_enemy(enemy_id):
		return
	var data: Dictionary = stats_db.get_enemy(enemy_id)
	var extra: Dictionary = data.get("extra", {})
	Log.trace(Log.Level.INFO, "Applying big_daddy extra stats from StatsDB: %s" % extra)
	if extra.has("shoot_range"):
		shoot_range = float(extra["shoot_range"])
	if extra.has("fire_rate"):
		fire_rate = float(extra["fire_rate"])
	if extra.has("tower_disable_duration"):
		tower_disable_duration = float(extra["tower_disable_duration"])
	if extra.has("pre_attack_delay"):
		pre_attack_delay = float(extra["pre_attack_delay"])
	if extra.has("attack_duration"):
		attack_duration = float(extra["attack_duration"])
	if extra.has("post_attack_delay"):
		post_attack_delay = float(extra["post_attack_delay"])
	if extra.has("attack_cooldown"):
		attack_cooldown = float(extra["attack_cooldown"])


func _physics_process(delta: float) -> void:
	if is_already_dead or Global.paused:
		if fire_rate_timer and not fire_rate_timer.is_stopped():
			fire_rate_timer.stop()
		_stop_all_attack_timers_and_reset_state()
		return

	# Attack Cycle Logic
	if current_target and _current_attack_cycle_state == AttackCycleState.NONE:
		Log.trace(Log.Level.DEBUG, "BigDaddy: Target '%s' in range, starting attack cycle." % current_target.name if current_target else "UNKNOWN")
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

	# Optional: Make the enemy face its target if it has one
	# if current_target:
	#	look_at(current_target.global_position)

# --- Attack Cycle Timer Handlers ---

func _on_pre_attack_timer_timeout() -> void:
	if _current_attack_cycle_state != AttackCycleState.PRE_ATTACK or not current_target:
		if _current_attack_cycle_state == AttackCycleState.PRE_ATTACK: # Only interrupt if we were in pre_attack
			Log.trace(Log.Level.DEBUG, "BigDaddy: Target lost or state changed during pre_attack_delay. Interrupting.")
			_interrupt_attack_cycle()
		return
	Log.trace(Log.Level.DEBUG, "BigDaddy: Pre-attack delay finished. Starting ATTACKING.")
	_current_attack_cycle_state = AttackCycleState.ATTACKING
	_attack_duration_timer.start(attack_duration)
	if fire_rate > 0 and fire_rate_timer:
		fire_rate_timer.start()

func _on_attack_duration_timer_timeout() -> void:
	if _current_attack_cycle_state != AttackCycleState.ATTACKING:
		return
	Log.trace(Log.Level.DEBUG, "BigDaddy: Attack duration finished. Starting POST_ATTACK.")
	_current_attack_cycle_state = AttackCycleState.POST_ATTACK
	_post_attack_timer.start(post_attack_delay)
	if fire_rate_timer:
		fire_rate_timer.stop()

func _on_post_attack_timer_timeout() -> void:
	if _current_attack_cycle_state != AttackCycleState.POST_ATTACK:
		return
	Log.trace(Log.Level.DEBUG, "BigDaddy: Post-attack delay finished. Starting COOLDOWN.")
	_current_attack_cycle_state = AttackCycleState.COOLDOWN
	_attack_cooldown_timer.start(attack_cooldown)

func _on_attack_cooldown_timer_timeout() -> void:
	if _current_attack_cycle_state != AttackCycleState.COOLDOWN:
		return
	Log.trace(Log.Level.DEBUG, "BigDaddy: Attack cooldown finished. State back to NONE.")
	_current_attack_cycle_state = AttackCycleState.NONE

# --- Helper functions for Attack Cycle ---

func _interrupt_attack_cycle() -> void:
	Log.trace(Log.Level.DEBUG, "BigDaddy: Interrupting attack cycle.")
	if _pre_attack_timer: _pre_attack_timer.stop()
	if _attack_duration_timer: _attack_duration_timer.stop()
	if _post_attack_timer: _post_attack_timer.stop()
	if fire_rate_timer: fire_rate_timer.stop()

	_current_attack_cycle_state = AttackCycleState.COOLDOWN
	if _attack_cooldown_timer: _attack_cooldown_timer.start(attack_cooldown)

func _stop_all_attack_timers_and_reset_state() -> void:
	Log.trace(Log.Level.DEBUG, "BigDaddy: Stopping all attack timers and resetting state (death/pause).")
	if _pre_attack_timer: _pre_attack_timer.stop()
	if _attack_duration_timer: _attack_duration_timer.stop()
	if _post_attack_timer: _post_attack_timer.stop()
	if _attack_cooldown_timer: _attack_cooldown_timer.stop()
	if fire_rate_timer: fire_rate_timer.stop()
	_current_attack_cycle_state = AttackCycleState.NONE

# --- Target Management ---

func _find_new_target() -> void:
	var old_target_body = current_target # current_target is the body
	var closest_tower_body: Node2D = null # This will be the body node (e.g. TowerBody)
	var min_dist_sq: float = INF

	for detected_body in towers_in_range: # detected_body is from range_area
		if not is_instance_valid(detected_body):
			# Log.trace(Log.Level.DEBUG, "BigDaddy: Invalid instance in towers_in_range, skipping.")
			continue

		var tower_script_node = detected_body.get_parent()
		if not (tower_script_node is ITower):
			Log.trace(Log.Level.WARN, "BigDaddy: Body '%s' in towers_in_range (group 'towers') does not have ITower as parent. Skipping." % detected_body.name)
			continue

		if tower_script_node.state != ITower.TowerState.ACTIVE:
			Log.trace(Log.Level.DEBUG, "BigDaddy: Tower '%s' (parent of '%s') is not ACTIVE (state: %s), skipping." % [tower_script_node.name, detected_body.name, tower_script_node.state])
			continue

		# Target is active, proceed with distance check
		var dist_sq: float = global_position.distance_squared_to(detected_body.global_position)
		if dist_sq < min_dist_sq:
			min_dist_sq = dist_sq
			closest_tower_body = detected_body

	current_target = closest_tower_body # current_target is the body (e.g. "TowerBody")

	if old_target_body != current_target:
		if current_target:
			var parent_tower_name = "UNKNOWN_PARENT"
			var parent_tower_state = "UNKNOWN_STATE"
			if current_target.get_parent() is ITower:
				parent_tower_name = current_target.get_parent().name
				parent_tower_state = ITower.TowerState.keys()[current_target.get_parent().state] # Get state name
			Log.trace(Log.Level.DEBUG, "BigDaddy: New target body acquired: %s (parent ITower: %s, state: %s)" % [current_target.name, parent_tower_name, parent_tower_state])
		elif old_target_body: # Had a target, but now no active ones
			Log.trace(Log.Level.DEBUG, "BigDaddy: Target body lost or no valid (active) tower bodies in range.")
		# else: No old target, no new target, already covered by logging if new target is found or not.


# --- Shooting ---

func _shoot() -> void:
	if is_already_dead or _current_attack_cycle_state != AttackCycleState.ATTACKING:
		return

	if not is_instance_valid(current_target): # current_target is the body
		_find_new_target() # This will now only find bodies of ACTIVE towers
		if not current_target: # Still no target body
			# Log.trace(Log.Level.DEBUG, "BigDaddy: No valid target found after _find_new_target in _shoot.")
			return

	# current_target is a body (e.g. "TowerBody"). Get its parent ITower for state check.
	var tower_script_node = current_target.get_parent()

	if not (tower_script_node is ITower):
		Log.trace(Log.Level.ERROR, "BigDaddy: current_target '%s' (body) does not have an ITower parent. Critical issue. Interrupting attack." % current_target.name)
		_interrupt_attack_cycle() # Stop current attack cycle
		current_target = null # Clear invalid target
		# Potentially remove from towers_in_range if it's fundamentally wrong, though body_exited should handle if freed
		if towers_in_range.has(current_target):
			towers_in_range.erase(current_target)
		_find_new_target() # Try to recover by finding a new target
		return

	if tower_script_node.state != ITower.TowerState.ACTIVE:
		var current_state_name = ITower.TowerState.keys()[tower_script_node.state]
		Log.trace(Log.Level.DEBUG, "BigDaddy: Tower '%s' (parent of '%s') is no longer ACTIVE (state: %s). Aborting shot." % [tower_script_node.name, current_target.name, current_state_name])
		_interrupt_attack_cycle()
		current_target = null # Clear this non-active target
		# No need to remove from towers_in_range here, _find_new_target will filter it out next time.
		_find_new_target() # Find a new one.
		return

	if not projectile_scene:
		Log.trace(Log.Level.ERROR, "BigDaddy: Missing projectile scene!")
		return

	var projectile = projectile_scene.instantiate()

	var bullet_container = get_tree().get_first_node_in_group("bullet_container")
	if bullet_container:
		bullet_container.add_child(projectile)
		projectile.z_index = 100
	elif get_parent():
		get_parent().add_child(projectile)
		Log.trace(Log.Level.WARN, "BigDaddy: 'bullet_container' group not found. Adding projectile to get_parent().")
	else:
		Log.trace(Log.Level.ERROR, "BigDaddy: Cannot add projectile, no parent and no bullet_container.")
		projectile.queue_free()
		return

	projectile.global_position = global_position
	if is_instance_valid(current_target):
		var direction_to_target = global_position.direction_to(current_target.global_position)
		projectile.rotation = direction_to_target.angle()

		if projectile.has_method("init"):
			projectile.init(direction_to_target, tower_disable_duration)
		elif projectile.has_meta("direction"):
			projectile.set_meta("direction", direction_to_target)
	else:
		Log.trace(Log.Level.WARN, "BigDaddy: Target became invalid right before setting projectile direction.")


# Override take_damage if needed, e.g., to stop shooting temporarily
# func take_damage(damage: float, damage_type: DamageType) -> void:
#	 super.take_damage(damage, damage_type)
#	 # Maybe interrupt shooting animation or timer?


# Override _dead_state if needed
# func _dead_state() -> void:
#	 super._dead_state()
#	 # Ensure timer is stopped
#	 if fire_rate_timer: fire_rate_timer.stop()



func _on_range_area_body_entered(body: Node2D) -> void:
	# Log.trace(Log.Level.DEBUG, "BigDaddy: Range area body entered: %s" % body.name) # Can be verbose
	if body.is_in_group("towers"):
		if not body in towers_in_range:
			towers_in_range.append(body)
			Log.trace(Log.Level.DEBUG, "BigDaddy: Tower '%s' entered range. Total in range: %s" % [body.name, towers_in_range.size()])
			if not current_target:
				_find_new_target()


func _on_range_area_body_exited(body: Node2D) -> void:
	if body in towers_in_range:
		towers_in_range.erase(body)
		Log.trace(Log.Level.DEBUG, "BigDaddy: Tower '%s' exited range. Total in range: %s" % [body.name, towers_in_range.size()])
		if body == current_target:
			current_target = null
			_find_new_target()
