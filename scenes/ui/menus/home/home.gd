## © [2026] A7 Studio. All rights reserved. Trademark.
##
## Manages the home screen interface and menu navigation.
## Handles level selection and options menu access.
class_name Home
extends Control

const _ARMORY_MENU: PackedScene = preload("res://scenes/ui/menus/armory/armory.tscn")
const _DEBUG_STATS_MENU: PackedScene = preload("res://scenes/ui/debug/stats_icons_debug.tscn")
const _ENCYCLOPEDIA_MENU: PackedScene = preload("res://scenes/ui/menus/hud/encyclopedia.tscn")
const _LEVELS_MENU: PackedScene = preload("res://scenes/ui/menus/level_selection/level_selection_menu.tscn")
const _OPTION_MENU: PackedScene = preload("res://scenes/ui/menus/options/options.tscn")

var _armory_menu_instance: Node = null
var _debug_stats_menu_instance: Node = null
var _encyclopedia_menu_instance: Encyclopedia
var _levels_menu_instance: LevelSelectionMenu
var _option_menu_instance: Options

@onready var armory_button: Button = %ArmoryButton
@onready var debug_stats_button: Button = %DebugStatsButton
@onready var encyclopedia_button: Button = %EncyclopediaButton
@onready var encyclopedia_exclamation: TextureRect = %EncyclopediaExclamation
@onready var gui_margin_container: MarginContainer = $GuiMarginContainer
@onready var play_button: Button = %PlayButton
@onready var settings_button: Button = %SettingsButton

@onready var signals: Array[Dictionary] = [
	{SignalUtil.WHO: debug_stats_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_debug_stats_button_pressed},
	{SignalUtil.WHO: armory_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_armory_button_pressed},
	{SignalUtil.WHO: encyclopedia_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_encyclopedia_button_pressed},
	{SignalUtil.WHO: settings_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_parameter_button_pressed},
	{SignalUtil.WHO: play_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_play_button_pressed},
]

@onready var _default_armory_text: String = armory_button.text
@onready var _default_encyclopedia_text: String = encyclopedia_button.text

# core
func _ready() -> void:
	assert(armory_button != null, "armory_button node not found")
	assert(debug_stats_button != null, "debug_stats_button node not found")
	assert(encyclopedia_button != null, "encyclopedia_button node not found")
	assert(encyclopedia_exclamation != null, "encyclopedia_exclamation node not found")
	assert(gui_margin_container != null, "gui_margin_container node not found")
	assert(play_button != null, "play_button node not found")
	assert(settings_button != null, "settings_button node not found")
	SignalUtil.connects(signals)
	_update_first_play_home_lock_state()
	_update_encyclopedia_notification()

	if Global.debug:
		debug_stats_button.visible = true

# private
## Handles the armory button press event.
func _on_armory_button_pressed() -> void:
	gui_margin_container.visible = false
	_armory_menu_instance = _ARMORY_MENU.instantiate()
	add_child(_armory_menu_instance)
	SignalUtil.connects([{SignalUtil.WHO: _armory_menu_instance, SignalUtil.WHAT: "menu_close", SignalUtil.TO: _on_menu_close.bind(_armory_menu_instance)}])


## Opens the stats icons debug overlay. Only reachable when [member Global.debug] is true.
func _on_debug_stats_button_pressed() -> void:
	gui_margin_container.visible = false
	_debug_stats_menu_instance = _DEBUG_STATS_MENU.instantiate()
	add_child(_debug_stats_menu_instance)
	SignalUtil.connects([{SignalUtil.WHO: _debug_stats_menu_instance, SignalUtil.WHAT: "menu_close", SignalUtil.TO: _on_menu_close.bind(_debug_stats_menu_instance)}])


## Handles the encyclopedia button press event.
## [br]Shows the encyclopedia menu and sets up its callback.
func _on_encyclopedia_button_pressed() -> void:
	gui_margin_container.visible = false
	_encyclopedia_menu_instance = _ENCYCLOPEDIA_MENU.instantiate() as Encyclopedia
	add_child(_encyclopedia_menu_instance)
	SignalUtil.connects([{SignalUtil.WHO: _encyclopedia_menu_instance, SignalUtil.WHAT: "menu_close", SignalUtil.TO: _on_menu_close.bind(_encyclopedia_menu_instance)}])


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
	_update_first_play_home_lock_state()
	_update_encyclopedia_notification()


## Handles the parameter button press event.
## [br]Shows the options menu and sets up its callback.
func _on_parameter_button_pressed() -> void:
	gui_margin_container.visible = false
	_option_menu_instance = _OPTION_MENU.instantiate() as Options
	add_child(_option_menu_instance)
	SignalUtil.connects([{SignalUtil.WHO: _option_menu_instance, SignalUtil.WHAT: "menu_close", SignalUtil.TO: _on_menu_close.bind(_option_menu_instance)}])


## Handles the play button press event.
## [br]Shows the level selection menu and sets up its callbacks.
func _on_play_button_pressed() -> void:
	if not ProgressionManager.is_tutorial_completed():
		if await ScenesLoader.start_level("lev.01") != null:
			gui_margin_container.visible = false
			visible = false
		return

	gui_margin_container.visible = false

	_levels_menu_instance = _LEVELS_MENU.instantiate() as LevelSelectionMenu
	add_child(_levels_menu_instance)

	SignalUtil.connects([
		{SignalUtil.WHO: _levels_menu_instance, SignalUtil.WHAT: "level_selected", SignalUtil.TO: _on_level_selected},
	])


func _set_button_locked(button: Button, is_locked: bool, unlocked_text: String) -> void:
	button.disabled = is_locked
	button.modulate = Color(0.45, 0.45, 0.45, 1.0) if is_locked else Color.WHITE
	button.text = "?" if is_locked else unlocked_text


## Updates the encyclopedia notification icon visibility.
func _update_encyclopedia_notification() -> void:
	if not ProgressionManager.is_tutorial_completed():
		encyclopedia_exclamation.visible = false
		return
	encyclopedia_exclamation.visible = ProgressionManager.has_unseen_encyclopedia_enemies() or ProgressionManager.has_unseen_encyclopedia_towers()


func _update_first_play_home_lock_state() -> void:
	var is_locked: bool = not ProgressionManager.is_tutorial_completed()
	_set_button_locked(armory_button, is_locked, _default_armory_text)
	_set_button_locked(encyclopedia_button, is_locked, _default_encyclopedia_text)
