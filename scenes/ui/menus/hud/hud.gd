## © [2024] A7 Studio. All rights reserved. Trademark.
##
## Manages the in-game HUD interface and its components.
## Handles resource displays, wave counters, and construction menu.
class_name HUD
extends Control

const PAUSE_MENU: PackedScene = preload("res://scenes/ui/menus/pause/pause.tscn")

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

## Construction menu nodes
@onready var construction_anim_player: AnimationPlayer = $AnimationPlayer
@onready var construction_menu: PanelContainer = $VBoxContainer/PanelContainer
@onready var construction_wrapper: VBoxContainer = $VBoxContainer
@onready var tower_list: HBoxContainer = $VBoxContainer/PanelContainer/MarginContainer/HBoxContainer

## HUD buttons
@onready var build_button: TextureButton = $VBoxContainer/MarginContainer/BuildButton
@onready var pause_button: TextureButton = $MarginContainer/PauseButton

@onready var signals: Array[Dictionary] = [
	{SignalUtil.WHO: build_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_build_button_pressed},
	{SignalUtil.WHO: pause_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_pause_button_pressed},
]

# core
func _ready() -> void:
	assert(coins_rich_text_label != null, "coins_rich_text_label node not found")
	assert(health_rich_text_label != null, "health_rich_text_label node not found")
	assert(waves_rich_text_label != null, "waves_rich_text_label node not found")
	assert(health_texture_progress_bar != null, "health_texture_progress_bar node not found")
	assert(construction_anim_player != null, "construction_anim_player node not found")
	assert(construction_menu != null, "construction_menu node not found")
	assert(build_button != null, "build_button node not found")
	assert(tower_list != null, "tower_list node not found")

	Global.hud = self
	hide()

	construction_anim_player.animation_finished.connect(
		func(_name: String) -> void:
			if _name == "RESET" and construction_menu.visible:
				construction_menu.visible = false
	)
	construction_menu.visible = true
	SignalUtil.connects(signals)

func _process(_delta: float) -> void:
	if not _is_ready:
		return
	if not visible:
		show()

	coins_rich_text_label.text = tr(default_coins_text) % ILevel.current_level.coins
	health_rich_text_label.text = tr(default_health_text) % (str(ILevel.current_level.health) + "/20")
	health_texture_progress_bar.value = ILevel.current_level.health
	var current_wave: int = ILevel.current_level.map.current_wave + 1
	waves_rich_text_label.text = tr(default_waves_text) % current_wave

# public
## Toggles the build menu visibility with animation.
## [br]Updates tower cards when showing the menu.
## [param toggle_bt] Whether to toggle the build button state
func toggle_build_menu(toggle_bt: bool = true) -> void:
	if toggle_bt:
		build_button.button_pressed = !build_button.button_pressed

	if construction_menu.visible:
		Log.trace(Log.Level.INFO, "Hiding construction menu")
		construction_anim_player.play("RESET")
	else:
		Log.trace(Log.Level.INFO, "Showing construction menu")
		construction_anim_player.play("show_tower_list")
		construction_menu.visible = true
		return

	for tower_card in tower_list.get_children():
		tower_card.update()

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

	var construction_wrapper_y: float = get_viewport_rect().size.y - (construction_wrapper.size.y + 5)
	construction_wrapper.position.y = construction_wrapper_y

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

	for tower_card in tower_list.get_children():
		tower_card.update()

## Handles the build button press event.
func _on_build_button_pressed() -> void:
	toggle_build_menu(false)

## Handles the pause button press event.
## [br]Creates and shows the pause menu.
func _on_pause_button_pressed() -> void:
	if not Global.paused:
		Global.paused = true
		var pause_menu_instance: PauseMenu = PAUSE_MENU.instantiate()
		Global.ui.add_child(pause_menu_instance)
