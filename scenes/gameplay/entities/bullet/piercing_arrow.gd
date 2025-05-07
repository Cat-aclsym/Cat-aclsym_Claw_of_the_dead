## © [2024] A7 Studio. All rights reserved. Trademark.
##
## Piercing arrow bullet that can pass through multiple enemies.
class_name PiercingArrow
extends IBullet

# Exports
@export var pierce_count: int = 3  ## Number of enemies the bullet can pierce
@export_range(0, 100) var pierce_reduction: int = 10  ## Percentage of damage reduction per enemy pierced

# Variables
var pierced_enemies: Array[IEnemy] = []  # Enemies already pierced
var piercing: int  # Current number of enemies that can be pierced
var initial_piercing: int  # Initial number of enemies that can be pierced

# core
func _ready() -> void:
	super._ready()
	
	# Initialize piercing variables
	piercing = pierce_count
	initial_piercing = pierce_count


func _physics_process(delta: float) -> void:
	if Global.paused:
		return
		
	position += direction * speed * delta


# private
func _on_body_entered(body: Node2D) -> void:
	if not body is IEnemy:
		return
		
	if pierced_enemies.has(body):
		return  # Avoid hitting the same enemy twice
		
	var enemy := body as IEnemy
	pierced_enemies.append(enemy)
	
	# Apply damage
	enemy.take_damage(damage, IEnemy.DamageType.DEFAULT)
	
	# Handle piercing
	piercing -= 1
	
	# Calculate damage reduction
	var enemies_pierced := initial_piercing - piercing
	var remaining_damage_percent: float = 100 - (pierce_reduction * enemies_pierced)
	damage = roundi(initial_damage * (remaining_damage_percent / 100))
	
	# If the piercing limit is reached, destroy the arrow
	if piercing <= 0:
		queue_free()
		return
