class_name ICannon
extends Node2D


@export var range: float
@export var fire_rate: float
@export var BulletScene: PackedScene = null

@onready var fire_rate_timer := $FireRateTimer as Timer

var enemy_array: Array[IEnemy]

func upgrade():
	pass # IUpgrade dans argument


func fire() -> void:
	if !len(enemy_array):
		return

	if BulletScene == null:
		return

	var enemy_position: Vector2 = enemy_array[0].global_position
	var bullet_instance: IBullet = BulletScene.instantiate()

	bullet_instance.direction = global_position.direction_to(enemy_position)
	bullet_instance.rotation = bullet_instance.direction.angle()
	bullet_instance.target = enemy_position
	add_child(bullet_instance)
	fire_rate_timer.start()


func _process(_delta: float) -> void:
	if fire_rate_timer.is_stopped():
		fire()


func _on_area_2d_body_entered(body) -> void:
	if body is IEnemy:
		enemy_array.append(body)


func _on_area_2d_body_exited(body) -> void:
	if body is IEnemy:
		enemy_array.erase(body)
