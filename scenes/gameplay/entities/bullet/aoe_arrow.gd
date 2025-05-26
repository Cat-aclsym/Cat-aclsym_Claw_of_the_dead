## © [2024] A7 Studio. All rights reserved. Trademark.
##
## AOE arrow bullet that deals area damage on impact.
class_name AOEArrow
extends IBullet

# Constants
const AOE_DAMAGE_MULTIPLIER: float = 0.75  # AOE damage is 75% of direct hit damage
const DEFAULT_AOE_RANGE: int = 100  # Reference size to calculate proportions

# Exports
@export var aoe_range: int = 100  ## Range of the area of effect

@export_group("Explosion Effect")
@export var explosion_effect_enabled: bool = true ## Enable explosion effect
@export var shockwave_duration: float = 0.5 ## Duration of shockwave
@export var shockwave_color: Color = Color(0.8, 0.9, 1.0, 0.7) ## Color of shockwave
@export var debris_particles_count: int = 25 ## Number of debris particles
@export var debris_particles_lifetime: float = 0.8 ## Lifetime of debris
@export var debris_particles_speed: float = 150.0 ## Speed of debris
@export var debris_particles_size: float = 2.0 ## Size of debris
@export var debris_particles_color: Color = Color(0.6, 0.6, 0.6, 0.8) ## Color of debris

# Variables
var aoe_enemies: Array[IEnemy] = []
var _area_size_ratio: float = 1.0  # Ratio calculated relative to standard size
var _is_exploding: bool = false

@onready var aoe_detection_area: Area2D = $AOEArea
@onready var aoe_detection_area_collision: CollisionShape2D = $AOEArea/CollisionShape2D
@onready var arrow_sprite: Sprite2D = $Sprite2D

# Effect circle - can be ShockwaveCircle or BurnAreaCircle depending on the child class
var effect_circle: Polygon2D

# Signals
@onready var aoe_signals: Array[Dictionary] = [
	{SignalUtil.WHO: aoe_detection_area, SignalUtil.WHAT: "body_entered", SignalUtil.TO: _on_aoe_area_body_entered},
	{SignalUtil.WHO: aoe_detection_area, SignalUtil.WHAT: "body_exited", SignalUtil.TO: _on_aoe_area_body_exited}
]


# core
func _ready() -> void:
	super._ready()
	
	# Calculate size ratio compared to standard size
	_area_size_ratio = float(aoe_range) / DEFAULT_AOE_RANGE
	
	# Configure the AOE area
	if aoe_detection_area_collision.shape is CircleShape2D:
		aoe_detection_area_collision.shape.radius = aoe_range
	
	# Try to find the effect circle (ShockwaveCircle for AOE, BurnAreaCircle for Fire)
	effect_circle = get_node_or_null("ShockwaveCircle")
	if not effect_circle:
		effect_circle = get_node_or_null("BurnAreaCircle")
	
	# Initialize effect circle if it exists
	if effect_circle:
		effect_circle.visible = false
		effect_circle.scale = Vector2.ZERO
		_adjust_effect_circle_size()
	
	SignalUtil.connects(aoe_signals)


func _physics_process(delta: float) -> void:
	if Global.paused or _is_exploding:
		return
		
	position += direction * speed * delta


# Protected methods for inheritance
## Virtual method called when impact occurs - override in child classes
func _on_impact_effect(enemy: IEnemy, impact_position: Vector2) -> void:
	# Default behavior: create explosion effect
	if explosion_effect_enabled:
		_create_explosion_effect(impact_position)
		if effect_circle:
			_start_shockwave_animation()
		else:
			# No effect circle, just destroy immediately
			queue_free()


## Common impact handling - factorized from both classes
func _handle_impact(enemy: IEnemy) -> void:
	_is_exploding = true
	
	# Apply direct hit damage
	enemy.take_damage(damage, IEnemy.DamageType.DEFAULT)
	
	# Create blood effect for directly hit enemy (inherited from IBullet)
	if hit_effect_enabled:
		_create_hit_effect(global_position)
	
	# Apply AOE damage to nearby enemies
	_apply_aoe_damage(enemy)
	
	# Stop arrow movement and hide sprite
	_stop_arrow_movement()
	
	# Handle trail particles cleanup
	_cleanup_trail_particles()
	
	# Call virtual method for specific impact effects
	_on_impact_effect(enemy, global_position)


## Apply AOE damage to nearby enemies (factorized)
func _apply_aoe_damage(direct_hit_enemy: IEnemy) -> void:
	if len(aoe_enemies) > 0:
		if Global.console:
			Global.console.push_debug("Applying AOE damage to " + str(len(aoe_enemies)) + " enemies")
		for nearby_enemy in aoe_enemies:
			if nearby_enemy != direct_hit_enemy and is_instance_valid(nearby_enemy):
				var aoe_damage = roundi(damage * AOE_DAMAGE_MULTIPLIER)
				nearby_enemy.take_damage(aoe_damage, IEnemy.DamageType.DEFAULT)


## Stop arrow movement and hide sprite (factorized)
func _stop_arrow_movement() -> void:
	arrow_sprite.visible = false
	direction = Vector2.ZERO
	speed = 0


## Cleanup trail particles (factorized)
func _cleanup_trail_particles() -> void:
	if trail_enabled and is_instance_valid(_trail_particles):
		_trail_particles.emitting = false
		remove_child(_trail_particles)
		get_parent().add_child(_trail_particles)
		
		var timer = Timer.new()
		_trail_particles.add_child(timer)
		timer.wait_time = trail_lifetime + 0.1
		timer.one_shot = true
		timer.timeout.connect(func(): _trail_particles.queue_free())
		timer.start()


