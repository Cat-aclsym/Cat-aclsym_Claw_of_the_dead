class_name ICannon
extends Node2D

@export var bullet: IBullet
@export var range: float
@export var fire_rate: float

@export var BulletScene: PackedScene = null


func upgrade():
	pass # IUpgrade dans argument

func fire():
	if Input.is_action_just_pressed("fire"):
		var bullet_instance: IBullet = BulletScene.instantiate()
		bullet_instance.position = position
		bullet_instance.direction = (get_viewport().get_mouse_position() - position).normalized()
		bullet_instance.rotation = bullet_instance.direction.angle()
		bullet_instance.target = get_viewport().get_mouse_position()
		add_child(bullet)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	fire()
