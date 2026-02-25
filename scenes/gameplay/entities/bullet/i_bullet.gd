## © [2024] A7 Studio. All rights reserved. Trademark.
##
## Interface for bullet entities.
class_name IBullet
extends Area2D

# exports
@export var damage: int ## Base damage value dealt to enemies
@export var speed: int ## Speed of the bullet

@export_group("Trail Effect")
@export var trail_enabled: bool = true ## Enable/disable trail effect
@export var trail_lifetime: float = 0.5 ## How long trail particles last
@export var trail_amount: int = 12 ## Number of particles in the trail
@export var trail_color: Color = Color(1.0, 1.0, 1.0, 0.7) ## Color of the trail particles
@export var trail_fade_out: bool = true ## Whether particles should fade out over lifetime
@export var trail_size: float = 0.5 ## Size scale of the trail particles
@export var trail_fade_curve: float = 0.4 ## Controls fade speed (smaller = faster)
@export var trail_thickness: int = 2 ## Thickness of star branches

@export_group("Hit Effect")
@export var hit_effect_enabled: bool = true ## Enable hit impact effect
@export var hit_particles_count: int = 15 ## Number of particles on impact
@export var hit_particles_lifetime: float = 0.6 ## Lifetime of impact particles
@export var hit_particles_speed: float = 100.0 ## Speed of impact particles
@export var hit_particles_size: float = 3.0 ## Size of impact particles
@export var hit_particles_color: Color = Color(0.8, 0.0, 0.0, 0.9) ## Color of particles (blood red by default)
@export var hit_particles_z_index: int = 1000 ## Z-index value to ensure particles are in foreground

# public
## Normalized vector indicating bullet's movement direction
var direction: Vector2
## Final destination point for the bullet
var target: Vector2
## The tower that fired this bullet
var tower_owner: ITower = null

# private
## Initial damage value to calculate percentage reduction
var initial_damage: int
## Trail particle system
var _trail_particles: GPUParticles2D
## Store the enemy that the bullet has touched to prevent multiple hits
var _touched_enemy: IEnemy

# signal
## Signal connections to be established in _ready
@onready var signals: Array[Dictionary] = [
	{SignalUtil.WHO: self, SignalUtil.WHAT: "body_entered", SignalUtil.TO: _on_body_entered}
]

# core
func _ready() -> void:
	SignalUtil.connects(signals)
	initial_damage = damage

	if trail_enabled:
		_setup_trail()


func _physics_process(delta: float) -> void:
	if Global.paused:
		return

	position += direction * speed * delta


# private
func _setup_trail() -> void:
	# Create particles node
	_trail_particles = GPUParticles2D.new()
	add_child(_trail_particles)

	# Create particle material
	var particle_material = ParticleProcessMaterial.new()

	# Configure material
	particle_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_POINT
	particle_material.direction = Vector3(0, 0, 0)
	particle_material.spread = 0
	particle_material.gravity = Vector3(0, 0, 0)
	particle_material.initial_velocity_min = 0
	particle_material.initial_velocity_max = 0
	particle_material.color = trail_color
	particle_material.scale_min = trail_size
	particle_material.scale_max = trail_size

	if trail_fade_out:
		particle_material.color_ramp = _create_fade_gradient()

	# Configure particles
	_trail_particles.process_material = particle_material
	_trail_particles.amount = trail_amount
	_trail_particles.lifetime = trail_lifetime
	_trail_particles.local_coords = false
	_trail_particles.emitting = true

	# Create a star-shaped texture for particles
	var texture = _create_star_particle_texture()
	_trail_particles.texture = texture


func _create_fade_gradient() -> Gradient:
	# Create a gradient for fading out with a curve
	var gradient = Gradient.new()

	# Add multiple points to create a smoother fade curve
	gradient.add_point(0.0, trail_color)

	# Intermediate point to slow down the beginning of the fade
	var mid_color = trail_color
	mid_color.a = trail_color.a * 0.8
	gradient.add_point(trail_fade_curve, mid_color)

	# Intermediate point to accelerate the end of the fade
	var late_color = trail_color
	late_color.a = trail_color.a * 0.3
	gradient.add_point(0.7, late_color)

	# Final point completely transparent
	var transparent_color = trail_color
	transparent_color.a = 0.0
	gradient.add_point(1.0, transparent_color)

	var ramp = GradientTexture1D.new()
	ramp.gradient = gradient
	return gradient


