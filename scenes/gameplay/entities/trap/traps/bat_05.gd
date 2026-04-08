## © [2026] A7 Studio. All rights reserved. Trademark.
##
## A trap that explodes when an enemy walks on it, dealing area damage after a 2-second delay.
class_name Bat05
extends ITrap


## The amount of damage dealt by the explosion
@export var damage: int = 50

## The range of the explosion in pixels. 
## Since tiles are 64x32, a range of 80-100 should cover adjacent tiles.
@export var explosion_range: float = 100.0

## Delay before explosion after trigger
@export var explosion_delay: float = 2.0

## Flag to prevent ITrap from cleaning up during activation
var is_activating: bool = false


# core
func _ready() -> void:
	super()


# public
## Starts the explosion sequence when an enemy triggers the trap.
func apply_effect(_enemy: IEnemy) -> void:
	if is_usable:
		_start_explosion_sequence()


# private
func _apply_trap_stats_extension(base: Dictionary) -> void:
	if base.has("damage"):
		damage = int(base["damage"])
	if base.has("explosion_range"):
		explosion_range = float(base["explosion_range"])
	if base.has("explosion_delay"):
		explosion_delay = float(base["explosion_delay"])


func _create_explosion_effect(explosion_position: Vector2, is_center: bool = true) -> void:
	# 1. Particules de feu (plus nombreuses pour couvrir le cercle)
	var fire_particles: GPUParticles2D = GPUParticles2D.new()
	get_tree().root.add_child(fire_particles)
	fire_particles.global_position = explosion_position
	fire_particles.z_index = 801
	
	var fire_material: ParticleProcessMaterial = ParticleProcessMaterial.new()
	fire_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	# On utilise le rayon d'explosion pour l'émission
	fire_material.emission_sphere_radius = explosion_range * 0.8
	fire_material.direction = Vector3(0, -1, 0)
	fire_material.spread = 45.0
	fire_material.gravity = Vector3(0, 0, 0)
	fire_material.initial_velocity_min = 40.0
	fire_material.initial_velocity_max = 80.0
	fire_material.scale_min = 2.0
	fire_material.scale_max = 4.0
	
	var fire_gradient: Gradient = Gradient.new()
	fire_gradient.add_point(0.0, Color(1, 0.9, 0.2, 1.0)) # Jaune opaque
	fire_gradient.add_point(0.4, Color(1, 0.4, 0.0, 0.8)) # Orange commence à fader
	fire_gradient.add_point(1.0, Color(1, 0.4, 0.0, 0.0)) # Orange totalement transparent
	
	var fire_ramp: GradientTexture1D = GradientTexture1D.new()
	fire_ramp.gradient = fire_gradient
	fire_material.color_ramp = fire_ramp
	
	fire_particles.process_material = fire_material
	fire_particles.amount = 80 # Plus de particules pour remplir le cercle
	fire_particles.lifetime = 0.5
	fire_particles.explosiveness = 1.0
	fire_particles.one_shot = true
	fire_particles.emitting = true
	
	# 2. Particules de fumée
	var smoke_particles: GPUParticles2D = GPUParticles2D.new()
	get_tree().root.add_child(smoke_particles)
	smoke_particles.global_position = explosion_position
	smoke_particles.z_index = 800
	
	var smoke_material: ParticleProcessMaterial = ParticleProcessMaterial.new()
	smoke_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	smoke_material.emission_sphere_radius = explosion_range
	smoke_material.direction = Vector3(0, -1, 0)
	smoke_material.spread = 45.0
	smoke_material.gravity = Vector3(0, -30.0, 0)
	smoke_material.initial_velocity_min = 15.0
	smoke_material.initial_velocity_max = 40.0
	smoke_material.scale_min = 4.0
	smoke_material.scale_max = 10.0
	
	var smoke_gradient: Gradient = Gradient.new()
	smoke_gradient.add_point(0.0, Color(0.3, 0.3, 0.3, 0.0)) # Start transparent
	smoke_gradient.add_point(0.2, Color(0.4, 0.4, 0.4, 0.5)) # Fade in
	smoke_gradient.add_point(1.0, Color(0.6, 0.6, 0.6, 0.0)) # Fade out end
	
	var smoke_ramp: GradientTexture1D = GradientTexture1D.new()
	smoke_ramp.gradient = smoke_gradient
	smoke_material.color_ramp = smoke_ramp
	
	smoke_particles.process_material = smoke_material
	smoke_particles.amount = 60
	smoke_particles.lifetime = 1.5
	smoke_particles.explosiveness = 0.8
	smoke_particles.one_shot = true
	smoke_particles.emitting = true
	
	# 3. Flash de lumière (uniquement au centre)
	if is_center:
		# Suppression du Polygon2D qui créait un cercle persistant
		pass
	
	# Nettoyage
	var cleanup_fire: SceneTreeTimer = get_tree().create_timer(1.0)
	cleanup_fire.timeout.connect(func() -> void: if is_instance_valid(fire_particles): fire_particles.queue_free())
	
	var cleanup_smoke: SceneTreeTimer = get_tree().create_timer(2.0)
	cleanup_smoke.timeout.connect(func() -> void: if is_instance_valid(smoke_particles): smoke_particles.queue_free())


func _explode() -> void:
	Log.trace(Log.Level.INFO, "BombTrap exploding at %s" % global_position)
	
	# 1. Effet d'explosion circulaire
	_create_explosion_effect(global_position, true)
	
	# 2. Infliger les dégâts aux ennemis dans le cercle
	var enemies: Array[Node] = get_tree().get_nodes_in_group("enemies")
	for node: Node in enemies:
		if node is IEnemy:
			var enemy: IEnemy = node as IEnemy
			var distance: float = global_position.distance_to(enemy.global_position)
			if distance <= explosion_range:
				enemy.take_damage(damage, IEnemy.DamageType.DEFAULT, self)
	
	# Visual/Audio effects
	if Global.camera:
		Global.camera.handle_effect("shake", 15.0)
	
	# Masquer le sprite
	$Sprite2D.visible = false
	current_durability = 0
	is_usable = false
	is_activating = false
	
	# Attendre la fin des effets avant de supprimer
	await get_tree().create_timer(2.0).timeout
	queue_free()


func _start_explosion_sequence() -> void:
	is_usable = false
	is_activating = true
	
	# 1. Créer le cercle d'alerte (isométrique)
	var circle: Polygon2D = Polygon2D.new()
	add_child(circle)
	circle.z_index = -1
	circle.color = Color(1.0, 0.2, 0.1, 0.3) # Rouge/Orange transparent
	
	var points: PackedVector2Array = []
	var segments: int = 32
	for i in range(segments + 1):
		var angle := i * PI * 2 / segments
		points.append(Vector2(cos(angle) * explosion_range, sin(angle) * (explosion_range / 2.0)))
	circle.polygon = points
	
	# 2. Animation de clignotement
	var blink_tween: Tween = create_tween()
	blink_tween.set_loops(6) # Clignote 6 fois en 2 secondes
	blink_tween.tween_property(circle, "modulate:a", 0.8, 0.15)
	blink_tween.tween_property(circle, "modulate:a", 0.3, 0.15)
	
	# 3. Attendre le délai
	var timer := get_tree().create_timer(explosion_delay)
	timer.timeout.connect(func() -> void:
		if is_instance_valid(blink_tween):
			blink_tween.kill()
		if is_instance_valid(circle):
			circle.queue_free()
		_explode()
	)
