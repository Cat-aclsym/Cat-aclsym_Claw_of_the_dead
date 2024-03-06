class_name ITower
extends Node2D

enum TargetType {
	FIRST,
	LAST,
	STRONGEST,
	WEAKEST,
	RANDOM
}
enum TowerState {
	BUILDING,
	UPGRADE
}
@export var cost: int
@export var sell_price: int
@export var upgrade: Array[PackedScene] #IUpgrade
@export var level: int
@export var shoot_range: float
@export var fire_rate: float
@export var BulletScene: PackedScene = null

@onready var fire_rate_timer := $FireRateTimer as Timer
@onready var area_2d := $Area2D as Area2D
@onready var collision_shape_2d := $Area2D/CollisionShape2D as CollisionShape2D

var target_type: TargetType
var state: TowerState
var enemy_array: Array[IEnemy]


func _ready():
	state = TowerState.BUILDING
	target_type = TargetType.FIRST
	collision_shape_2d.shape.radius = shoot_range


func _process(_delta: float) -> void:
	if fire_rate_timer.is_stopped():
		fire()


func _on_area_2d_body_entered(body) -> void:
	if body is IEnemy:
		enemy_array.append(body)


func _on_area_2d_body_exited(body) -> void:
	if body is IEnemy:
		enemy_array.erase(body)


func fire() -> void:
	if !len(enemy_array):
		return
	if BulletScene == null:
		return

	var enemy_position: Vector2  = enemy_array[0].global_position
	var bullet_instance: IBullet = BulletScene.instantiate()

	bullet_instance.direction = global_position.direction_to(enemy_position)
	bullet_instance.rotation = bullet_instance.direction.angle()
	bullet_instance.target = enemy_position
	add_child(bullet_instance)
	fire_rate_timer.start()


func upgrade_tower():
	pass


func build_tower():
	pass


func sell_tower():
	pass


func _choose_target():
	pass


func _get_strongest_target():
	pass


func _get_weakest_target():
	pass


func _get_first_target():
	pass


func _get_last_target():
	pass


func _get_random_target():
	pass
