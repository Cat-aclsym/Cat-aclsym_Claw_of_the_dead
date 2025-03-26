## © [2024] A7 Studio. All rights reserved. Trademark.
##
## AOE arrow bullet that deals area damage on impact.
class_name AOEArrow
extends IBullet

# Constants
const AOE_DAMAGE_MULTIPLIER: float = 0.75  # AOE damage is 75% of direct hit damage

# Variables
var aoe_enemies: Array[IEnemy] = []
@onready var aoe_detection_area: Area2D = $AOEArea
@onready var aoe_detection_area_collision: CollisionShape2D = $AOEArea/CollisionShape2D

# Signals
@onready var aoe_signals: Array[Dictionary] = [
	{SignalUtil.WHO: aoe_detection_area, SignalUtil.WHAT: "body_entered", SignalUtil.TO: _on_aoe_area_body_entered},
	{SignalUtil.WHO: aoe_detection_area, SignalUtil.WHAT: "body_exited", SignalUtil.TO: _on_aoe_area_body_exited}
]


# core
func _ready() -> void:
	super._ready()
	is_explosive = true
	
	if aoe_detection_area_collision.shape is CircleShape2D:
		aoe_detection_area_collision.shape.radius = aoe_range
	
	SignalUtil.connects(aoe_signals)


func _physics_process(delta: float) -> void:
	if Global.paused:
		return
		
	position += direction * speed * delta


# private
func _on_body_entered(body: Node2D) -> void:
	if not body is IEnemy or _touched_enemy != null:
		return

	_touched_enemy = body as IEnemy
	var enemy := body as IEnemy
	
	# Apply direct hit damage
	enemy.take_damage(damage, IEnemy.DamageType.DEFAULT)
	
	# Apply AOE damage to nearby enemies
	if is_explosive and len(aoe_enemies) > 0:
		print("Applying AOE damage to ", len(aoe_enemies), " enemies")
		for nearby_enemy in aoe_enemies:
			if nearby_enemy != enemy and is_instance_valid(nearby_enemy):  # Skip the directly hit enemy
				var aoe_damage = roundi(damage * AOE_DAMAGE_MULTIPLIER)
				nearby_enemy.take_damage(aoe_damage, IEnemy.DamageType.DEFAULT)
	
	# Free the bullet after impact
	queue_free()


func _on_aoe_area_body_entered(body: Node2D) -> void:
	if body is IEnemy and not aoe_enemies.has(body):
		aoe_enemies.append(body)
		print("Enemy entered AOE area, total: ", len(aoe_enemies))


func _on_aoe_area_body_exited(body: Node2D) -> void:
	if body is IEnemy:
		aoe_enemies.erase(body)
		print("Enemy exited AOE area, total: ", len(aoe_enemies)) 
