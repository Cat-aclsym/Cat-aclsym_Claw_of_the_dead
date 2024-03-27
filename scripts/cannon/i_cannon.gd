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
		if BulletScene == null: return
		var mouse_position: Vector2 = get_global_mouse_position()
		var bullet_instance: IBullet = BulletScene.instantiate()
		bullet_instance.direction = (mouse_position - global_position).normalized()
		bullet_instance.rotation = bullet_instance.direction.angle()
		bullet_instance.target = mouse_position
		add_child(bullet_instance)
		
		bullet_instance.global_position = global_position
		
		Log.debug("global_position:")
		Log.debug(global_position)
		
		Log.debug("mouse_position")
		Log.debug(mouse_position)

		Log.debug("bullet_instance.global_position")
		Log.debug(bullet_instance.global_position)

func _process(delta):
	fire()


func _on_menu_button_pressed():
	pass # Replace with function body.


func serialize() -> Dictionary:
	var bullets_data = [] # Liste pour stocker les données sérialisées des balles
	for child in get_children():
		if child is IBullet: # Vérifie si l'enfant est une instance de IBullet
			var bullet_data = {
				"direction": {"x": child.direction.x, "y": child.direction.y},
				"speed": child.speed,
				"damage": child.damage,
				"target": {"x": child.target.x, "y": child.target.y},
				"position": {"x": child.global_position.x, "y": child.global_position.y}
			}
			bullets_data.append(bullet_data)
	return {
		"type": get_class(),
		"bullet": bullets_data, # ou une propriété spécifique de bullet pour la sérialisation
		"range": range,
		"fire_rate": fire_rate,
		"BulletScene": BulletScene if BulletScene == null else BulletScene.get_path(),
		"position": {"x": global_position.x, "y": global_position.y}, # sauvegarder la position si nécessaire
		# Ajoutez d'autres propriétés si nécessaire
	}
