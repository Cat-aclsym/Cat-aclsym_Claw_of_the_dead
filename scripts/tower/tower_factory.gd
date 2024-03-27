class_name TowerFactory
extends Node2D

@export var tower: PackedScene

func _ready():
	#print("TowerFactory ready")
	var tower_instance = tower.instantiate()
	tower_instance.position = Vector2(0, 0)
	add_child(tower_instance)
