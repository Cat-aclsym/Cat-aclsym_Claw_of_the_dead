## File: home_menu.gd
##Home screen for the game
##It launch the levels selection menu or the option menu
##
##Author: Matéo Perrot--Nasi
##Created: 24/01/2024
##
class_name HomeScreen
extends Control

@onready var option_menu: PackedScene =  preload("res://scenes/menus/option_menu/option_menu.tscn")
@onready var levels_menu: PackedScene = preload("res://scenes/menus/levels_menu/levels_menu.tscn")
@onready var gui_margin_container: MarginContainer = $GuiMarginContainer

func _on_play_button_pressed():
	get_tree().get_root().add_child(levels_menu.instantiate())
	queue_free()

func _on_parameter_button_pressed():
	gui_margin_container.visible = false
	var option_menu_child: Node = option_menu.instantiate()
	add_child(option_menu_child)
	option_menu_child.menu_option_close.connect(_on_menu_option_close)


func _on_menu_option_close():
	gui_margin_container.visible = true
