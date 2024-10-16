## File: menus/ingame_menu/ingame_menu.gd
## The class for defining the behavior of the in-game menu and its components.
##
## Created: 06/03/2024

class_name IngameMenu
extends Control


@onready var coins_rich_text_label: Label = $HUDMarginContainer/HUDVBoxContainer/CoinsWavesMarginContainer/CoinsWavesHBoxContainer/CoinsTextureRect/MarginContainer/CoinsLabel
@onready var health_rich_text_label: Label = $HUDMarginContainer/HUDVBoxContainer/HeartTextureRect/HealthMarginContainer/MarginContainer/HealthTextureProgressBar/HealthLabel
@onready var waves_rich_text_label: Label = $HUDMarginContainer/HUDVBoxContainer/CoinsWavesMarginContainer/CoinsWavesHBoxContainer/WavesTextureRect/MarginContainer/WavesLabel
@onready var default_coins_text: String = coins_rich_text_label.text
@onready var default_health_text: String = health_rich_text_label.text
@onready var default_waves_text: String = waves_rich_text_label.text

@onready var health_texture_progress_bar: TextureProgressBar = $HUDMarginContainer/HUDVBoxContainer/HeartTextureRect/HealthMarginContainer/MarginContainer/HealthTextureProgressBar
@onready var new_wave_count_label: Label = $NewWaveCountLabel

@onready var construction_anim_player: AnimationPlayer = $AnimationPlayer
@onready var construction_wrapper: VBoxContainer = $VBoxContainer
@onready var construction_menu: PanelContainer = $VBoxContainer/PanelContainer
@onready var build_button: TextureButton = $VBoxContainer/MarginContainer/BuildButton
@onready var tower_list: HBoxContainer = $VBoxContainer/PanelContainer/MarginContainer/HBoxContainer

const pause_menu: PackedScene = preload("res://scenes/menus/pause_menu/pause_menu.tscn")

var _is_ready: bool = false


# core
func _ready() -> void:
	Global.ig_menu = self
	hide()

	construction_anim_player.animation_finished.connect(
	func(_name: String) -> void:
		if _name == "RESET" and construction_menu.visible:
			construction_menu.visible = false
	)
	construction_menu.visible = true


func _process(_delta: float) -> void:
	if not _is_ready: return
	if not visible: show()

	coins_rich_text_label.text = tr(default_coins_text) % ILevel.current_level.coins
	health_rich_text_label.text = tr(default_health_text) % (str(ILevel.current_level.health) + "/20")
	health_texture_progress_bar.value = ILevel.current_level.health
	var current_wave: int = ILevel.current_level.map.current_wave + 1
	waves_rich_text_label.text = tr(default_waves_text) % current_wave


# public
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

func load_ui() -> void:
	if ILevel.current_level == null:
		Log.trace(Log.Level.ERROR, "Cannot load ingame ui, ILevel.current_level = null")
		return

	_is_ready = true
	visible = true
	ILevel.current_level.stats_updated.connect(_update)
	_update()

	## Fix, the construction wrapper is not at the bottom of the screen but should be
	var construction_wrapper_y: float = get_viewport_rect().size.y - (construction_wrapper.size.y + 5)
	construction_wrapper.position.y = construction_wrapper_y


func unload_ui() -> void:
	_is_ready = false
	visible = false
	ILevel.current_level.disconnect("stats_updated", _update)


# private
func _update() -> void:
	if !_is_ready: return

	for tower_card in tower_list.get_children():
		tower_card.update()


# signal
func _on_build_button_pressed() -> void:
	toggle_build_menu(false)


func _on_pause_button_pressed():
	if not Global.paused:
		Global.paused = true
		var pause_menu_instance: PauseMenu = pause_menu.instantiate()
		Global.hud.add_child(pause_menu_instance)


func _on_place_button_pressed():
	pass

func _on_cancel_place_button_pressed():
	pass

# event


# setget
