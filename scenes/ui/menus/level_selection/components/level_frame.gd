## © [2024] A7 Studio. All rights reserved. Trademark.
## @experimental
class_name LevelFrame extends Control

signal start_level(level: ILevel)

const LVL_IDEN: String = "id"
const LVL_NAME: String = "name"
const LVL_DESC: String = "desc"

@export var level_id: String = "lev.XX"
@export var arc_title: String

# var level: ILevel
var arc_texture: Texture2D
var arc_id: String
var level: ILevel = null : get = _get_level

@onready var description_label: Label = $PanelContainer/MarginContainer/VBoxContainer/DescriptionLabel
@onready var level_name_label: Label = $PanelContainer/MarginContainer/VBoxContainer/HeaderContainer/LevelNameLabel
@onready var play_button: TextureButton = $PanelContainer/MarginContainer/VBoxContainer/FooterContainer/PlayButton
@onready var signals: Array[Dictionary] = [
	{SignalUtil.WHO: play_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_play_button_pressed}
]

# core
func _ready() -> void:
	configure()


# public
func configure() -> void:
	level_name_label.text = level.level_name
	description_label.text = level.level_description
	arc_id = level.arc_id
	
	level.free()
	level = null

	arc_texture = load("res://assets/ui/level_selection/bg_arcs/%s.png" % arc_id)
	SignalUtil.connects(signals)


# private
func _get_level() -> ILevel:
	if level != null:
		return level
	var level_scene := load("res://scenes/gameplay/world/level/levels/%s.tscn" % level_id)
	level = level_scene.instantiate() as ILevel
	return level


# signal
func _on_play_button_pressed() -> void:
	Log.trace(Log.Level.DEBUG, "Playing level [%s]" % level_name_label.text)
	start_level.emit(level) # level is reparented by the listener -> no need to free it here

# event


# setget
