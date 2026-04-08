## © [2026] A7 Studio. All rights reserved. Trademark.
##
## A trap that explodes when an enemy walks on it, dealing area damage.
class_name Bat05
extends ITrap


## The amount of damage dealt by the explosion
@export var damage: int = 50

## The range of the explosion in pixels. 
## Since tiles are 64x32, a range of 80-100 should cover adjacent tiles.
@export var explosion_range: float = 100.0


# core
func _ready() -> void:
	super()


# public
func apply_effect(_enemy: IEnemy) -> void:
	_explode()


# private
func _apply_trap_stats_extension(base: Dictionary) -> void:
	if base.has("damage"):
		damage = int(base["damage"])
	if base.has("explosion_range"):
		explosion_range = float(base["explosion_range"])


func _create_explosion_effect(explosion_position: Vector2, is_center: bool = true) -> void:
	# 1. Particules de feu
	var fire_particles: GPUParticles2D = GPUParticles2D.new()
	get_tree().root.add_child(fire_particles)
	fire_particles.global_position = explosion_position
	fire_particles.z_index = 801
	
	var fire_material: ParticleProcessMaterial = ParticleProcessMaterial.new()
	fire_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	fire_material.emission_sphere_radius = 3.0 if not is_center else 6.0
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
	fire_particles.amount = 15
	fire_particles.lifetime = 0.4
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
	smoke_material.emission_sphere_radius = 8.0 if not is_center else 12.0
	smoke_material.direction = Vector3(0, -1, 0)
	smoke_material.spread = 45.0
	smoke_material.gravity = Vector3(0, -30.0, 0)
	smoke_material.initial_velocity_min = 15.0
	smoke_material.initial_velocity_max = 40.0
	smoke_material.scale_min = 4.0 if not is_center else 6.0
	smoke_material.scale_max = 8.0 if not is_center else 12.0
	
	var smoke_gradient: Gradient = Gradient.new()
	smoke_gradient.add_point(0.0, Color(0.3, 0.3, 0.3, 0.0)) # Start transparent
	smoke_gradient.add_point(0.2, Color(0.4, 0.4, 0.4, 0.5)) # Fade in
	smoke_gradient.add_point(1.0, Color(0.6, 0.6, 0.6, 0.0)) # Fade out end
	
	var smoke_ramp: GradientTexture1D = GradientTexture1D.new()
	smoke_ramp.gradient = smoke_gradient
	smoke_material.color_ramp = smoke_ramp
	
	smoke_particles.process_material = smoke_material
	smoke_particles.amount = 12 if not is_center else 30
	smoke_particles.lifetime = 1.2 if not is_center else 1.8
	smoke_particles.explosiveness = 0.8
	smoke_particles.one_shot = true
	smoke_particles.emitting = true
	
	# 3. Flash de lumière (uniquement au centre)
	if is_center:
		var flash: Polygon2D = Polygon2D.new()
		get_tree().root.add_child(flash)
		flash.global_position = explosion_position
		flash.z_index = 802
		
		var points: PackedVector2Array = []
		for i in range(32):
			var angle := i * PI * 2 / 32
			points.append(Vector2(cos(angle), sin(angle)) * explosion_range)
		flash.polygon = points
		flash.color = Color(1, 0.9, 0.5, 0.6)
		
		var tween := create_tween()
		tween.tween_property(flash, "scale", Vector2(1.2, 1.2), 0.1)
		tween.parallel().tween_property(flash, "color:a", 0.0, 0.2)
		tween.tween_callback(flash.queue_free)
	
	# Nettoyage
	var cleanup_fire: SceneTreeTimer = get_tree().create_timer(1.0)
	cleanup_fire.timeout.connect(func() -> void: if is_instance_valid(fire_particles): fire_particles.queue_free())
	
	var cleanup_smoke: SceneTreeTimer = get_tree().create_timer(2.0)
	cleanup_smoke.timeout.connect(func() -> void: if is_instance_valid(smoke_particles): smoke_particles.queue_free())


func _explode() -> void:
	Log.trace(Log.Level.INFO, "BombTrap exploding at %s" % global_position)
	
	# 1. Effet central principal
	_create_explosion_effect(global_position, true)
	
	# 2. Identifier les cases adjacentes (range de 1 case)
	# Les tuiles sont en 64x32 (isométrique).
	var adjacent_offsets: Array[Vector2] = [
		Vector2(64, 0), Vector2(-64, 0),   # Droite, Gauche
		Vector2(0, 32), Vector2(0, -32),   # Bas, Haut
		Vector2(32, 16), Vector2(-32, 16), # Diagonales bas
		Vector2(32, -16), Vector2(-32, -16) # Diagonales haut
	]
	
	for offset: Vector2 in adjacent_offsets:
		_create_explosion_effect(global_position + offset, false)
	
	# 3. Infliger les dégâts
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
	
	# Attendre la fin des effets
	await get_tree().create_timer(2.0).timeout
	
	current_durability = 0
	is_usable = false
	queue_free()
