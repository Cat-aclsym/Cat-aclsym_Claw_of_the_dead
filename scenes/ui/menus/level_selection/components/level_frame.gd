## © [2024] A7 Studio. All rights reserved. Trademark.
## @experimental
class_name LevelFrame extends Control

signal start_level(level: ILevel)

const LVL_IDEN: String = "id"
const LVL_NAME: String = "name"
const LVL_DESC: String = "desc"

@export var level_id: String = "lev.XX"
@export var arc_title: String

var level: ILevel
var arc_texture: Texture2D

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
	var level_scene := load("res://scenes/gameplay/world/level/levels/%s.tscn" % level_id)
	level = level_scene.instantiate()

	level_name_label.text = level.level_name

	arc_texture = load("res://assets/ui/level_selection/bg_arcs/%s.png" % level.arc_id)
	
	SignalUtil.connects(signals)


# private


# signal
func _on_play_button_pressed() -> void:
	Log.trace(Log.Level.DEBUG, "Playing level [%s]" % level_name_label.text)
	start_level.emit(level)

# event


# setget