func _create_star_particle_texture() -> Texture2D:
	# Create a 4-pointed star texture for particles
	var image_size := 8  # Reduced from 16 to 8 for smaller texture
	var image := Image.create(image_size, image_size, false, Image.FORMAT_RGBA8)

	# Fill with transparent
	image.fill(Color(0, 0, 0, 0))

	# Center point
	var center := Vector2(image_size / 2.0, image_size / 2.0)

	# Draw 4-pointed star
	var points := PackedVector2Array([
		# Horizontal points
		Vector2(0, center.y),
		Vector2(image_size, center.y),
		# Vertical points
		Vector2(center.x, 0),
		Vector2(center.x, image_size)
	])

	# Draw thicker lines for each arm of the star
	for point in points:
		_draw_thick_line(image, center, point, Color(1, 1, 1, 1), trail_thickness)

	var texture := ImageTexture.create_from_image(image)
	return texture


func _draw_thick_line(image: Image, from: Vector2, to: Vector2, color: Color, thickness: int) -> void:
	# Draw the main line
	_draw_line(image, from, to, color)

	# Add thickness by drawing parallel lines
	var half_thick := thickness / 2.0

	# Calculate the perpendicular vector to the line
	var direction := (to - from).normalized()
	var perpendicular := Vector2(-direction.y, direction.x)

	# Draw parallel lines to create thickness
	for i in range(1, half_thick + 1):
		var offset := perpendicular * i

		# Line above
		_draw_line(image, from + offset, to + offset, color)

		# Line below
		_draw_line(image, from - offset, to - offset, color)

	# Round the ends
	if thickness > 1:
		_draw_circle(image, from, half_thick, color)
		_draw_circle(image, to, half_thick, color)


func _draw_line(image: Image, from: Vector2, to: Vector2, color: Color) -> void:
	# Simple Bresenham line algorithm
	var dx: int = abs(to.x - from.x)
	var dy: int = -abs(to.y - from.y)
	var sx: int = 1 if from.x < to.x else -1
	var sy: int = 1 if from.y < to.y else -1
	var err: int = dx + dy

	var x: int = from.x as int
	var y: int = from.y as int

	while true:
		if x >= 0 and y >= 0 and x < image.get_width() and y < image.get_height():
			image.set_pixel(x, y, color)

		if x == to.x and y == to.y:
			break

		var e2: int = 2 * err
		if e2 >= dy:
			if x == to.x:
				break
			err += dy
			x += sx

		if e2 <= dx:
			if y == to.y:
				break
			err += dx
			y += sy


func _draw_circle(image: Image, center: Vector2, radius: int, color: Color) -> void:
	# Simplified circle algorithm for small radii
	var x0: int = center.x as int
	var y0: int = center.y as int

	for x in range(x0 - radius, x0 + radius + 1):
		for y in range(y0 - radius, y0 + radius + 1):
			# Check if the pixel is inside the circle
			if (x - x0) * (x - x0) + (y - y0) * (y - y0) <= radius * radius:
				if x >= 0 and y >= 0 and x < image.get_width() and y < image.get_height():
					image.set_pixel(x, y, color)


func _create_hit_particle_texture() -> Texture2D:
	# Create a simple round particle texture for blood effect
	var image_size := 8
	var image := Image.create(image_size, image_size, false, Image.FORMAT_RGBA8)

	# Fill with transparency
	image.fill(Color(0, 0, 0, 0))

	# Draw a filled circle to simulate blood drops
	var center := Vector2(image_size / 2, image_size / 2)
	var radius := image_size / 2 - 1

	for x in range(image_size):
		for y in range(image_size):
			var dist := Vector2(x, y).distance_to(center)
			if dist <= radius:
				# Use white for the texture (color will be defined by the material)
				image.set_pixel(x, y, Color(1, 1, 1, 1))

	var texture := ImageTexture.create_from_image(image)
	return texture


