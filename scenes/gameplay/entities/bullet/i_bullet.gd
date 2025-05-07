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

@export_group("Hit Effect")
@export var hit_effect_enabled: bool = true ## Activer l'effet d'impact
@export var hit_particles_count: int = 15 ## Nombre de particules à l'impact
@export var hit_particles_lifetime: float = 0.6 ## Durée de vie des particules d'impact
@export var hit_particles_speed: float = 100.0 ## Vitesse des particules d'impact
@export var hit_particles_size: float = 3.0 ## Taille des particules d'impact
@export var hit_particles_color: Color = Color(0.8, 0.0, 0.0, 0.9) ## Couleur des particules (rouge sang par défaut)
@export var hit_particles_z_index: int = 1000 ## Valeur Z-index pour s'assurer que les particules sont au premier plan

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


func _create_hit_particle_texture() -> Texture2D:
	# Créer une simple texture de particule ronde pour l'effet de sang
	var image_size := 8
	var image := Image.create(image_size, image_size, false, Image.FORMAT_RGBA8)
	
	# Remplir avec de la transparence
	image.fill(Color(0, 0, 0, 0))
	
	# Dessiner un cercle plein pour simuler des gouttes de sang
	var center := Vector2(image_size / 2, image_size / 2)
	var radius := image_size / 2 - 1
	
	for x in range(image_size):
		for y in range(image_size):
			var dist := Vector2(x, y).distance_to(center)
			if dist <= radius:
				# Utiliser du blanc pour la texture (la couleur sera définie par le matériau)
				image.set_pixel(x, y, Color(1, 1, 1, 1))
	
	var texture := ImageTexture.create_from_image(image)
	return texture


func _create_hit_effect(hit_position: Vector2) -> void:
	# Log de débogage pour vérifier que la fonction est bien appelée
	if Global.console:
		Global.console.push_debug("Creating hit effect at position: " + str(hit_position))
	
	# Récupérer la scène actuelle pour y attacher les particules
	var scene_root := get_tree().get_root()
	
	# Créer un système de particules pour l'effet d'impact
	var hit_particles := GPUParticles2D.new()
	scene_root.add_child(hit_particles)
	hit_particles.global_position = hit_position # Utiliser global_position pour garantir la position correcte
	hit_particles.z_index = hit_particles_z_index # Valeur très élevée pour être au premier plan
	
	# Configurer les paramètres de dessin pour garantir que les particules sont au premier plan
	hit_particles.set_meta("_edit_lock_", true) # Éviter les modifications accidentelles
	
	# Créer un CanvasItem personnalisé pour s'assurer que les particules sont dessinées en dernier
	var canvas_item_material := CanvasItemMaterial.new()
	canvas_item_material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	hit_particles.material = canvas_item_material
	
	# Créer le matériau des particules
	var particle_material := ParticleProcessMaterial.new()
	
	# Configurer le matériau pour un effet d'éclaboussure
	particle_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_POINT
	particle_material.direction = Vector3(0, 0, 1)
	particle_material.spread = 180.0 # Émission dans toutes les directions
	particle_material.gravity = Vector3(0, 200.0, 0) # Augmenter la gravité pour un effet plus réaliste
	particle_material.initial_velocity_min = hit_particles_speed * 0.5
	particle_material.initial_velocity_max = hit_particles_speed
	particle_material.scale_min = hit_particles_size * 0.5
	particle_material.scale_max = hit_particles_size
	particle_material.color = hit_particles_color
	particle_material.damping_min = 10.0
	particle_material.damping_max = 30.0
	
	# Créer un gradient pour le fondu
	var gradient := Gradient.new()
	gradient.add_point(0.0, hit_particles_color)
	
	# Point intermédiaire à mi-chemin
	var mid_color := hit_particles_color
	mid_color.a *= 0.7
	gradient.add_point(0.5, mid_color)
	
	# Point final transparent
	var fade_color := hit_particles_color
	fade_color.a = 0.0
	gradient.add_point(1.0, fade_color)
	
	var color_ramp := GradientTexture1D.new()
	color_ramp.gradient = gradient
	particle_material.color_ramp = color_ramp
	
	# Configurer les particules
	hit_particles.process_material = particle_material
	hit_particles.amount = hit_particles_count
	hit_particles.lifetime = hit_particles_lifetime
	hit_particles.explosiveness = 0.95 # Presque instantané pour un effet d'éclaboussure
	hit_particles.randomness = 0.3 # Ajouter de l'aléatoire pour un effet plus naturel
	hit_particles.one_shot = true
	hit_particles.texture = _create_hit_particle_texture()
	
	# Démarrer l'émission
	hit_particles.emitting = true
	
	# Log pour vérifier les paramètres
	if Global.console:
		Global.console.push_debug("Hit particles created with count: " + str(hit_particles_count) + " z_index: " + str(hit_particles.z_index))
	
	# Supprimer les particules après leur durée de vie
	var timer := Timer.new()
	hit_particles.add_child(timer)
	timer.wait_time = hit_particles_lifetime + 0.5 # Ajouter une marge pour être sûr
	timer.one_shot = true
	timer.timeout.connect(func(): 
		# Log de débogage
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
	
	# Log de débogage
	if Global.console:
		Global.console.push_debug("Bullet hit enemy at position: " + str(global_position))
	
	# Apply base damage
	enemy.take_damage(damage, IEnemy.DamageType.DEFAULT)
	
	# Créer l'effet d'éclaboussure de sang au point d'impact
	if hit_effect_enabled:
		# Utiliser les coordonnées globales pour un positionnement correct
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
