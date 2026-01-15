## © [2026] A7 Studio. All rights reserved. Trademark.

class_name HUD
extends Control
## Manages the in-game HUD interface and its components.
##
## Handles resource displays, wave counters, and construction menu.

# Constants
const DEFAULT_TIME_SCALE: float = 1.0
const PAUSE_MENU: PackedScene = preload("res://scenes/ui/menus/pause/pause.tscn")
const SKIP_COLOR_INACTIVE: Color = Color(1.0, 1.0, 1.0, 1.0)
const SKIP_TIME_SCALE: float = 3.0
const TOWER_SELECTION_MENU: PackedScene = preload("res://scenes/ui/menus/tower_selection/tower_selection.tscn")

# Variables
@onready var coins_rich_text_label: Label = %HUDVBoxContainer/CoinsWavesMarginContainer/CoinsWavesHBoxContainer/CoinsTextureRect/MarginContainer/CoinsLabel
@onready var health_rich_text_label: Label = %HUDVBoxContainer/HeartTextureRect/HealthMarginContainer/MarginContainer/HealthTextureProgressBar/HealthLabel
@onready var health_texture_progress_bar: TextureProgressBar = %HUDVBoxContainer/HeartTextureRect/HealthMarginContainer/MarginContainer/HealthTextureProgressBar
@onready var new_wave_count_label: Label = $NewWaveCountLabel
@onready var pause_button: TextureButton = $PauseMarginContainer/PauseButton
@onready var skip_animation_player: AnimationPlayer = $SkipMarginContainer/SkipAnimationPlayer
@onready var skip_time_scale_button: TextureButton = $SkipMarginContainer/SkipButton
@onready var tower_selection_button: TextureButton = $TowerSelectionMarginContainer/TowerSelectionButton
@onready var waves_rich_text_label: Label = %HUDVBoxContainer/CoinsWavesMarginContainer/CoinsWavesHBoxContainer/WavesTextureRect/MarginContainer/WavesLabel

@onready var default_coins_text: String = coins_rich_text_label.text
@onready var default_health_text: String = health_rich_text_label.text
@onready var default_waves_text: String = waves_rich_text_label.text

@onready var signals: Array[Dictionary] = [
	{SignalUtil.WHO: pause_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_pause_button_pressed},
	{SignalUtil.WHO: skip_time_scale_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_skip_time_scale_button_pressed},
	{SignalUtil.WHO: tower_selection_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_tower_selection_button_pressed}
]

var _is_ready: bool = false


# Built-in functions
func _ready() -> void:
	assert(coins_rich_text_label != null, "coins_rich_text_label node not found")
	assert(health_rich_text_label != null, "health_rich_text_label node not found")
	assert(waves_rich_text_label != null, "waves_rich_text_label node not found")
	assert(health_texture_progress_bar != null, "health_texture_progress_bar node not found")
	assert(tower_selection_button != null, "tower_selection_button node not found")
	assert(skip_time_scale_button != null, "skip_time_scale_button node not found")

	Global.hud = self
	hide()

	SignalUtil.connects(signals)
	_apply_time_scale(DEFAULT_TIME_SCALE, false)


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


# Public functions
## Initializes and displays the HUD interface.
func load_ui() -> void:
	if ILevel.current_level == null:
		Log.trace(Log.Level.ERROR, "Cannot load ingame ui, ILevel.current_level = null")
		return

	_is_ready = true
	visible = true
	SignalUtil.connects([{SignalUtil.WHO: ILevel.current_level, SignalUtil.WHAT: "stats_updated", SignalUtil.TO: _update}])
	_update()


## Cleans up and hides the HUD interface.
func unload_ui() -> void:
	_is_ready = false
	visible = false
	ILevel.current_level.disconnect("stats_updated", _update)


# Private functions
func _apply_time_scale(time_scale: float, is_fast: bool) -> void:
	Engine.time_scale = time_scale
	skip_time_scale_button.button_pressed = is_fast
	if is_fast:
		skip_animation_player.play("skip_active")
	else:
		skip_animation_player.stop()
		skip_time_scale_button.modulate = SKIP_COLOR_INACTIVE


func _on_pause_button_pressed() -> void:
	if not Global.paused:
		Global.paused = true
		var pause_menu_instance: Pause = PAUSE_MENU.instantiate()
		Global.ui.add_child(pause_menu_instance)


func _on_skip_time_scale_button_pressed() -> void:
	var is_fast: bool = skip_time_scale_button.button_pressed
	var target_scale: float = SKIP_TIME_SCALE if is_fast else DEFAULT_TIME_SCALE
	_apply_time_scale(target_scale, is_fast)


func _on_tower_selection_button_pressed() -> void:
	if Global.ui.get_node("TowerSelection") == null:
		var tower_selection_menu_instance: TowerSelection = TOWER_SELECTION_MENU.instantiate()
		Global.ui.add_child(tower_selection_menu_instance)
	else:
		Global.ui.get_node("TowerSelection").queue_free()


func _update() -> void:
	if !_is_ready:
		return