func _create_hit_effect(hit_position: Vector2) -> void:
	# Debug log to verify the function is called
	if Global.console:
		Global.console.push_debug("Creating hit effect at position: " + str(hit_position))

	# Get the current scene to attach particles to
	var scene_root := get_tree().get_root()

	# Create a particle system for the impact effect
	var hit_particles := GPUParticles2D.new()
	scene_root.add_child(hit_particles)
	hit_particles.global_position = hit_position # Use global_position to guarantee correct position
	hit_particles.z_index = hit_particles_z_index # Very high value to be in foreground

	# Configure drawing parameters to ensure particles are in foreground
	hit_particles.set_meta("_edit_lock_", true) # Avoid accidental modifications

	# Create a custom CanvasItem to ensure particles are drawn last
	var canvas_item_material := CanvasItemMaterial.new()
	canvas_item_material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	hit_particles.material = canvas_item_material

	# Create the particle material
	var particle_material := ParticleProcessMaterial.new()

	# Configure the material for a splash effect
	particle_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_POINT
	particle_material.direction = Vector3(0, 0, 1)
	particle_material.spread = 180.0 # Emission in all directions
	particle_material.gravity = Vector3(0, 200.0, 0) # Increase gravity for more realistic effect
	particle_material.initial_velocity_min = hit_particles_speed * 0.5
	particle_material.initial_velocity_max = hit_particles_speed
	particle_material.scale_min = hit_particles_size * 0.5
	particle_material.scale_max = hit_particles_size
	particle_material.color = hit_particles_color
	particle_material.damping_min = 10.0
	particle_material.damping_max = 30.0

	# Create a gradient for fading
	var gradient := Gradient.new()
	gradient.add_point(0.0, hit_particles_color)

	# Intermediate point at halfway
	var mid_color := hit_particles_color
	mid_color.a *= 0.7
	gradient.add_point(0.5, mid_color)

	# Final transparent point
	var fade_color := hit_particles_color
	fade_color.a = 0.0
	gradient.add_point(1.0, fade_color)

	var color_ramp := GradientTexture1D.new()
	color_ramp.gradient = gradient
	particle_material.color_ramp = color_ramp

	# Configure particles
	hit_particles.process_material = particle_material
	hit_particles.amount = hit_particles_count
	hit_particles.lifetime = hit_particles_lifetime
	hit_particles.explosiveness = 0.95 # Almost instant for splash effect
	hit_particles.randomness = 0.3 # Add randomness for more natural effect
	hit_particles.one_shot = true
	hit_particles.texture = _create_hit_particle_texture()

	# Start emission
	hit_particles.emitting = true

	# Log to verify parameters
	if Global.console:
		Global.console.push_debug("Hit particles created with count: " + str(hit_particles_count) + " z_index: " + str(hit_particles.z_index))

	# Remove particles after their lifetime
	var timer := Timer.new()
	hit_particles.add_child(timer)
	timer.wait_time = hit_particles_lifetime + 0.5 # Add margin to be sure
	timer.one_shot = true
	timer.timeout.connect(func():
		# Debug log
		if Global.console:
			Global.console.push_debug("Removing hit particles")
		hit_particles.queue_free()
	)
	timer.start()


func _on_body_entered(body: Node2D) -> void:
	if not body is IEnemy or _touched_enemy != null:
		return

	_touched_enemy = body as IEnemy
	var enemy := body as IEnemy

	# Debug log
	if Global.console:
		Global.console.push_debug("Bullet hit enemy at position: " + str(global_position))

	# Apply base damage
	enemy.take_damage(damage, IEnemy.DamageType.DEFAULT, self)

	# Create blood splash effect at impact point
	if hit_effect_enabled:
		# Use global coordinates for correct positioning
		_create_hit_effect(global_position)

	if trail_enabled and is_instance_valid(_trail_particles):
		# Stop emitting but allow existing particles to finish
		_trail_particles.emitting = false

		# Need to reparent to ensure particles finish their lifetime
		remove_child(_trail_particles)
		get_parent().add_child(_trail_particles)

		# Setup timer to free the particles after they're done
		var timer = Timer.new()
		_trail_particles.add_child(timer)
		timer.wait_time = trail_lifetime + 0.1
		timer.one_shot = true
		timer.timeout.connect(func(): _trail_particles.queue_free())
		timer.start()

	# Free the bullet
	queue_free()
