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
@export var trail_fade_curve: float = 0.4 ## Contrôle la rapidité du fondu (plus petit = plus rapide)
@export var trail_thickness: int = 2 ## Épaisseur des branches de l'étoile

# public
## Normalized vector indicating bullet's movement direction
var direction: Vector2
## Final destination point for the bullet
var target: Vector2

# private
## Initial damage value to calculate percentage reduction
var initial_damage: int
## Trail particle system
var _trail_particles: GPUParticles2D

## Signal connections to be established in _ready
@onready var signals: Array[Dictionary] = [
	{SignalUtil.WHO: self, SignalUtil.WHAT: "body_entered", SignalUtil.TO: _on_body_entered}
]

## Store the enemy that the bullet has touched to prevent multiple hits
var _touched_enemy: IEnemy


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
	
	# Ajouter plusieurs points pour créer une courbe de fondu plus douce
	gradient.add_point(0.0, trail_color)
	
	# Point intermédiaire pour ralentir le début du fondu
	var mid_color = trail_color
	mid_color.a = trail_color.a * 0.8
	gradient.add_point(trail_fade_curve, mid_color)
	
	# Point intermédiaire pour accélérer la fin du fondu
	var late_color = trail_color
	late_color.a = trail_color.a * 0.3
	gradient.add_point(0.7, late_color)
	
	# Point final complètement transparent
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
	var center := Vector2(image_size / 2, image_size / 2)
	
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
	# Dessiner la ligne principale
	_draw_line(image, from, to, color)
	
	# Ajouter de l'épaisseur en dessinant des lignes parallèles
	var half_thick := thickness / 2
	
	# Calculer le vecteur perpendiculaire à la ligne
	var direction := (to - from).normalized()
	var perpendicular := Vector2(-direction.y, direction.x)
	
	# Dessiner des lignes parallèles pour créer l'épaisseur
	for i in range(1, half_thick + 1):
		var offset := perpendicular * i
		
		# Ligne au-dessus
		_draw_line(image, from + offset, to + offset, color)
		
		# Ligne en-dessous
		_draw_line(image, from - offset, to - offset, color)
	
	# Arrondir les extrémités
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
	# Algorithme de cercle simplifié pour de petits rayons
	var x0: int = center.x as int
	var y0: int = center.y as int
	
	for x in range(x0 - radius, x0 + radius + 1):
		for y in range(y0 - radius, y0 + radius + 1):
			# Vérifier si le pixel est dans le cercle
			if (x - x0) * (x - x0) + (y - y0) * (y - y0) <= radius * radius:
				if x >= 0 and y >= 0 and x < image.get_width() and y < image.get_height():
					image.set_pixel(x, y, color)


func _on_body_entered(body: Node2D) -> void:
	if not body is IEnemy or _touched_enemy != null:
		return

	_touched_enemy = body as IEnemy
	var enemy := body as IEnemy
	
	# Apply base damage
	enemy.take_damage(damage, IEnemy.DamageType.DEFAULT)
	
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
