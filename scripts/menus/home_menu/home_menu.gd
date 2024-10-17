## © [2024] A7 Studio. All rights reserved. Trademark.
## File: home_menu.gd
##Home screen for the game
##It launch the levels selection menu or the option menu
##
##Author: Matéo Perrot--Nasi
##Created: 24/01/2024
##
class_name HomeMenu
extends Control

@onready var gui_margin_container: MarginContainer = $GuiMarginContainer
@onready var levels_menu: PackedScene = preload("res://scenes/menus/levels_menu/levels_menu.tscn")
@onready var option_menu: PackedScene =  preload("res://scenes/menus/option_menu/option_menu.tscn")

var levels_menu_instance: LevelsMenu
var option_menu_instance: OptionMenu

# core


# public


# private


# signal
func _on_play_button_pressed():
	gui_margin_container.visible = false

	levels_menu_instance = levels_menu.instantiate()
	add_child(levels_menu_instance)
	levels_menu_instance.menu_close.connect(_on_menu_close.bind(levels_menu_instance))
	levels_menu_instance.level_selected.connect(
	func() -> void:
		_on_menu_close(levels_menu_instance)
		visible = false
	)

func _on_parameter_button_pressed():
	gui_margin_container.visible = false
	option_menu_instance = option_menu.instantiate()
	add_child(option_menu_instance)
	option_menu_instance.menu_close.connect(_on_menu_close.bind(option_menu_instance))


func _on_menu_close(menu: Control):
	gui_margin_container.visible = true
	menu.queue_free()


# event


# setget
