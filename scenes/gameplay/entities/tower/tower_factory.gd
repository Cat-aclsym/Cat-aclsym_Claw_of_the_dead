## © [2024] A7 Studio. All rights reserved. Trademark.
##
## Factory for creating tower instances.
class_name TowerFactory
extends Node2D

## The tower scene to be instantiated
@export var tower: PackedScene

# core
## Called when the node enters the scene tree.
## Creates and positions a new tower instance.
func _ready() -> void:
	var tower_instance := _create_tower()
	_setup_tower(tower_instance)

# private
## Creates a new instance of the tower.
## Returns: The newly created tower instance.
func _create_tower() -> ITower:
	assert(tower != null, "Tower scene must be set")
	return tower.instantiate() as ITower

## Sets up the initial tower position and adds it to the scene.
## [param tower_instance] The tower instance to setup.
func _setup_tower(tower_instance: ITower) -> void:
	tower_instance.position = Vector2.ZERO
	add_child(tower_instance)
