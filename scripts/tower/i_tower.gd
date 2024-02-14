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
@export var damage: int
@export var cannon: PackedScene #ICannon

var target_type: TargetType
var state: TowerState


func _ready():
	state = TowerState.BUILDING
	target_type = TargetType.FIRST
	var cannon_instance = cannon.instantiate()
	cannon_instance.position = Vector2(0, 0)
	add_child(cannon_instance)


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
