## File:	tour_menu.gd.
##
## Author:	Laurie Jeham-Masselot
## Created: 06/03/2024
##
## Methods to call the skill tree
## 

class_name TourMenu
extends Control

#Button

var all_tour_menu: PackedScene = preload("res://scenes/tour-menu/all-menu-tower.tscn")
var menu_scene: PackedScene = preload("res://scenes/tour-menu/tour-menu.tscn")
var menu_instance = null
var is_visible = false

@onready var button_upgrade : TextureButton = $ButtonContainer/TextureRect/HBoxContainer/ButtonUpgrade
@onready var button_quit : TextureButton = $ButtonContainer/TextureRect/QuitButton/Quit

# core
func _ready() -> void:
	if all_tour_menu == null:
		print("La scène n'a pas pu être chargée.")
	else:
		print("La scène a été chargée avec succès.")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

#internal
func _calculer_menu_position() -> Vector2:
	var button_pos = button_upgrade.get_global_rect().position
	var button_size = button_upgrade.get_global_rect().size
	var button_center = button_pos + button_size * 0.5
	var menu_pos = button_center
	menu_pos.y = max(menu_pos.y, 0)
	return menu_pos
	
# signals
func _on_button_upgrade_pressed() -> void:
	if menu_instance == null:
		menu_instance = all_tour_menu.instantiate()
		add_child(menu_instance)
		menu_instance.z_index = 999
		menu_instance.global_position = _calculer_menu_position()
	if (!menu_instance.visible) :
		menu_instance.visible = true
	else :
		menu_instance.visible = false
		
func _on_quit_pressed() -> void:
	self.visible = false
