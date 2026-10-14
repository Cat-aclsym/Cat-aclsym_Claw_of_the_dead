## © [2026] A7 Studio. All rights reserved. Trademark.
##
## Projectile fired by enemies, targeting towers.
class_name EnemyProjectile
extends Area2D

# Constants
const DESTROY_TIMEOUT: float = 5.0

# Exported variables
@export var speed: float = 200.0

# Public variables
var direction := Vector2.ZERO
var disable_duration: float = 3.0
## True for the stream projectiles that only look like an attack: they never disable a tower.
var is_visual_only: bool = false

var _lifetime: float = 0.0


# Built-in functions
func _ready() -> void:
	# Connect the collision signal
	SignalUtil.connects([{SignalUtil.WHO: self, SignalUtil.WHAT: "body_entered", SignalUtil.TO: _on_body_entered}])
	# Destroy the projectile after a short lifetime if it misses, the tween dies with the projectile
	var lifetime_tween: Tween = create_tween()
	lifetime_tween.tween_interval(_lifetime if _lifetime > 0.0 else DESTROY_TIMEOUT)
	lifetime_tween.tween_callback(queue_free)


func _physics_process(delta: float) -> void:
	if Global.paused:
		return
	# Move the projectile
	global_position += direction * speed * delta


# Public functions
## Initializes the projectile with a direction and disable duration.
## [br]
## [param _direction] The direction the projectile will travel
## [param _disable_duration] How long the tower will be disabled when hit
## [param p_visual_only] A visual-only projectile has no collision and no effect, it only flies for [param p_lifetime] seconds
func init(_direction: Vector2, _disable_duration: float = 3.0, p_visual_only: bool = false, p_lifetime: float = 0.0) -> void:
	direction = _direction
	disable_duration = _disable_duration
	_lifetime = p_lifetime
	if p_visual_only:
		is_visual_only = true
		set_deferred("monitoring", false)
	# Adjust sprite rotation based on direction
	rotation = direction.angle()


# Private functions
func _on_body_entered(body: Node2D) -> void:
	if is_visual_only:
		return

	# Check if the body is a tower
	if body.is_in_group("towers"): # Assumes towers are in the "towers" group
		# Create impact particles at collision point
		_spawn_impact_particles(body.global_position)

		# Get the parent tower node
		var tower: Node = body.get_parent()
		if is_instance_valid(tower) and tower is ITower:
			# Disable the tower
			(tower as ITower).disable_tower_for(disable_duration)

		# Destroy the projectile after hitting a tower
		queue_free()


func _spawn_impact_particles(pos: Vector2) -> void:
	## Creates bubble particles at the impact point.
	## [param pos] The global position where particles will appear
	# Create a particles node
	var particles := CPUParticles2D.new()
	particles.position = pos
	particles.z_index = 100  # Ensure particles appear above other elements

	# Get scene tree root to add particles at top level
	var root: Window = get_tree().root
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

	# Automatically remove particles after they're done, with a bit of extra time
	VfxUtil.free_after(particles, particles.lifetime * 1.2)