# private
func _adjust_effect_circle_size() -> void:
	# Adjust the effect circle scale based on AOE range
	if effect_circle:
		var visual_scale = _area_size_ratio
		effect_circle.scale = Vector2(visual_scale, visual_scale)


func _create_debris_particle_texture() -> Texture2D:
	# Create a debris texture (small irregular square)
	var image_size := 6
	var image := Image.create(image_size, image_size, false, Image.FORMAT_RGBA8)
	
	# Fill with transparency
	image.fill(Color(0, 0, 0, 0))
	
	# Draw a small square with some missing pixels for irregular appearance
	for x in range(1, image_size - 1):
		for y in range(1, image_size - 1):
			# Add randomness for debris appearance
			if randf() > 0.3:  # 70% chance to have a pixel
				image.set_pixel(x, y, Color(1, 1, 1, 1))
	
	var texture := ImageTexture.create_from_image(image)
	return texture


func _create_explosion_effect(explosion_position: Vector2) -> void:
	# Create explosion effect with debris
	if Global.console:
		Global.console.push_debug("Creating explosion effect at position: " + str(explosion_position))
	
	var scene_root := get_tree().get_root()
	
	# Create the debris particle system
	var debris_particles := GPUParticles2D.new()
	scene_root.add_child(debris_particles)
	debris_particles.global_position = explosion_position
	debris_particles.z_index = 800 # Above enemies but below blood effects
	
	# Create the particle material
	var particle_material := ParticleProcessMaterial.new()
	
	# Configure for an upward-oriented explosion effect
	particle_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_POINT
	particle_material.direction = Vector3(0, -1, 0) # Main direction upward
	particle_material.spread = 120.0 # Reduce spread to concentrate upward
	particle_material.gravity = Vector3(0, 150.0, 0) # Gravity so debris falls back down
	particle_material.initial_velocity_min = debris_particles_speed * 0.8 # Increase minimum speed
	particle_material.initial_velocity_max = debris_particles_speed * 1.3 # Increase maximum speed
	particle_material.scale_min = debris_particles_size * 0.5
	particle_material.scale_max = debris_particles_size
	particle_material.color = debris_particles_color
	particle_material.damping_min = 15.0 # Reduce damping for more range
	particle_material.damping_max = 30.0
	
	# Create a gradient for debris fading
	var gradient := Gradient.new()
	gradient.add_point(0.0, debris_particles_color)
	
	var mid_color := debris_particles_color
	mid_color.a *= 0.8
	gradient.add_point(0.3, mid_color)
	
	var fade_color := debris_particles_color
	fade_color.a = 0.0
	gradient.add_point(1.0, fade_color)
	
	var color_ramp := GradientTexture1D.new()
	color_ramp.gradient = gradient
	particle_material.color_ramp = color_ramp
	
	# Configure particles
	debris_particles.process_material = particle_material
	debris_particles.amount = int(debris_particles_count * _area_size_ratio) # Adjust according to size
	debris_particles.lifetime = debris_particles_lifetime
	debris_particles.explosiveness = 1.0 # Instant explosion
	debris_particles.randomness = 0.5
	debris_particles.one_shot = true
	debris_particles.texture = _create_debris_particle_texture()
	
	# Start emission
	debris_particles.emitting = true
	
	# Remove after lifetime
	var timer := Timer.new()
	debris_particles.add_child(timer)
	timer.wait_time = debris_particles_lifetime + 0.3
	timer.one_shot = true
	timer.timeout.connect(func(): debris_particles.queue_free())
	timer.start()


func _start_shockwave_animation() -> void:
	if not effect_circle:
		queue_free()
		return
		
	# Show the shockwave
	effect_circle.visible = true
	effect_circle.modulate = shockwave_color
	
	# Apply rotation and skew similar to fire arrow
	effect_circle.rotation = deg_to_rad(32.5)
	rotation = deg_to_rad(0)
	# effect_circle.skew = deg_to_rad(0)
	
	# Start with a very small scale
	effect_circle.scale = Vector2(0.05, 0.05) * _area_size_ratio
	
	# Create expansion animation
	var expand_tween := create_tween()
	expand_tween.set_ease(Tween.EASE_OUT)
	expand_tween.set_trans(Tween.TRANS_QUART)
	
	# Fast expansion then slowdown
	var target_scale := Vector2(1.0, 1.0) * _area_size_ratio
	expand_tween.tween_property(effect_circle, "scale", target_scale, shockwave_duration * 0.7)
	
	# Create fade animation
	var fade_tween := create_tween()
	fade_tween.tween_property(effect_circle, "modulate:a", 0.0, shockwave_duration)
	
	# Wait for animation to finish then destroy
	await fade_tween.finished
	queue_free()


func _on_body_entered(body: Node2D) -> void:
	if not body is IEnemy or _touched_enemy != null or _is_exploding:
		return

	_touched_enemy = body as IEnemy
	var enemy := body as IEnemy
	
	# Use the factorized impact handling
	_handle_impact(enemy)


func _on_aoe_area_body_entered(body: Node2D) -> void:
	if body is IEnemy and not aoe_enemies.has(body):
		aoe_enemies.append(body)


func _on_aoe_area_body_exited(body: Node2D) -> void:
	if body is IEnemy:
		aoe_enemies.erase(body) 
