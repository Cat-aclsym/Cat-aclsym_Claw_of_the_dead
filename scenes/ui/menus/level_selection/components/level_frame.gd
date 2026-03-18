## © [2026] A7 Studio. All rights reserved. Trademark.

class_name LevelFrame
extends Control
## Manages the level detail preview in the level selection menu.

signal start_level(level: ILevel)

# Constants
const CONDITION_DONE: Texture2D = preload("res://assets/ui/icons/Star.png")
const CONDITION_TODO: Texture2D = preload("res://assets/ui/level_selection/window/condition_todo.svg")
const LVL_DESC: String = "desc"
const LVL_IDEN: String = "id"
const LVL_NAME: String = "name"

# Variables
@export var arc_title: String
@export var level_id: String = "lev.XX"

var arc_texture: Texture2D
var level: ILevel = null : get = _get_level

@onready var challenges_container: VBoxContainer = $LevelPanelContainer/LevelMarginContainer/LevelVBoxContainer/FooterHBoxContainer/ChallengesContainer
@onready var description_label: Label = $LevelPanelContainer/LevelMarginContainer/LevelVBoxContainer/TopVBoxContainer/DescriptionLabel
@onready var level_name_label: Label = $LevelPanelContainer/LevelMarginContainer/LevelVBoxContainer/TopVBoxContainer/HeaderHBoxContainer/LevelNameLabel
@onready var play_button: TextureButton = $LevelPanelContainer/LevelMarginContainer/LevelVBoxContainer/FooterHBoxContainer/PlayButton

@onready var signals: Array[Dictionary] = [
	{SignalUtil.WHO: play_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_play_button_pressed}
]


# Built-in functions
func _ready() -> void:
	configure()


# Public functions
func configure() -> void:
	level_name_label.text = level.level_name
	description_label.text = level.level_description

	arc_texture = load("res://assets/ui/level_selection/bg_arcs/%s.png" % level.arc_id)

	_load_challenges()

	SignalUtil.connects(signals)


# Private functions
# private
func _get_level() -> ILevel:
	if level != null:
		return level
	var level_scene := load("res://scenes/gameplay/world/level/levels/%s.tscn" % level_id)
	level = level_scene.instantiate() as ILevel
	return level

	
func _load_challenges() -> void:
	# Load level config to find challenges
	var level_path := "res://resources/levels/%s.json" % level_id
	if not FileAccess.file_exists(level_path):
		challenges_container.visible = false
		return

	var file := FileAccess.open(level_path, FileAccess.READ)
	if not file:
		challenges_container.visible = false
		return

	var content := file.get_as_text()
	var json: Variant = JSON.parse_string(content)

	if not json or not json.has("challenges"):
		challenges_container.visible = false
		return

	var challenge_ids: Array = json["challenges"]
	var completed_challenges: Array[String] = []
	if ProgressionManager.data.levels.has(level_id):
		completed_challenges = ProgressionManager.data.levels[level_id].challenges_completed

	# Update existing challenge UI nodes
	for i in range(3):
		var challenge_node = challenges_container.get_child(i)
		if i < challenge_ids.size():
			challenge_node.visible = true
			var c_id = challenge_ids[i]
			_setup_challenge_ui(challenge_node, c_id, c_id in completed_challenges)
		else:
			challenge_node.visible = false


func _on_play_button_pressed() -> void:
	Log.trace(Log.Level.DEBUG, "Playing level [%s]" % level_name_label.text)
	start_level.emit(level)


func _setup_challenge_ui(node: HBoxContainer, c_id: String, is_completed: bool) -> void:
	var challenge_index: int = node.get_index() + 1
	var indicator: TextureRect = node.get_node("Challenge%dIndicator" % challenge_index)
	var label: Label = node.get_node("Challenge%dLabel" % challenge_index)

	indicator.texture = CONDITION_DONE if is_completed else CONDITION_TODO

	# Load challenge metadata for translation keys
	var path := "res://resources/challenges/%s.json" % c_id
	if FileAccess.file_exists(path):
		var file := FileAccess.open(path, FileAccess.READ)
		if not file:
			return
		var content := file.get_as_text()
		var data: Variant = JSON.parse_string(content)
		if data:
			# Display Name and Description
			var c_name = tr(data.get("name", ""))
			var c_desc = tr(data.get("description", ""))
			label.text = "%s: %s" % [c_name, c_desc]
		else:
			label.text = c_id
	else:
		label.text = c_id
