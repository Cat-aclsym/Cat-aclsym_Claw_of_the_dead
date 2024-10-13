class_name TowerFactory
extends Node2D

@export var tower: PackedScene ## Tower scene to instantiate


# core
## Called when the node enters the scene tree for the first time.
func _ready():
	## Create a new instance of the tower scene
	var tower_instance = tower.instantiate()
	## Set the position of the tower instance to the position of the TowerFactory node
	tower_instance.position = Vector2(0, 0)
	## Add the tower instance as a child of the TowerFactory node
	add_child(tower_instance)


# public


# private


# signal


# event


# setget

