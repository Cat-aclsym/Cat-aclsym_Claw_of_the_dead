## File: menus/ingame_menu/ingame_menu.gd
## The class for defining the behavior of the in-game menu and its components.
##
## Created: 06/03/2024

class_name IngameMenu
extends Control


@onready var CoinsRichTextLabel: RichTextLabel = $MarginContainer/VBoxContainer/HBoxContainer/CoinsPanelContainer/CoinsRichTextLabel
@onready var HealthRichTextLabel: RichTextLabel = $MarginContainer/VBoxContainer/HealthBoxContainer/MarginContainer/HealthRichTextLabel
@onready var HealthTextureProgressBar: TextureProgressBar = $MarginContainer/VBoxContainer/HealthBoxContainer/HealthTextureProgressBar
@onready var WavesRichTextLabel: RichTextLabel = $MarginContainer/VBoxContainer/HBoxContainer/WavesPanelContainer/WavesRichTextLabel
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
	pass
