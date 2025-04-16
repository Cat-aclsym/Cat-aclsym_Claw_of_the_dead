## © [2024] A7 Studio. All rights reserved. Trademark.
##
## Specific implementation for the Big Daddy enemy, adding shooting capabilities.
class_name BigDaddy
extends IEnemy

@export_subgroup("Shooting Configuration")
## The projectile scene to be instantiated by the enemy
@export var projectile_scene: PackedScene = null
## The shooting range of the enemy
@export var shoot_range: float = 150.0
## The fire rate of the enemy (shots per second)
@export var fire_rate: float = 0.5

# Onready variables
## The area 2D node for the enemy to detect towers in range
@onready var range_area: Area2D = $RangeArea
## The collision shape 2D node for the range detection
@onready var range_collision_shape: CollisionShape2D = $RangeArea/CollisionShape2D
## The timer for the fire rate of the enemy to shoot projectiles
@onready var fire_rate_timer: Timer = $FireRateTimer

# Variables
## Array to store towers currently within range
var towers_in_range: Array[Node2D] = []
## The current target tower
var current_target: Node2D = null


func _ready() -> void:
	super._ready() # Call the parent class's _ready function

	# Ensure nodes are ready before connecting signals or configuring them
	await ready

	# Configure Range Area
	assert(range_area and range_collision_shape and range_collision_shape.shape is CircleShape2D)
	Log.trace(Log.Level.INFO, "BigDaddy: Setting range to %s" % shoot_range)
	range_collision_shape.shape.radius = shoot_range
	range_area.body_entered.connect(_on_range_area_body_entered)
	range_area.body_exited.connect(_on_range_area_body_exited)

	# Configure Fire Rate Timer
	assert(fire_rate_timer)
	fire_rate_timer.wait_time = 1.0 / max(fire_rate, 0.01) # Avoid division by zero
	fire_rate_timer.timeout.connect(_shoot)
	fire_rate_timer.start()

	# Initial check for targets already in range (optional, depends on timing)
	_find_new_target()


func _physics_process(delta: float) -> void:
	if is_already_dead or Global.paused:
		if fire_rate_timer and not fire_rate_timer.is_stopped():
			fire_rate_timer.stop()
		return

	# Restart timer if it was stopped and the enemy is alive
	if not is_already_dead and fire_rate_timer and fire_rate_timer.is_stopped():
		fire_rate_timer.start()

	# Keep standard enemy behavior (movement, etc.)
	super._physics_process(delta)

	# Optional: Make the enemy face its target if it has one
	# if current_target:
	#	look_at(current_target.global_position)


# func _on_RangeArea_body_exited(body: Node2D) -> void:
	# if body in towers_in_range:
	# 	towers_in_range.erase(body)
	# 	Log.trace(Log.Level.DEBUG, "BigDaddy: Tower exited range: %s" % body.name)
	# 	if body == current_target: # If the target left range, find a new one
	# 		current_target = null
	# 		_find_new_target()


func _find_new_target() -> void:
	current_target = null
	var closest_tower: Node2D = null
	var min_dist_sq: float = 999999999 # Use squared distance for efficiency

	for tower in towers_in_range:
		# Optional: Add a check to ensure the tower is still valid (e.g., not destroyed)
		# if not is_instance_valid(tower): continue

		var dist_sq: float = global_position.distance_squared_to(tower.global_position)
		if dist_sq < min_dist_sq:
			min_dist_sq = dist_sq
			closest_tower = tower

	current_target = closest_tower


# --- Shooting ---

func _shoot() -> void:
	if is_already_dead or state != EnemyState.FOLLOW_PATH: # Only shoot while moving/idle, not when dead/finished
		return

	# Re-validate target just before shooting
	if not is_instance_valid(current_target) or not current_target in towers_in_range:
		_find_new_target() # Try to find a new target if the current one is invalid

	if not current_target:
		# Log.trace(Log.Level.DEBUG, "BigDaddy: Shoot cancelled, no valid target.")
		return # No target to shoot at

	if not projectile_scene:
		Log.trace(Log.Level.ERROR, "BigDaddy: Missing projectile scene!")
		return

	Log.trace(Log.Level.INFO, "BigDaddy: Firing at %s" % current_target.name)

	# Instantiate projectile
	var projectile = projectile_scene.instantiate() # Assuming projectile script handles itself

	# Add projectile to the main level scene tree for proper cleanup? Or parent?
	# Option 1: Add to parent (the enemy spawner or level)
	# get_parent().add_child(projectile)
	# Option 2: Add to a dedicated bullet container node in the level (better)
	var bullet_container = get_tree().get_first_node_in_group("bullet_container") # Needs setup
	if bullet_container:
		bullet_container.add_child(projectile)
		projectile.z_index = 100
		projectile.global_position = global_position
	else: # Fallback to parent
		Log.trace(Log.Level.WARN, "BigDaddy: 'bullet_container' group not found. Adding projectile to parent.")
		get_parent().add_child(projectile)


	# Setup projectile
	projectile.global_position = global_position # Start at enemy position
	var direction_to_target = global_position.direction_to(current_target.global_position)
	projectile.rotation = direction_to_target.angle()

	# Pass necessary info to projectile (if its script needs it)
	if projectile.has_method("init"):
		projectile.init(direction_to_target) # Example init method
	elif projectile.has_meta("direction"): # Check if using exported variable
		projectile.set_meta("direction", direction_to_target)
	# projectile.target_group = "towers" # Set group for collision if needed

	# Note: Projectile movement and collision should be handled in its own script.


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
	Log.trace(Log.Level.DEBUG, "BigDaddy: Range area body entered: %s" % body.name)
	# Check if the body is a tower (using group or class_name)
	if body.is_in_group("towers"): # Assuming towers are in the "towers" group
		Log.trace(Log.Level.DEBUG, "BigDaddy: Tower entered range: %s" % body.name)
		if not body in towers_in_range:
			towers_in_range.append(body)
			if not current_target: # Find a target if we don't have one
				_find_new_target()


func _on_range_area_body_exited(body: Node2D) -> void:
	if body in towers_in_range:
		towers_in_range.erase(body)
		Log.trace(Log.Level.DEBUG, "BigDaddy: Tower exited range: %s" % body.name)
		if body == current_target: # If the target left range, find a new one
			current_target = null
			_find_new_target()
