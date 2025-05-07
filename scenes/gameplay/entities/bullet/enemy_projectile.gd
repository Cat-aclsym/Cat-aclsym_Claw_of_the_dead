## © [2024] A7 Studio. All rights reserved. Trademark.
##
## Projectile fired by enemies, targeting towers.
class_name EnemyProjectile
extends Area2D

@export var speed: float = 200.0

var direction: Vector2 = Vector2.ZERO


func _ready() -> void:
	# Connect the collision signal
	body_entered.connect(_on_body_entered)
	# Set a timer to destroy the projectile if it doesn't hit anything
	var lifetime_timer := Timer.new()
	lifetime_timer.wait_time = 5.0 # Projectile lives for 5 seconds
	lifetime_timer.one_shot = true
	lifetime_timer.timeout.connect(queue_free)
	add_child(lifetime_timer)
	lifetime_timer.start()


func _physics_process(delta: float) -> void:
	if Global.paused:
		return
	# Move the projectile
	global_position += direction * speed * delta


func init(_direction: Vector2) -> void:
	"""Initializes the projectile with a direction."""
	direction = _direction
	# Optional: Adjust sprite rotation based on direction if needed
	rotation = direction.angle()


func _on_body_entered(body: Node2D) -> void:
	# Check if the body is a tower
	if body.is_in_group("towers"): # Assumes towers are in the "towers" group
		# Destroy the projectile after hitting a tower
		queue_free()

	# Optional: Check if it hit terrain/obstacles and destroy
	# elif body.is_in_group("obstacles"):
	# 	 queue_free() 