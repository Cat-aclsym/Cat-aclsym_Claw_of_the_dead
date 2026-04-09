## © [2024] A7 Studio. All rights reserved. Trademark.
##
## Projectile fired by enemies, targeting towers.
class_name EnemyProjectile
extends Area2D

@export var speed: float = 200.0

var direction: Vector2 = Vector2.ZERO
var disable_duration: float = 3.0


func _ready() -> void:
	# Connect the collision signal
	body_entered.connect(_on_body_entered)
	# Destroy the projectile after a short lifetime if it misses
	await get_tree().create_timer(5.0).timeout
	if is_instance_valid(self):
		queue_free()


func _physics_process(delta: float) -> void:
	if Global.paused:
		return
	# Move the projectile
	global_position += direction * speed * delta


func init(_direction: Vector2, _disable_duration: float = 3.0) -> void:
	"""Initializes the projectile with a direction and disable duration.

	Args:
		_direction: The direction the projectile will travel
		_disable_duration: How long the tower will be disabled when hit
	"""
	direction = _direction
	disable_duration = _disable_duration
	# Adjust sprite rotation based on direction
	rotation = direction.angle()


func _on_body_entered(body: Node2D) -> void:
	# Check if the body is a tower
	if body.is_in_group("towers"): # Assumes towers are in the "towers" group
		# Create impact particles at collision point
		_spawn_impact_particles(body.global_position)

		# Get the parent tower node
		var tower = body.get_parent()
		if tower is ITower:
			# Disable the tower
			_disable_tower(tower)

		# Destroy the projectile after hitting a tower
		queue_free()

	# Optional: Check if it hit terrain/obstacles and destroy
	# elif body.is_in_group("obstacles"):
	# 	 queue_free()


func _spawn_impact_particles(pos: Vector2) -> void:
	"""Creates bubble particles at the impact point.

	Args:
		pos: The global position where particles will appear
	"""
	# Create a particles node
	var particles = CPUParticles2D.new()  # Using CPUParticles2D instead of GPUParticles2D
	particles.position = pos
	particles.z_index = 100  # Ensure particles appear above other elements

	# Get scene tree root to add particles at top level
	var root = get_tree().root
	root.add_child(particles)

	# Set emission shape
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 5.0

	# Set particle movement
	particles.direction = Vector2(0, -1)
	particles.spread = 45.0
	particles.initial_velocity_min = 20.0
	particles.initial_velocity_max = 40.0
	particles.gravity = Vector2(0, -20)  # Slight upward movement like bubbles

	# Set particle appearance
	particles.color = Color(0.3, 0.6, 0.9, 0.7)  # Semi-transparent blue
	particles.scale_amount_min = 2.0  # Small squares
	particles.scale_amount_max = 4.0  # Slightly larger squares

	# Set particle lifetime
	particles.lifetime_randomness = 0.3

	# Set emission parameters
	particles.amount = 15  # Not too many for performance
	particles.lifetime = 1.0
	particles.one_shot = true
	particles.explosiveness = 0.8  # Burst at beginning

	# Start emitting
	particles.emitting = true

	# Automatically remove particles after they're done
	var cleanup_timer := get_tree().create_timer(particles.lifetime * 1.2)  # Give a bit extra time
	cleanup_timer.timeout.connect(func():
		if is_instance_valid(particles):
			particles.queue_free()
	)


func _disable_tower(tower: ITower) -> void:
	"""Disables a tower for the specified duration.

	Args:
		tower: The tower to disable
	"""
	# Don't do anything if the tower already has a disable timer
	if tower.has_meta("is_disabled") and tower.get_meta("is_disabled") == true:
		return

	# Mark tower as disabled
	tower.set_meta("is_disabled", true)

	# Store the original modulate color
	var sprite = tower.get_node_or_null("%Sprite")
	if not sprite:
		sprite = tower.get_node_or_null("Sprite")
	
	if not sprite:
		return

	var original_modulate: Color = sprite.modulate

	# Visually indicate the tower is disabled by reducing opacity
	sprite.modulate = Color(original_modulate.r, original_modulate.g,
		original_modulate.b, 0.5)

	# Functionally disable the tower
	tower.fire_rate_timer.stop()
	tower.set_process(false)

	# Re-enable the tower when the timer expires
	var restore_timer := get_tree().create_timer(disable_duration)
	restore_timer.timeout.connect(func():
		if not is_instance_valid(tower) or not is_instance_valid(sprite):
			return

		# Reset visual appearance
		sprite.modulate = original_modulate

		# Restore functionality
		tower.set_process(true)

		# Reset the fire rate timer to allow the tower to resume firing
		if is_instance_valid(tower) and is_instance_valid(tower.fire_rate_timer):
			tower.fire_rate_timer.start()

		# Mark tower as enabled
		tower.set_meta("is_disabled", false)
	)
