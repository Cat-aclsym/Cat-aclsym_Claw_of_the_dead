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


func _ready() -> void:
	hide()


func _process(_delta: float) -> void:


	if (ILevel.current_level == null): return
	if (!visible): show()

	CoinsRichTextLabel.text = tr(default_coins_text) % ILevel.current_level.coins
	HealthRichTextLabel.text = tr(default_health_text) % (str(ILevel.current_level.health) + "/10")
	HealthTextureProgressBar.value = ILevel.current_level.health
	var current_wave := ILevel.current_level.Map.current_wave + 1
	WavesRichTextLabel.text = tr(default_waves_text) % current_wave
