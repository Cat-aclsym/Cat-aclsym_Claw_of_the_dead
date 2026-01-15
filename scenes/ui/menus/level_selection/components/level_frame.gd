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

@onready var description_label: Label = $PanelContainer/MarginContainer/VBoxContainer/DescriptionLabel
@onready var level_name_label: Label = $PanelContainer/MarginContainer/VBoxContainer/HeaderContainer/LevelNameLabel
@onready var play_button: TextureButton = $PanelContainer/MarginContainer/VBoxContainer/FooterContainer/PlayButton
@onready var challenges_container: VBoxContainer = $PanelContainer/MarginContainer/VBoxContainer/FooterContainer/ChallengesContainer

const CONDITION_TODO: Texture2D = preload("res://assets/ui/level_selection/window/condition_todo.svg")
const CONDITION_DONE: Texture2D = preload("res://assets/ui/level_selection/window/condition_done.svg")

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
	description_label.text = level.level_description

	arc_texture = load("res://assets/ui/level_selection/bg_arcs/%s.png" % level.arc_id)

	_load_challenges()

	SignalUtil.connects(signals)


# private
func _load_challenges() -> void:
	# Load level config to find challenges
	var level_path := "res://resources/levels/%s.json" % level_id
	if not FileAccess.file_exists(level_path):
		challenges_container.visible = false
		return

	var file := FileAccess.open(level_path, FileAccess.READ)
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

func _setup_challenge_ui(node: HBoxContainer, c_id: String, is_completed: bool) -> void:
	var indicator: TextureRect = node.get_node("Indicator")
	var label: Label = node.get_node("Label")

	indicator.texture = CONDITION_DONE if is_completed else CONDITION_TODO

	# Load challenge metadata for translation keys
	var path := "res://resources/challenges/%s.json" % c_id
	if FileAccess.file_exists(path):
		var file := FileAccess.open(path, FileAccess.READ)
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



# signal
func _on_play_button_pressed() -> void:
	Log.trace(Log.Level.DEBUG, "Playing level [%s]" % level_name_label.text)
	start_level.emit(level)

# event


# setget
