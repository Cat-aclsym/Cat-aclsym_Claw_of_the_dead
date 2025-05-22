## © [2024] A7 Studio. All rights reserved. Trademark.
## @experimental
class_name LevelFrame extends Control

signal start_level(level: ILevel)

const LVL_IDEN: String = "id"
const LVL_NAME: String = "name"
const LVL_DESC: String = "desc"

@export var arc_title: String
@export var arc_texture: CompressedTexture2D
@export var level_scene: PackedScene

var level: ILevel

@onready var level_name_label: Label = $PanelContainer/MarginContainer/VBoxContainer/HeaderContainer/LevelNameLabel
@onready var description_label: Label = $PanelContainer/MarginContainer/VBoxContainer/DescriptionLabel
@onready var challenges_container: VBoxContainer = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/ChallengesContainer
@onready var play_button: TextureButton = $PanelContainer/MarginContainer/VBoxContainer/FooterContainer/PlayButton

@onready var signals: Array[Dictionary] = [
	{SignalUtil.WHO: play_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_play_button_pressed}
]

# core
func _ready() -> void:
	configure()


# public
func configure() -> void:
	level = level_scene.instantiate()

	level_name_label.text = level.level_name
	
	SignalUtil.connects(signals)


# private


# signal
func _on_play_button_pressed() -> void:
	Log.trace(Log.Level.DEBUG, "Playing level [%s]" % level_name_label.text)
	start_level.emit(level)

# event


# setget
