## © [2026] A7 Studio. All rights reserved. Trademark.
##
## A trap that stuns all enemies in range after a 2-second charge-up.
class_name Bat07
extends ITrap


## Duration of the stun effect in seconds.
@export var stun_duration: float = 4.0

## Range of the stun effect in pixels.
@export var stun_range: float = 100.0

## Charge-up time before activation.
@export var charge_time: float = 2.0

## Flag to prevent ITrap from cleaning up during activation
var is_activating: bool = false


# core
func _ready() -> void:
	super()


# public
## Starts the charge-up sequence when an enemy triggers the trap.
func apply_effect(_enemy: IEnemy) -> void:
	if is_usable:
		_start_activation_sequence()


# private
func _apply_trap_stats_extension(base: Dictionary) -> void:
	if base.has("stun_duration"):
		stun_duration = float(base["stun_duration"])
	if base.has("stun_range"):
		stun_range = float(base["stun_range"])
	if base.has("charge_time"):
		charge_time = float(base["charge_time"])


func _create_stun_visual_effect(pos: Vector2, is_center: bool = true) -> void:
	var particles: GPUParticles2D = GPUParticles2D.new()
	get_tree().root.add_child(particles)
	particles.global_position = pos
	particles.z_index = 801
	
	var material: ParticleProcessMaterial = ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = 5.0 if not is_center else 10.0
	material.direction = Vector3(0, -1, 0)
	material.spread = 180.0
	material.gravity = Vector3(0, 0, 0)
	material.initial_velocity_min = 30.0
	material.initial_velocity_max = 60.0
	material.scale_min = 2.0
	material.scale_max = 4.0
	
	var gradient: Gradient = Gradient.new()
	gradient.add_point(0.0, Color(1.0, 1.0, 0.0, 1.0))
	gradient.add_point(1.0, Color(1.0, 1.0, 0.0, 0.0))
	
	var ramp: GradientTexture1D = GradientTexture1D.new()
	ramp.gradient = gradient
	material.color_ramp = ramp
	
	particles.process_material = material
	particles.amount = 15 if not is_center else 30
	particles.lifetime = 0.5
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.emitting = true
	
	get_tree().create_timer(1.0).timeout.connect(func() -> void: if is_instance_valid(particles): particles.queue_free())


func _start_activation_sequence() -> void:
	is_usable = false # Prevent multiple triggers
	is_activating = true # Tell ITrap to wait
	
	# 1. Créer le cercle de chargement
	var circle: Polygon2D = Polygon2D.new()
	add_child(circle)
	circle.z_index = -1
	circle.color = Color(1.0, 1.0, 0.0, 0.2) # Jaune très faible opacité
	
	# Création des points du cercle (isométrique)
	var points: PackedVector2Array = []
	var segments: int = 32
	for i in range(segments + 1):
		var angle := i * PI * 2 / segments
		points.append(Vector2(cos(angle) * stun_range, sin(angle) * (stun_range / 2.0)))
	circle.polygon = points
	
	# 2. Animation de remplissage (échelle de 0 à 1)
	circle.scale = Vector2.ZERO
	var tween: Tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_QUAD)
	
	# Le cercle grandit pendant 2 secondes
	tween.tween_property(circle, "scale", Vector2.ONE, charge_time)
	
	# Une fois rempli, on déclenche l'effet
	tween.finished.connect(func() -> void:
		# 3. Déclenchement de l'effet
		circle.color.a = 0.6 # Augmenter l'opacité lors de l'activation (full visuel)
		_trigger_stun()
		
		# 4. On garde le cercle et le piège pendant la durée du stun
		# Puis on fait disparaître le tout
		var cleanup_timer := get_tree().create_timer(stun_duration)
		cleanup_timer.timeout.connect(func() -> void:
			var fade_tween: Tween = create_tween()
			fade_tween.set_parallel(true)
			fade_tween.tween_property(circle, "modulate:a", 0.0, 0.5)
			fade_tween.tween_property(self, "modulate:a", 0.0, 0.5)
			fade_tween.finished.connect(queue_free)
		)
	)


func _trigger_stun() -> void:
	Log.trace(Log.Level.INFO, "StunTrap triggering at %s" % global_position)
	
	# 1. Effets visuels sur la zone
	_create_stun_visual_effect(global_position, true)
	
	var adjacent_offsets: Array[Vector2] = [
		Vector2(64, 0), Vector2(-64, 0),
		Vector2(0, 32), Vector2(0, -32),
		Vector2(32, 16), Vector2(-32, 16),
		Vector2(32, -16), Vector2(-32, -16)
	]
	
	for offset: Vector2 in adjacent_offsets:
		_create_stun_visual_effect(global_position + offset, false)
	
	# 2. Stun les ennemis présents
	var enemies: Array[Node] = get_tree().get_nodes_in_group("enemies")
	var hit_count: int = 0
	for node: Node in enemies:
		if node is IEnemy:
			var enemy: IEnemy = node as IEnemy
			var distance: float = global_position.distance_to(enemy.global_position)
			if distance <= stun_range:
				enemy.stun(stun_duration)
				hit_count += 1
	
	# 3. On ne cache plus le sprite ici, on attend la fin du stun (géré dans _start_activation_sequence)
	current_durability = 0
	is_activating = false # Sequence finished, but durability is 0 so it will wait for cleanup_timer
	
	# Si personne n'a été touché, on pourrait accélérer la disparition, 
	# mais pour la lisibilité visuelle, on garde le comportement uniforme.
