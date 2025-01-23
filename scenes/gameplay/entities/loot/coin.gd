## © [2024] A7 Studio. All rights reserved. Trademark.
##
## Represents a collectable coin that appears when enemies die.
class_name Coin
extends Area2D

signal collected(coin: Coin)

@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var popup_spawner: PopupSpawner = $PopupSpawner
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var value: int = 1
var is_collected: bool = false

# core
func _ready() -> void:
	# Ensure coin is visible above map
	z_index = 100
	
	# Spawn animation
	scale = Vector2.ZERO
	modulate.a = 0
	var spawn_tween = create_tween()
	spawn_tween.set_parallel(true)
	spawn_tween.tween_property(self, "scale", Vector2.ONE, 0.3)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)
	spawn_tween.tween_property(self, "modulate:a", 1.0, 0.2)
	
	# Start despawn timer
	var timer := get_tree().create_timer(25.0)
	timer.timeout.connect(_on_warning_timeout)
	
	var despawn_timer := get_tree().create_timer(30.0)
	despawn_timer.timeout.connect(queue_free)

func _input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and not is_collected:
		Log.trace(Log.Level.INFO, "Coin clicked at position: %s" % global_position)
		collect()

# public
func collect() -> void:
	if is_collected:
		Log.trace(Log.Level.INFO, "Coin already collected, ignoring")
		return
		
	is_collected = true
	collision_shape.set_deferred("disabled", true)
	
	Log.trace(Log.Level.INFO, "Collecting coin at position: %s" % global_position)
	
	# Ensure coin is above everything, including UI
	z_index = 4096
	
	# Create collect effect
	_create_collect_effect()
	
	# Show popup
	popup_spawner.score("+%d" % value)
	
	# Animate coin to HUD
	var tween := create_tween()
	var target_pos: Vector2 = Global.ui.get_node("HUD").get_coin_counter_position()
	
	# Animation plus lente et avec easing + scale
	tween.set_parallel(true)
	tween.tween_property(self, "global_position", target_pos, 1.0)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "scale", Vector2.ZERO, 1.0)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(func():
		sprite.visible = false
		collected.emit(self)
		queue_free()
	)

# private
func _create_collect_effect() -> void:
	var particles := GPUParticles2D.new()
	add_child(particles)
	particles.z_index = 4096
	
	# Create particle material
	var material := ParticleProcessMaterial.new()
	material.particle_flag_disable_z = true
	material.spread = 180.0
	material.gravity = Vector3.ZERO
	material.initial_velocity_min = 15.0
	material.initial_velocity_max = 30.0
	material.scale_min = 3.0
	material.scale_max = 5.0
	material.damping_min = 30.0
	material.damping_max = 30.0
	material.color = Color(1, 0.85, 0, 1)
	
	# Ajoute un fade out
	var gradient := Gradient.new()
	gradient.add_point(0.0, Color(1, 0.85, 0, 1))  # Début : jaune doré opaque
	gradient.add_point(0.7, Color(1, 0.85, 0, 1))  # Reste opaque jusqu'à 70%
	gradient.add_point(1.0, Color(1, 0.85, 0, 0))  # Fin : transparent
	
	var gradient_texture := GradientTexture1D.new()
	gradient_texture.gradient = gradient
	material.color_ramp = gradient_texture
	
	# Setup particles
	particles.amount = 8
	particles.lifetime = 0.5
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.process_material = material
	particles.emitting = true
	
	# Auto cleanup
	await get_tree().create_timer(0.5).timeout
	particles.queue_free()

func _on_warning_timeout() -> void:
	animation_player.play("warning")

# Méthode non-statique pour nettoyer les pièces
func cleanup_all_coins() -> void:
	# Trouve toutes les pièces dans la scène et les supprime
	for coin in get_tree().get_nodes_in_group("coins"):
		coin.queue_free()
