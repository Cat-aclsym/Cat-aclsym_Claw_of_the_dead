## © [2024] A7 Studio. All rights reserved. Trademark.
##
## Interface for bullet entities.
class_name IBullet
extends Area2D

# exports
@export var damage: int ## Base damage value dealt to enemies	
@export var speed: int ## Speed of the bullet

@export_subgroup("Piercing Properties")
@export var is_piercing: bool ## Whether the bullet can pierce enemies
@export var pierce_count: int ## Number of enemies the bullet can pierce
@export_range(0, 100) var pierce_reduction: int ## Percentage of damage reduction per enemy pierced

@export_subgroup("Area of Effect")
@export var is_explosive: bool ## Whether the bullet can create an area of effect
@export var aoe_range: int ## Range of the area of effect

@export_subgroup("Damage over Time")
@export var has_dot: bool ## Whether the bullet can apply damage over time
@export var dot_damage: int ## Damage per tick
@export var dot_duration: int ## Duration of the damage over time
@export var dot_tick: int ## Number of ticks the damage over time lasts

# public
## Normalized vector indicating bullet's movement direction
var direction: Vector2
## Final destination point for the bullet
var target: Vector2

# private
## Initial damage value to calculate percentage reduction
var initial_damage: int
var piercing: int
## Initial number of enemies that can be pierced
var initial_piercing: int

## Signal connections to be established in _ready
@onready var signals: Array[Dictionary] = [
	{SignalUtil.WHO: self, SignalUtil.WHAT: "body_entered", SignalUtil.TO: _on_body_entered}
]

## Store the enemy that the bullet has touched to prevent multiple hits
var _touched_enemy: IEnemy



# core
func _ready() -> void:
	SignalUtil.connects(signals)
	initial_damage = damage
	piercing = pierce_count
	initial_piercing = pierce_count


func _physics_process(delta: float) -> void:
	if Global.paused:
		return

	position += direction * speed * delta

# private
func _on_body_entered(body: Node2D) -> void:
	if not body is IEnemy or _touched_enemy != null and not is_piercing:
		return

	_touched_enemy = body as IEnemy
	var enemy := body as IEnemy
	
	# Apply base damage
	enemy.take_damage(damage, IEnemy.DamageType.DEFAULT)
	
	# Handle piercing
	if is_piercing:
		piercing -= 1
		var enemies_pierced := initial_piercing - piercing
		var remaining_damage_percent: float = 100 - (pierce_reduction * enemies_pierced)
		damage = roundi(initial_damage * (remaining_damage_percent / 100))
		if piercing <= 0:
			queue_free()
			return
	
	# Handle DoT
	if has_dot:
		enemy.add_poison_effect(dot_damage, dot_duration, dot_tick)
	
	# Free the bullet if it's not piercing
	if not is_piercing:
		queue_free()
