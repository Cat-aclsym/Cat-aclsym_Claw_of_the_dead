## File: menus/ingame_menu/ingame_menu.gd
## The class for defining the behavior of the in-game menu and its components.
##
## Created: 06/03/2024

class_name IngameMenu
extends Node


@onready var CoinsRichTextLabel: RichTextLabel = $VBoxContainer/CoinsRichTextLabel
@onready var HealthRichTextLabel: RichTextLabel = $VBoxContainer/HealthRichTextLabel
@onready var WavesRichTextLabel: RichTextLabel = $VBoxContainer/WavesRichTextLabel
@onready var default_coins_text := CoinsRichTextLabel.text
@onready var default_health_text := HealthRichTextLabel.text
@onready var default_waves_text := WavesRichTextLabel.text


func _ready() -> void:
	print(default_coins_text)


func _process(_delta: float) -> void:
	CoinsRichTextLabel.text = tr(default_coins_text) % Stats.coins
	HealthRichTextLabel.text = tr(default_health_text) % Stats.health
	#	WavesRichTextLabel.text = tr(default_waves_text % [Stats.waves])
	pass
