## File:	hud-test.gd.
##
## Author:	Laurie Jeham-Masselot
## Created: 06/03/2024
##
## Scene + method to test call 
## 
class_name HUDTest
extends Control

#Button
var menu_scene: PackedScene = preload("res://scenes/tour-menu/tour-menu.tscn")
var menu_instance: TourMenu = null

var _active: bool = false
@export var speed : float = 5.0
@onready var tower_button_1: TextureButton = $CenterContainer/UiLimit/TowerButton1

#Functionnal
func  _on_tower_button_1_mouse_entered() -> void: 
	_active = true

func _on_tower_button_1_mouse_exited() -> void:
	_active = false
	
# core
func _ready():
	if menu_scene == null:
		print("La scène n'a pas pu être chargée.")
	else:
		print("La scène a été chargée avec succès.")
	
# internal
func _process(delta: float) -> void:
	var color = modulate
	if _active:
		color.a = maxf(color.a - delta * speed, 0.0 + 0.5)
	else:
		color.a = minf(color.a + delta * speed, 1.0)
	modulate = color

# internal 
func _calculer_menu_position() -> Vector2:
	var button_pos = tower_button_1.get_global_rect().position
	var button_size = tower_button_1.get_global_rect().size
	var button_center = button_pos + button_size * 0.5
	var menu_pos = button_center - menu_instance.size * 0.5
	menu_pos.y = max(menu_pos.y, 0)
	return menu_pos
	
# signals

func _on_tower_button_1_pressed() -> void:
	if menu_instance == null:
		menu_instance = menu_scene.instantiate()
		add_child(menu_instance)
		menu_instance.global_position = _calculer_menu_position()
	if (!menu_instance.visible) :
		menu_instance.visible = true
	else :
		menu_instance.visible = false

	
