## © [2026] A7 Studio. All rights reserved. Trademark.
##
## Interface for bullet entities.
class_name IBullet
extends Area2D

# exports
## Runtime values; balance comes from [method ITower._apply_projectile_config] (tower [code]bullet_stats[/code]). Scenes use 0 for gameplay.
@export var damage: float ## Base damage value dealt to enemies
@export var speed: int ## Speed of the bullet

@export_group("Trail Effect")
@export var trail_enabled: bool = true ## Enable or disable the trail node configured in the scene.

# public
## Normalized vector indicating bullet's movement direction
var direction: Vector2
## Final destination point for the bullet
var target: Vector2
## The tower that fired this bullet
var tower_owner: ITower = null

# private
## Collision shape used to stop the projectile immediately on impact.
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
## Sprite used for the visible projectile.
@onready var sprite_2d: Sprite2D = $Sprite2D
## One-shot smoke burst played when the bullet hits.
@onready var smoke_burst_particles: GPUParticles2D = $SmokeBurstParticles
## Trail particle node configured directly in the scene.
@onready var trail_particles: GPUParticles2D = $TrailParticles

## Initial damage value to calculate percentage reduction
var initial_damage: float
## Guards against duplicate impact callbacks while overlap/animation is still active.
var _has_impacted: bool = false
## Store the enemy that the bullet has touched to prevent multiple hits
var _touched_enemy: IEnemy

# signal
## Signal connections to be established in _ready
@onready var signals: Array[Dictionary] = [
	{SignalUtil.WHO: self, SignalUtil.WHAT: "body_entered", SignalUtil.TO: _on_body_entered}
]

# core
func _ready() -> void:
	assert(is_instance_valid(sprite_2d), "IBullet requires Sprite2D child")
	assert(is_instance_valid(collision_shape_2d), "IBullet requires CollisionShape2D child")
	assert(is_instance_valid(smoke_burst_particles), "IBullet requires SmokeBurstParticles child")
	assert(is_instance_valid(trail_particles), "IBullet requires TrailParticles child")

	SignalUtil.connects(signals)
	initial_damage = damage
	smoke_burst_particles.emitting = false
	trail_particles.local_coords = false
	trail_particles.amount = maxi(trail_particles.amount, 32)
	trail_particles.preprocess = trail_particles.lifetime

	if trail_enabled:
		trail_particles.visible = true
		trail_particles.emitting = true
		trail_particles.restart()
	else:
		_disable_trail()


func _physics_process(delta: float) -> void:
	if Global.paused:
		return

	if trail_enabled and is_instance_valid(trail_particles):
		trail_particles.emitting = true

	position += direction * speed * delta


func _disable_projectile() -> void:
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	set_physics_process(false)
	if is_instance_valid(collision_shape_2d):
		collision_shape_2d.set_deferred("disabled", true)
	if is_instance_valid(sprite_2d):
		sprite_2d.visible = false
	direction = Vector2.ZERO
	speed = 0


func _detach_trail_for_cleanup() -> void:
	if not trail_enabled or not is_instance_valid(trail_particles):
		return

	trail_particles.emitting = false
	trail_particles.reparent(_get_scene_root())
	_queue_free_after(trail_particles, trail_particles.lifetime + 0.1)


func _play_smoke_burst(hit_position: Vector2) -> void:
	if not is_instance_valid(smoke_burst_particles):
		return

	smoke_burst_particles.reparent(_get_scene_root())
	smoke_burst_particles.global_position = hit_position
	smoke_burst_particles.local_coords = false
	smoke_burst_particles.visible = true
	smoke_burst_particles.emitting = true
	smoke_burst_particles.restart()

	var cleanup_timer := get_tree().create_timer(smoke_burst_particles.lifetime + 0.1)
	cleanup_timer.timeout.connect(func():
		if is_instance_valid(smoke_burst_particles):
			smoke_burst_particles.queue_free()
	)


func _get_scene_root() -> Node:
	return get_tree().current_scene if is_instance_valid(get_tree().current_scene) else get_tree().root


func _queue_free_after(node: Node, delay: float) -> void:
	var cleanup_timer := get_tree().create_timer(maxf(delay, 0.05))
	cleanup_timer.timeout.connect(func():
		if is_instance_valid(node):
			node.queue_free()
	)


func _disable_trail() -> void:
	if not is_instance_valid(trail_particles):
		return

	trail_particles.emitting = false
	trail_particles.visible = false


func _on_body_entered(body: Node2D) -> void:
	if _has_impacted or not body is IEnemy or _touched_enemy != null:
		return

	_has_impacted = true

	_touched_enemy = body as IEnemy
	var enemy := body as IEnemy

	# Stop the projectile immediately after impact.
	_disable_projectile()

	# Apply base damage.
	enemy.take_damage(damage, IEnemy.DamageType.DEFAULT, self)

	# Keep the trail visible briefly after the bullet is destroyed.
	_detach_trail_for_cleanup()

	# Play the smoke burst where the bullet touched the enemy.
	_play_smoke_burst(global_position)

	# Free the bullet
	queue_free()
