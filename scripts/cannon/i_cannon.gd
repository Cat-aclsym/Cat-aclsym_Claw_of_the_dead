class_name ICannon
extends Node2D


@export var bullet: IBullet
@export var range: float
@export var fire_rate: float
@export var BulletScene: PackedScene = null

var enemy_array: Array[IEnemy]


func upgrade():
	pass # IUpgrade dans argument


func fire():
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






	#if Input.is_action_just_pressed("fire") and :
	#if BulletScene == null: return
	#var mouse_position: Vector2 = get_global_mouse_position()
	#var bullet_instance: IBullet = BulletScene.instantiate()
	#bullet_instance.direction = (mouse_position - global_position).normalized()
	#bullet_instance.rotation = bullet_instance.direction.angle()
	#bullet_instance.target = mouse_position
	#add_child(bullet_instance)
	#
	#bullet_instance.global_position = global_position
	#
	#Log.debug("global_position:")
	#Log.debug(global_position)
	#
	#Log.debug("mouse_position")
	#Log.debug(mouse_position)
	#
	#Log.debug("bullet_instance.global_position")
	#Log.debug(bullet_instance.global_position)


func _process(delta):
	fire()


func _on_area_2d_body_entered(body):
	if body is IEnemy:
		enemy_array.append(body)


func _on_area_2d_body_exited(body):
	if body is IEnemy:
		enemy_array.erase(body)
