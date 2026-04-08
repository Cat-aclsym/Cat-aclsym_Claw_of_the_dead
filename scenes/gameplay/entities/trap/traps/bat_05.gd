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


func _create_explosion_effect(explosion_position: Vector2) -> void:
	var debris_particles: GPUParticles2D = GPUParticles2D.new()
	get_tree().root.add_child(debris_particles)
	debris_particles.global_position = explosion_position
	debris_particles.z_index = 800
	
	var particle_material: ParticleProcessMaterial = ParticleProcessMaterial.new()
	particle_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_POINT
	particle_material.direction = Vector3(0, -1, 0)
	particle_material.spread = 180.0
	particle_material.gravity = Vector3(0, 300.0, 0)
	particle_material.initial_velocity_min = 150.0
	particle_material.initial_velocity_max = 250.0
	particle_material.scale_min = 2.0
	particle_material.scale_max = 4.0
	particle_material.color = Color(1, 0.4, 0.1) # Orange/Fire color
	
	var gradient: Gradient = Gradient.new()
	gradient.add_point(0.0, Color(1, 0.8, 0.2))
	gradient.add_point(0.5, Color(1, 0.2, 0.0))
	gradient.add_point(1.0, Color(0.2, 0.2, 0.2, 0))
	
	var color_ramp: GradientTexture1D = GradientTexture1D.new()
	color_ramp.gradient = gradient
	particle_material.color_ramp = color_ramp
	
	debris_particles.process_material = particle_material
	debris_particles.amount = 30
	debris_particles.lifetime = 0.8
	debris_particles.explosiveness = 1.0
	debris_particles.one_shot = true
	debris_particles.emitting = true
	
	var cleanup_timer: SceneTreeTimer = get_tree().create_timer(1.0)
	cleanup_timer.timeout.connect(func() -> void: if is_instance_valid(debris_particles): debris_particles.queue_free())


func _explode() -> void:
	Log.trace(Log.Level.INFO, "BombTrap exploding at %s" % global_position)
	
	_create_explosion_effect(global_position)
	
	# Find all enemies in range
	var enemies: Array[Node] = get_tree().get_nodes_in_group("enemies")
	for node: Node in enemies:
		if node is IEnemy:
			var enemy: IEnemy = node as IEnemy
			var distance: float = global_position.distance_to(enemy.global_position)
			if distance <= explosion_range:
				enemy.take_damage(damage, IEnemy.DamageType.DEFAULT, self)
	
	# Visual/Audio effects
	# TODO: Add explosion sound when SoundManager supports it
	# if SoundManager:
	# 	SoundManager.play_sfx("explosion")
	
	if Global.camera:
		Global.camera.handle_effect("shake", 15.0)
	
	# Hide sprite during explosion
	$Sprite2D.visible = false
	
	# Wait a bit for particles to be visible before queue_free
	await get_tree().create_timer(1.0).timeout
	
	current_durability = 0
	is_usable = false
	queue_free()
