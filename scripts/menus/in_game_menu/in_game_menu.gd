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

@onready var ConstructionMenu: PanelContainer = $VBoxContainer/PanelContainer
@onready var TowerList: HBoxContainer = $VBoxContainer/PanelContainer/HBoxContainer

var _is_ready: bool = false


func _ready() -> void:
	hide()


func _process(_delta: float) -> void:
	if (!_is_ready): return
	if (!visible): show()

	CoinsRichTextLabel.text = tr(default_coins_text) % ILevel.current_level.coins
	HealthRichTextLabel.text = tr(default_health_text) % (str(ILevel.current_level.health) + "/10")
	HealthTextureProgressBar.value = ILevel.current_level.health
	var current_wave := ILevel.current_level.Map.current_wave + 1
	WavesRichTextLabel.text = tr(default_waves_text) % current_wave


# internal
func _update() -> void:
	if !_is_ready: return

	for tower_card in TowerList.get_children():
		tower_card.update()


# signals
func _on_build_button_pressed() -> void:
	ConstructionMenu.visible = !ConstructionMenu.visible

	if !ConstructionMenu.visible:
		return

	for tower_card in TowerList.get_children():
		tower_card.update()

# functionnal
func load_ui() -> void:
	if ILevel.current_level == null:
		Log.error("Cannot load ingame ui, ILevel.current_level = null")
		return

	_is_ready = true
	visible = true
	ILevel.current_level.connect("stats_updated", _update)
	_update()


func unload_ui() -> void:
	_is_ready = false
	visible = false
	ILevel.current_level.disconnect("stats_updated", _update)
