## © [2026] A7 Studio. All rights reserved. Trademark.
##
## Manages the home screen interface and menu navigation.
## Handles level selection and options menu access.
class_name Home
extends Control

var _armory_menu_instance: Node = null
var _encyclopedia_menu_instance: Encyclopedia
var _levels_menu_instance: LevelSelectionMenu
var _option_menu_instance: Options

@onready var armory_button: TextureButton = %ArmoryButton
@onready var encyclopedia_button: TextureButton = %EncyclopediaButton
@onready var encyclopedia_exclamation: TextureRect = %EncyclopediaExclamation
@onready var gui_margin_container: MarginContainer = $GuiMarginContainer
@onready var play_button: TextureButton = %PlayButton
@onready var settings_button: TextureButton = %SettingsButton

@onready var _armory_menu: PackedScene = preload("res://scenes/ui/menus/armory/armory.tscn")
@onready var _encyclopedia_menu: PackedScene = preload("res://scenes/ui/menus/hud/encyclopedia.tscn")
@onready var _levels_menu: PackedScene = preload("res://scenes/ui/menus/level_selection/level_selection_menu.tscn")
@onready var _option_menu: PackedScene = preload("res://scenes/ui/menus/options/options.tscn")

@onready var signals: Array[Dictionary] = [
	{SignalUtil.WHO: armory_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_armory_button_pressed},
	{SignalUtil.WHO: encyclopedia_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_encyclopedia_button_pressed},
	{SignalUtil.WHO: settings_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_parameter_button_pressed},
	{SignalUtil.WHO: play_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_play_button_pressed},
]

# core
func _ready() -> void:
	assert(armory_button != null, "armory_button node not found")
	assert(encyclopedia_button != null, "encyclopedia_button node not found")
	assert(encyclopedia_exclamation != null, "encyclopedia_exclamation node not found")
	assert(gui_margin_container != null, "gui_margin_container node not found")
	assert(play_button != null, "play_button node not found")
	assert(settings_button != null, "settings_button node not found")
	assert(_armory_menu != null, "armory_menu scene not found")
	assert(_levels_menu != null, "levels_menu scene not found")
	assert(_option_menu != null, "option_menu scene not found")
	SignalUtil.connects(signals)
	_update_encyclopedia_notification()
	
	ButtonEffects.apply(armory_button)
	ButtonEffects.apply(encyclopedia_button)
	ButtonEffects.apply(play_button)
	ButtonEffects.apply(settings_button)

# private
## Handles the armory button press event.
func _on_armory_button_pressed() -> void:
	gui_margin_container.visible = false
	_armory_menu_instance = _armory_menu.instantiate()
	add_child(_armory_menu_instance)
	_armory_menu_instance.menu_close.connect(_on_menu_close.bind(_armory_menu_instance))


## Handles the encyclopedia button press event.
## [br]Shows the encyclopedia menu and sets up its callback.
func _on_encyclopedia_button_pressed() -> void:
	gui_margin_container.visible = false
	_encyclopedia_menu_instance = _encyclopedia_menu.instantiate() as Encyclopedia
	add_child(_encyclopedia_menu_instance)
	_encyclopedia_menu_instance.menu_close.connect(_on_menu_close.bind(_encyclopedia_menu_instance))


## Handles level selection events.
func _on_level_selected() -> void:
	_on_menu_close(_levels_menu_instance)
	visible = false


## Handles menu close events.
## [br]Restores the main container visibility and cleans up the menu.
## [param menu] The menu instance to close
func _on_menu_close(menu: Control) -> void:
	gui_margin_container.visible = true
	menu.queue_free()
	_update_encyclopedia_notification()


## Handles the parameter button press event.
## [br]Shows the options menu and sets up its callback.
func _on_parameter_button_pressed() -> void:
	gui_margin_container.visible = false
	_option_menu_instance = _option_menu.instantiate() as Options
	add_child(_option_menu_instance)
	_option_menu_instance.menu_close.connect(_on_menu_close.bind(_option_menu_instance))


## Handles the play button press event.
## [br]Shows the level selection menu and sets up its callbacks.
func _on_play_button_pressed() -> void:
	gui_margin_container.visible = false

	_levels_menu_instance = _levels_menu.instantiate() as LevelSelectionMenu
	add_child(_levels_menu_instance)

	SignalUtil.connects([
		{SignalUtil.WHO: _levels_menu_instance, SignalUtil.WHAT: "level_selected", SignalUtil.TO: _on_level_selected},
	])


## Updates the encyclopedia notification icon visibility.
func _update_encyclopedia_notification() -> void:
	encyclopedia_exclamation.visible = ProgressionManager.has_unseen_encyclopedia_enemies() or ProgressionManager.has_unseen_encyclopedia_towers()
