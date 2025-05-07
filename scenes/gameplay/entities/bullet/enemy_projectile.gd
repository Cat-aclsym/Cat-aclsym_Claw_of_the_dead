## © [2024] A7 Studio. All rights reserved. Trademark.
##
## Projectile fired by enemies, targeting towers.
class_name EnemyProjectile
extends Area2D

@export var speed: float = 200.0

var direction: Vector2 = Vector2.ZERO
var disable_duration: float = 3.0


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


func init(_direction: Vector2, _disable_duration: float = 3.0) -> void:
	"""Initializes the projectile with a direction and disable duration.
	
	Args:
		_direction: The direction the projectile will travel
		_disable_duration: How long the tower will be disabled when hit
	"""
	direction = _direction
	disable_duration = _disable_duration
	# Adjust sprite rotation based on direction
	rotation = direction.angle()


func _on_body_entered(body: Node2D) -> void:
	# Check if the body is a tower
	if body.is_in_group("towers"): # Assumes towers are in the "towers" group
		# Get the parent tower node
		var tower = body.get_parent()
		if tower is ITower:
			# Disable the tower
			_disable_tower(tower)
		
		# Destroy the projectile after hitting a tower
		queue_free()

	# Optional: Check if it hit terrain/obstacles and destroy
	# elif body.is_in_group("obstacles"):
	# 	 queue_free() 


func _disable_tower(tower: ITower) -> void:
	"""Disables a tower for the specified duration.
	
	Args:
		tower: The tower to disable
	"""
	# Don't do anything if the tower already has a disable timer
	if tower.has_meta("is_disabled") and tower.get_meta("is_disabled") == true:
		return
		
	# Mark tower as disabled
	tower.set_meta("is_disabled", true)
	
	# Create unique ID for this timer
	var timer_name = "DisableTimer"
	
	# Remove any existing disable timer
	if tower.has_node(timer_name):
		tower.get_node(timer_name).queue_free()
	
	# Create a new timer for the disabled state
	var disabled_timer := Timer.new()
	disabled_timer.name = timer_name
	disabled_timer.wait_time = disable_duration
	disabled_timer.one_shot = true
	tower.add_child(disabled_timer)
	
	# Store the original modulate color
	var original_modulate = tower.sprite_2d.modulate
	
	# Visually indicate the tower is disabled by reducing opacity
	tower.sprite_2d.modulate = Color(original_modulate.r, original_modulate.g, 
		original_modulate.b, 0.5)
	
	# Functionally disable the tower
	tower.fire_rate_timer.stop()
	tower.set_process(false)
	
	# Re-enable the tower when the timer expires
	disabled_timer.timeout.connect(func():
		# Reset visual appearance
		tower.sprite_2d.modulate = original_modulate
		
		# Restore functionality
		tower.set_process(true)
		
		# Reset the fire rate timer to allow the tower to resume firing
		if is_instance_valid(tower) and is_instance_valid(tower.fire_rate_timer):
			tower.fire_rate_timer.start()
			
		# Mark tower as enabled
		tower.set_meta("is_disabled", false)
		
		# Clean up the timer
		if is_instance_valid(disabled_timer):
			disabled_timer.queue_free()
	)
	
	# Start the disable timer
	disabled_timer.start() 