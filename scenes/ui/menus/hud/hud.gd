## © [2024] A7 Studio. All rights reserved. Trademark.
##
## Manages the in-game HUD interface and its components.
## Handles resource displays, wave counters, and construction menu.
class_name HUD
extends Control

const PAUSE_MENU: PackedScene = preload("res://scenes/ui/menus/pause/pause.tscn")
const TOWER_SELECTION_MENU: PackedScene = preload("res://scenes/ui/menus/tower_selection/tower_selection.tscn")
const DEFAULT_TIME_SCALE: float = 1.0
const FAST_TIME_SCALE: float = 2.0
const FASTEST_TIME_SCALE: float = 4.0

## The flag indicating if the HUD is ready to display.
var _is_ready: bool = false

## Resources with values nodes
@onready var coins_rich_text_label: Label = $HUDMarginContainer/HUDVBoxContainer/CoinsWavesMarginContainer/CoinsWavesHBoxContainer/CoinsTextureRect/MarginContainer/CoinsLabel
@onready var health_rich_text_label: Label = $HUDMarginContainer/HUDVBoxContainer/HeartTextureRect/HealthMarginContainer/MarginContainer/HealthTextureProgressBar/HealthLabel
@onready var waves_rich_text_label: Label = $HUDMarginContainer/HUDVBoxContainer/CoinsWavesMarginContainer/CoinsWavesHBoxContainer/WavesTextureRect/MarginContainer/WavesLabel
@onready var default_coins_text: String = coins_rich_text_label.text
@onready var default_health_text: String = health_rich_text_label.text
@onready var default_waves_text: String = waves_rich_text_label.text

## Nodes for resources display
@onready var health_texture_progress_bar: TextureProgressBar = $HUDMarginContainer/HUDVBoxContainer/HeartTextureRect/HealthMarginContainer/MarginContainer/HealthTextureProgressBar
@onready var new_wave_count_label: Label = $NewWaveCountLabel

## HUD buttons
@onready var pause_button: TextureButton = $MarginContainer/PauseButton
@onready var tower_selection_button: TextureButton = $TowerSelectionMarginContainer/TowerSelectionButton
@onready var time_scale_1x_button: Button = $TimeScaleMarginContainer/TimeScaleHBoxContainer/TimeScale1xButton
@onready var time_scale_2x_button: Button = $TimeScaleMarginContainer/TimeScaleHBoxContainer/TimeScale2xButton
@onready var time_scale_4x_button: Button = $TimeScaleMarginContainer/TimeScaleHBoxContainer/TimeScale4xButton
@onready var time_scale_buttons: Array[Button] = [
	time_scale_1x_button,
	time_scale_2x_button,
	time_scale_4x_button
]

@onready var signals: Array[Dictionary] = [
	{SignalUtil.WHO: pause_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_pause_button_pressed},
	{SignalUtil.WHO: tower_selection_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_tower_selection_button_pressed},
	{SignalUtil.WHO: time_scale_1x_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_time_scale_1x_button_pressed},
	{SignalUtil.WHO: time_scale_2x_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_time_scale_2x_button_pressed},
	{SignalUtil.WHO: time_scale_4x_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_time_scale_4x_button_pressed}
]

# core
func _ready() -> void:
	assert(coins_rich_text_label != null, "coins_rich_text_label node not found")
	assert(health_rich_text_label != null, "health_rich_text_label node not found")
	assert(waves_rich_text_label != null, "waves_rich_text_label node not found")
	assert(health_texture_progress_bar != null, "health_texture_progress_bar node not found")
	assert(tower_selection_button != null, "tower_selection_button node not found")
	for button in time_scale_buttons:
		assert(button != null, "time scale button node not found")

	Global.hud = self
	hide()

	SignalUtil.connects(signals)
	_apply_time_scale(DEFAULT_TIME_SCALE, time_scale_1x_button)

func _process(_delta: float) -> void:
	if not _is_ready:
		return
	if not visible:
		show()

	coins_rich_text_label.text = tr(default_coins_text) % ILevel.current_level.coins
	health_rich_text_label.text = tr(default_health_text) % (str(ILevel.current_level.health) + "/20")
	health_texture_progress_bar.value = ILevel.current_level.health
	var current_wave: int = ILevel.current_level.current_wave + 1
	waves_rich_text_label.text = tr(default_waves_text) % current_wave

# public

## Initializes and displays the HUD interface.
## [br]Sets up signal connections and positions the construction menu.
func load_ui() -> void:
	if ILevel.current_level == null:
		Log.trace(Log.Level.ERROR, "Cannot load ingame ui, ILevel.current_level = null")
		return

	_is_ready = true
	visible = true
	SignalUtil.connects([ {SignalUtil.WHO: ILevel.current_level, SignalUtil.WHAT: "stats_updated", SignalUtil.TO: _update}])
	_update()

## Cleans up and hides the HUD interface.
func unload_ui() -> void:
	_is_ready = false
	visible = false
	ILevel.current_level.disconnect("stats_updated", _update)

# private

## Updates all tower cards in the build menu.
func _update() -> void:
	if !_is_ready:
		return

## Handles the pause button press event.
## [br]Creates and shows the pause menu.
func _on_pause_button_pressed() -> void:
	if not Global.paused:
		Global.paused = true
		var pause_menu_instance: Pause = PAUSE_MENU.instantiate()
		Global.ui.add_child(pause_menu_instance)

## Handles the tower selection button press event.
## [br]Creates and shows the tower selection menu.
func _on_tower_selection_button_pressed() -> void:
	if Global.ui.get_node("TowerSelection") == null :
		var tower_selection_menu_instance: TowerSelection = TOWER_SELECTION_MENU.instantiate()
		Global.ui.add_child(tower_selection_menu_instance)
	else :
		Global.ui.get_node("TowerSelection").queue_free()

## Handles the 1x speed button press event.
func _on_time_scale_1x_button_pressed() -> void:
	_apply_time_scale(DEFAULT_TIME_SCALE, time_scale_1x_button)

## Handles the 2x speed button press event.
func _on_time_scale_2x_button_pressed() -> void:
	_apply_time_scale(FAST_TIME_SCALE, time_scale_2x_button)

## Handles the 4x speed button press event.
func _on_time_scale_4x_button_pressed() -> void:
	_apply_time_scale(FASTEST_TIME_SCALE, time_scale_4x_button)

## Applies the requested time scale and updates button states.
func _apply_time_scale(time_scale: float, pressed_button: Button) -> void:
	Engine.time_scale = time_scale
	pressed_button.button_pressed = true
