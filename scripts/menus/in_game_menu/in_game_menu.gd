## File: menus/ingame_menu/ingame_menu.gd
## The class for defining the behavior of the in-game menu and its components.
##
## Created: 06/03/2024

class_name IngameMenu
extends Control


@onready var CoinsRichTextLabel: Label = $HUDMarginContainer/HUDVBoxContainer/CoinsWavesMarginContainer/CoinsWavesHBoxContainer/CoinsTextureRect/MarginContainer/CoinsLabel
@onready var HealthRichTextLabel: Label = $HUDMarginContainer/HUDVBoxContainer/HeartTextureRect/HealthMarginContainer/MarginContainer/HealthTextureProgressBar/HealthLabel
@onready var HealthTextureProgressBar: TextureProgressBar = $HUDMarginContainer/HUDVBoxContainer/HeartTextureRect/HealthMarginContainer/MarginContainer/HealthTextureProgressBar
@onready var WavesRichTextLabel: Label = $HUDMarginContainer/HUDVBoxContainer/CoinsWavesMarginContainer/CoinsWavesHBoxContainer/WavesTextureRect/MarginContainer/WavesLabel
@onready var NewWaveCountLabel: Label = $NewWaveCountLabel
@onready var default_coins_text := CoinsRichTextLabel.text
@onready var default_health_text := HealthRichTextLabel.text
@onready var default_waves_text := WavesRichTextLabel.text
@onready var build_button: TextureButton = $VBoxContainer/MarginContainer/BuildButton

@onready var ConstructionAnimationPlayer: AnimationPlayer = $AnimationPlayer
@onready var ConstructionWrapper: VBoxContainer = $VBoxContainer
@onready var ConstructionMenu: PanelContainer = $VBoxContainer/PanelContainer
@onready var TowerList: HBoxContainer = $VBoxContainer/PanelContainer/MarginContainer/HBoxContainer

const pause_menu: PackedScene = preload("res://scenes/menus/pause_menu/pause_menu.tscn")

var _is_ready: bool = false


func _ready() -> void:
	Global.ig_menu = self
	hide()

	ConstructionAnimationPlayer.animation_finished.connect(
	func(_name: String) -> void:
		if _name == "RESET" and ConstructionMenu.visible:
			ConstructionMenu.visible = false
	)
	ConstructionMenu.visible = true
	

func _process(_delta: float) -> void:
	if not _is_ready: return
	if not visible: show()

	CoinsRichTextLabel.text = tr(default_coins_text) % ILevel.current_level.coins
	HealthRichTextLabel.text = tr(default_health_text) % (str(ILevel.current_level.health) + "/10")
	HealthTextureProgressBar.value = ILevel.current_level.health
	var current_wave := ILevel.current_level.Map.current_wave + 1
	WavesRichTextLabel.text = tr(default_waves_text) % current_wave


# functionnal
func toggle_build_menu(toggle_bt: bool = true) -> void:
	if toggle_bt:
		build_button.button_pressed = !build_button.button_pressed
		
	if ConstructionMenu.visible:
		Log.info("Hiding construction menu")
		ConstructionAnimationPlayer.play("RESET")
	else:
		Log.info("Showing construction menu")
		ConstructionAnimationPlayer.play("show_tower_list")
		ConstructionMenu.visible = true
		return

	for tower_card in TowerList.get_children():
		tower_card.update()


# internal
func _update() -> void:
	if !_is_ready: return

	for tower_card in TowerList.get_children():
		tower_card.update()


# signals
func _on_build_button_pressed() -> void:
	toggle_build_menu(false)

# functionnal
func load_ui() -> void:
	if ILevel.current_level == null:
		Log.error("Cannot load ingame ui, ILevel.current_level = null")
		return

	_is_ready = true
	visible = true
	ILevel.current_level.stats_updated.connect(_update)
	_update()

	## Fix, the construction wrapper is not at the bottom of the screen but should be
	var construction_wrapper_y: float = get_viewport_rect().size.y - (ConstructionWrapper.size.y + 5)
	ConstructionWrapper.position.y = construction_wrapper_y


func unload_ui() -> void:
	_is_ready = false
	visible = false
	ILevel.current_level.disconnect("stats_updated", _update)


func _on_pause_button_pressed():
	if not Global.paused:
		Global.paused = true
		var pause_menu_instance: PauseMenu = pause_menu.instantiate()
		Global.hud.add_child(pause_menu_instance)


func _on_place_button_pressed():
	pass

func _on_cancel_place_button_pressed():
	pass
