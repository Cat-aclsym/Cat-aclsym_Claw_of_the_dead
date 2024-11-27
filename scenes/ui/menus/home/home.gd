## © [2024] A7 Studio. All rights reserved. Trademark.
##
## Manages the home screen interface and menu navigation.
## Handles level selection and options menu access.
class_name HomeMenu
extends Control

var _levels_menu_instance: LevelsMenu
var _option_menu_instance: OptionMenu

@onready var gui_margin_container: MarginContainer = $GuiMarginContainer
@onready var play_button: TextureButton = $GuiMarginContainer/GuiHBoxContainer/HomeScreenVBoxContainer/PlayMarginContainer/PlayButton
@onready var settings_button: TextureButton = $GuiMarginContainer/GuiHBoxContainer/HomeScreenVBoxContainer/SettingsMarginContainer/SettingsButton
@onready var _levels_menu: PackedScene = preload("res://scenes/ui/menus/level_selection/level_selection.tscn")
@onready var _option_menu: PackedScene = preload("res://scenes/ui/menus/options/options.tscn")

@onready var signals: Array[Dictionary] = [
	{SignalUtil.WHO: play_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_play_button_pressed},
	{SignalUtil.WHO: settings_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_parameter_button_pressed},
]

# core
func _ready() -> void:
	assert(gui_margin_container != null, "gui_margin_container node not found")
	assert(_levels_menu != null, "levels_menu scene not found")
	assert(_option_menu != null, "option_menu scene not found")
	SignalUtil.connects(signals)

# private
## Handles the play button press event.
## [br]Shows the level selection menu and sets up its callbacks.
func _on_play_button_pressed() -> void:
	gui_margin_container.visible = false

	_levels_menu_instance = _levels_menu.instantiate()
	add_child(_levels_menu_instance)

	SignalUtil.connects([
		{SignalUtil.WHO: _levels_menu_instance, SignalUtil.WHAT: "menu_close", SignalUtil.TO: _on_menu_close},
		{SignalUtil.WHO: _levels_menu_instance, SignalUtil.WHAT: "level_selected", SignalUtil.TO: _on_level_selected},
	])

## Handles the parameter button press event.
## [br]Shows the options menu and sets up its callback.
func _on_parameter_button_pressed() -> void:
	gui_margin_container.visible = false
	_option_menu_instance = _option_menu.instantiate()
	add_child(_option_menu_instance)
	_option_menu_instance.menu_close.connect(_on_menu_close.bind(_option_menu_instance))

## Handles menu close events.
## [br]Restores the main container visibility and cleans up the menu.
## [param menu] The menu instance to close
func _on_menu_close(menu: Control) -> void:
	gui_margin_container.visible = true
	menu.queue_free()

## Handles level selection events.
func _on_level_selected() -> void:
	_on_menu_close(_levels_menu_instance)
	visible = false
