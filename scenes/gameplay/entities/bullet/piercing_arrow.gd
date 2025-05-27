## © [2024] A7 Studio. All rights reserved. Trademark.
##
## Piercing arrow bullet that can pass through multiple enemies.
class_name PiercingArrow
extends IBullet

# exports
@export var pierce_count: int = 3  ## Number of enemies the bullet can pierce
@export_range(0, 100) var pierce_reduction: int = 10  ## Percentage of damage reduction per enemy pierced

@export_group("Pierce Effects")
@export var spark_effect_enabled: bool = true ## Enable spark effect for pierced enemies
@export var spark_particles_count: int = 8 ## Number of spark particles
@export var spark_particles_lifetime: float = 0.3 ## Lifetime of sparks
@export var spark_particles_speed: float = 80.0 ## Speed of sparks
@export var spark_particles_size: float = 1.5 ## Size of sparks
@export var spark_particles_color: Color = Color(1.0, 1.0, 0.7, 0.9) ## Color of sparks (yellow-white)

# public
var pierced_enemies: Array[IEnemy] = []  # Enemies already pierced
var piercing: int  # Current number of enemies that can be pierced
var initial_piercing: int  # Initial number of enemies that can be pierced

# core
func _ready() -> void:
	super._ready()
	
	# Initialize piercing variables
	piercing = pierce_count
	initial_piercing = pierce_count


func _physics_process(delta: float) -> void:
	if Global.paused:
		return
		
	position += direction * speed * delta


# private
func _create_spark_particle_texture() -> Texture2D:
	# Create a spark texture (small 4-pointed star)
	var image_size := 6
	var image := Image.create(image_size, image_size, false, Image.FORMAT_RGBA8)
	
	# Fill with transparency
	image.fill(Color(0, 0, 0, 0))
	
	# Center of the image
	var center := Vector2(image_size / 2, image_size / 2)
	
	# Draw a small 4-pointed star
	var points := PackedVector2Array([
		Vector2(0, center.y),           # Left
		Vector2(image_size - 1, center.y), # Right
		Vector2(center.x, 0),           # Top
		Vector2(center.x, image_size - 1)   # Bottom
	])
	
	# Draw the star lines
	for point in points:
		_draw_spark_line(image, center, point, Color(1, 1, 1, 1))
	
	# Add a brighter central point
	image.set_pixel(center.x as int, center.y as int, Color(1, 1, 1, 1))
	
	var texture := ImageTexture.create_from_image(image)
	return texture


func _draw_spark_line(image: Image, from: Vector2, to: Vector2, color: Color) -> void:
	# Simple line algorithm for sparks
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


func _create_spark_effect(hit_position: Vector2) -> void:
	# Create a spark effect for pierced enemies
	if Global.console:
		Global.console.push_debug("Creating spark effect at position: " + str(hit_position))
	
	var scene_root := get_tree().get_root()
	
	# Create the spark particle system
	var spark_particles := GPUParticles2D.new()
	scene_root.add_child(spark_particles)
	spark_particles.global_position = hit_position
	spark_particles.z_index = 500 # Lower than blood effect but above enemies
	
	# Create the particle material
	var particle_material := ParticleProcessMaterial.new()
	
	# Configure for a spark effect
	particle_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_POINT
	particle_material.direction = Vector3(0, 0, 1)
	particle_material.spread = 120.0 # Narrower than blood effect
	particle_material.gravity = Vector3(0, 50.0, 0) # Light gravity
	particle_material.initial_velocity_min = spark_particles_speed * 0.7
	particle_material.initial_velocity_max = spark_particles_speed
	particle_material.scale_min = spark_particles_size * 0.8
	particle_material.scale_max = spark_particles_size
	particle_material.color = spark_particles_color
	particle_material.damping_min = 30.0
	particle_material.damping_max = 60.0
	
	# Create a gradient for spark fading
	var gradient := Gradient.new()
	gradient.add_point(0.0, spark_particles_color)
	
	var mid_color := spark_particles_color
	mid_color.a *= 0.6
	gradient.add_point(0.4, mid_color)
	
	var fade_color := spark_particles_color
	fade_color.a = 0.0
	gradient.add_point(1.0, fade_color)
	
	var color_ramp := GradientTexture1D.new()
	color_ramp.gradient = gradient
	particle_material.color_ramp = color_ramp
	
	# Configure particles
	spark_particles.process_material = particle_material
	spark_particles.amount = spark_particles_count
	spark_particles.lifetime = spark_particles_lifetime
	spark_particles.explosiveness = 0.9 # Fast emission
	spark_particles.randomness = 0.4
	spark_particles.one_shot = true
	spark_particles.texture = _create_spark_particle_texture()
	
	# Start emission
	spark_particles.emitting = true
	
	# Remove after lifetime
	var timer := Timer.new()
	spark_particles.add_child(timer)
	timer.wait_time = spark_particles_lifetime + 0.2
	timer.one_shot = true
	timer.timeout.connect(func(): spark_particles.queue_free())
	timer.start()


func _on_body_entered(body: Node2D) -> void:
	if not body is IEnemy:
		return
		
	if pierced_enemies.has(body):
		return  # Avoid hitting the same enemy twice
		
	var enemy := body as IEnemy
	pierced_enemies.append(enemy)
	
	# Apply damage
	enemy.take_damage(damage, IEnemy.DamageType.DEFAULT)
	
	# Handle piercing
	piercing -= 1
	
	# Calculate damage reduction
	var enemies_pierced := initial_piercing - piercing
	var remaining_damage_percent: float = 100 - (pierce_reduction * enemies_pierced)
	damage = roundi(initial_damage * (remaining_damage_percent / 100))
	
	# Create appropriate effect depending on whether it's the last enemy or not
	if piercing <= 0:
		# Last enemy: full blood effect (inherited from IBullet)
		if hit_effect_enabled:
			_create_hit_effect(global_position)
		
		# Handle trail like in IBullet
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
		
		# Destroy the arrow
		queue_free()
	else:
		# Pierced enemy: spark effect
		if spark_effect_enabled:
			_create_spark_effect(global_position)
