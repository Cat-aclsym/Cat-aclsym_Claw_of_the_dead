class_name IBullet
extends Area2D


@export var speed: int
@export var damage: int
@export var direction: Vector2
@export var target: Vector2


func _init():
	pass


func _physics_process(delta: float):
	position += direction * speed * delta

	if global_position.distance_to(target) < 100:
		#print("Target: ", target)
		#print("Global Position: ", global_position)
		queue_free()


func _on_body_entered(body):
	if body is IEnemy:
		print("zadazd")
		body._take_damage(damage)
		queue_free()

func serialize() -> Dictionary:
	return {
		"type": get_class(),
		"speed": speed,
		"damage": damage,
		"direction": direction,
		"target": target,
		"position": {"x": global_position.x, "y": global_position.y}, # sauvegarder la position si nécessaire
		# Ajoutez d'autres propriétés si nécessaire
	}
