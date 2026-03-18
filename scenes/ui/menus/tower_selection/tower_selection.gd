## © [2025] A7 Studio. All rights reserved. Trademark.
##
## Manages the tower construction selection menu interface and functionality.
class_name TowerSelection
extends Control

## Construction menu nodes
@onready var construction_menu: HBoxContainer = $MarginContainer/BackgroundTextureRect/TowerListMarginContainer/HBoxContainer
@onready var construction_anim_player: AnimationPlayer = $AnimationPlayer

# Called when the node enters the scene tree for the first time.
func _ready():
	assert(construction_menu != null, "construction_menu node not found")
	assert(construction_anim_player != null, "construction_anim_player node not found")

	construction_anim_player.animation_finished.connect(
	func(_name: String) -> void:
		if _name == "RESET" and construction_menu.visible:
			construction_menu.visible = false
	)
	construction_menu.visible = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float):
	if is_queued_for_deletion():
		toggle_build_menu()

# public

## Toggles the build menu visibility with animation.
## [br]Updates tower cards when showing the menu.
func toggle_build_menu() -> void:
	if construction_menu.visible:
		Log.trace(Log.Level.INFO, "Hiding construction menu")
		construction_anim_player.play("RESET")
	else:
		Log.trace(Log.Level.INFO, "Showing construction menu")
		construction_anim_player.play("show_tower_list")
		construction_menu.visible = true
		return
