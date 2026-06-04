## © [2026] A7 Studio. All rights reserved. Trademark.
##
## Manages the home screen interface and menu navigation.
## Handles level selection and options menu access.
class_name Home
extends Control

const _DEBUG_STATS_MENU: PackedScene = preload("res://scenes/ui/debug/stats_icons_debug.tscn")

var _armory_menu_instance: Node = null
var _debug_stats_menu_instance: Node = null
var _encyclopedia_menu_instance: Encyclopedia
var _levels_menu_instance: LevelSelectionMenu
var _option_menu_instance: Options

const _LEVEL_SCENE_PATH_TEMPLATE: String = "res://scenes/gameplay/world/level/levels/%s.tscn"

@onready var armory_button: TextureButton = %ArmoryButton
@onready var armory_label: Label = $GuiMarginContainer/GuiHBoxContainer/HomeScreenVBoxContainer/ArmoryButton/ArmoryLabel
@onready var debug_stats_button: Button = %DebugStatsButton
@onready var encyclopedia_button: TextureButton = %EncyclopediaButton
@onready var encyclopedia_exclamation: TextureRect = %EncyclopediaExclamation
@onready var encyclopedia_label: Label = $GuiMarginContainer/GuiHBoxContainer/HomeScreenVBoxContainer/EncyclopediaButton/EncyclopediaLabel
@onready var gui_margin_container: MarginContainer = $GuiMarginContainer
@onready var play_button: TextureButton = %PlayButton
@onready var settings_button: TextureButton = %SettingsButton

@onready var _default_armory_text: String = armory_label.text
@onready var _default_encyclopedia_text: String = encyclopedia_label.text

@onready var _armory_menu: PackedScene = preload("res://scenes/ui/menus/armory/armory.tscn")
@onready var _encyclopedia_menu: PackedScene = preload("res://scenes/ui/menus/hud/encyclopedia.tscn")
@onready var _levels_menu: PackedScene = preload("res://scenes/ui/menus/level_selection/level_selection_menu.tscn")
@onready var _option_menu: PackedScene = preload("res://scenes/ui/menus/options/options.tscn")

@onready var signals: Array[Dictionary] = [
	{SignalUtil.WHO: debug_stats_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_debug_stats_button_pressed},
	{SignalUtil.WHO: armory_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_armory_button_pressed},
	{SignalUtil.WHO: encyclopedia_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_encyclopedia_button_pressed},
	{SignalUtil.WHO: settings_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_parameter_button_pressed},
	{SignalUtil.WHO: play_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_play_button_pressed},
]

# core
func _ready() -> void:
	assert(armory_button != null, "armory_button node not found")
	assert(armory_label != null, "armory_label node not found")
	assert(debug_stats_button != null, "debug_stats_button node not found")
	assert(encyclopedia_button != null, "encyclopedia_button node not found")
	assert(encyclopedia_exclamation != null, "encyclopedia_exclamation node not found")
	assert(encyclopedia_label != null, "encyclopedia_label node not found")
	assert(gui_margin_container != null, "gui_margin_container node not found")
	assert(play_button != null, "play_button node not found")
	assert(settings_button != null, "settings_button node not found")
	assert(_armory_menu != null, "armory_menu scene not found")
	assert(_levels_menu != null, "levels_menu scene not found")
	assert(_option_menu != null, "option_menu scene not found")
	SignalUtil.connects(signals)
	_update_first_play_home_lock_state()
	_update_encyclopedia_notification()

	ButtonEffects.apply(armory_button)
	ButtonEffects.apply(encyclopedia_button)
	ButtonEffects.apply(play_button)
	ButtonEffects.apply(settings_button)
	if Global.debug:
		debug_stats_button.visible = true

# private
## Opens the stats icons debug overlay. Only reachable when [member Global.debug] is true.
func _on_debug_stats_button_pressed() -> void:
	gui_margin_container.visible = false
	_debug_stats_menu_instance = _DEBUG_STATS_MENU.instantiate()
	add_child(_debug_stats_menu_instance)
	_debug_stats_menu_instance.menu_close.connect(_on_menu_close.bind(_debug_stats_menu_instance))


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
	_update_first_play_home_lock_state()
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
	if not ProgressionManager.is_tutorial_completed():
		_start_level_direct("lev.01")
		return

	gui_margin_container.visible = false

	_levels_menu_instance = _levels_menu.instantiate() as LevelSelectionMenu
	add_child(_levels_menu_instance)

	SignalUtil.connects([
		{SignalUtil.WHO: _levels_menu_instance, SignalUtil.WHAT: "level_selected", SignalUtil.TO: _on_level_selected},
	])


## Starts a level directly from its id without going through level selection.
## [param level_id] Target level id (e.g. "lev.01")
func _start_level_direct(level_id: String) -> void:
	var level_scene_path: String = _LEVEL_SCENE_PATH_TEMPLATE % level_id
	var level_scene: PackedScene = load(level_scene_path)
	if level_scene == null:
		Log.trace(Log.Level.ERROR, "Failed to load level scene: %s" % level_scene_path)
		return

	var level_instance: ILevel = level_scene.instantiate() as ILevel
	if level_instance == null:
		Log.trace(Log.Level.ERROR, "Failed to instantiate ILevel from scene: %s" % level_scene_path)
		return

	gui_margin_container.visible = false
	visible = false

	get_tree().get_root().add_child(level_instance)
	level_instance.start_level()
	Global.ui.start_level()


## Updates the encyclopedia notification icon visibility.
func _update_encyclopedia_notification() -> void:
	if not ProgressionManager.is_tutorial_completed():
		encyclopedia_exclamation.visible = false
		return
	encyclopedia_exclamation.visible = ProgressionManager.has_unseen_encyclopedia_enemies() or ProgressionManager.has_unseen_encyclopedia_towers()


func _set_button_locked(button: TextureButton, label: Label, is_locked: bool, unlocked_text: String) -> void:
	button.disabled = is_locked
	button.modulate = Color(0.45, 0.45, 0.45, 1.0) if is_locked else Color.WHITE
	label.text = "?" if is_locked else unlocked_text


func _update_first_play_home_lock_state() -> void:
	var is_locked: bool = not ProgressionManager.is_tutorial_completed()
	_set_button_locked(armory_button, armory_label, is_locked, _default_armory_text)
	_set_button_locked(encyclopedia_button, encyclopedia_label, is_locked, _default_encyclopedia_text)
