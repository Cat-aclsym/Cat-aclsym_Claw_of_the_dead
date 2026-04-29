## © [2026] A7 Studio. All rights reserved. Trademark.

class_name LevelFrame
extends Control
## Manages the level detail preview in the level selection menu.

signal start_level(level: ILevel)

## Constants
const CONDITION_DONE: Texture2D = preload("res://assets/ui/icons/Star.png")
const CONDITION_TODO: Texture2D = preload("res://assets/ui/icons/Star_Empty.png")
const CHALLENGE_DESCRIPTION_KEY: String = "description"
const CHALLENGE_NAME_KEY: String = "name"
const DEFAULT_ARC_ID: String = "arc.01"
const LEVEL_DATA_CHALLENGES_KEY: String = "challenges"
const LEVEL_SCENE_PATH_PATTERN: String = "res://scenes/gameplay/world/level/levels/%s.tscn"
const LEVEL_JSON_PATH_PATTERN: String = "res://resources/levels/%s.json"
const CHALLENGE_JSON_PATH_PATTERN: String = "res://resources/challenges/%s.json"

## Variables
@export var arc_title: String
@export var level_id: String = "lev.XX"

var arc_texture: Texture2D
var _level: ILevel = null
var level: ILevel = null : get = _get_level

@onready var challenges_container: VBoxContainer = $LevelPanelContainer/LevelMarginContainer/LevelVBoxContainer/FooterHBoxContainer/ChallengesContainer
@onready var description_label: Label = $LevelPanelContainer/LevelMarginContainer/LevelVBoxContainer/TopVBoxContainer/DescriptionLabel
@onready var level_name_label: Label = $LevelPanelContainer/LevelMarginContainer/LevelVBoxContainer/TopVBoxContainer/HeaderHBoxContainer/LevelNameLabel
@onready var play_button: TextureButton = $LevelPanelContainer/LevelMarginContainer/LevelVBoxContainer/FooterHBoxContainer/PlayButton
@onready var signals: Array[Dictionary] = [
	{SignalUtil.WHO: play_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_play_button_pressed}
]


## Built-in functions
func _ready() -> void:
	assert(play_button != null, "play_button is required")
	configure()


func _exit_tree() -> void:
	unload_level()


## Public functions
func configure() -> void:
	var scene_state: SceneState = _load_level_scene_state()
	var level_name: String = _get_scene_string_property(scene_state, "level_name", level_id)
	var level_description: String = _get_scene_string_property(scene_state, "level_description", "")
	var arc_id: String = _get_scene_string_property(scene_state, "arc_id", DEFAULT_ARC_ID)

	level_name_label.text = tr(level_name)
	description_label.text = tr(level_description)
	arc_texture = load("res://assets/ui/level_selection/bg_arcs/%s.png" % arc_id)

	_load_challenges()

	SignalUtil.connects(signals)
	ButtonEffects.apply(play_button)


## Private functions
func _get_level() -> ILevel:
	if _level != null:
		return _level
	var level_scene: PackedScene = load(LEVEL_SCENE_PATH_PATTERN % level_id)
	_level = level_scene.instantiate() as ILevel
	return _level


func _load_level_scene_state() -> SceneState:
	var level_scene_path: String = LEVEL_SCENE_PATH_PATTERN % level_id
	var level_scene := load(level_scene_path) as PackedScene
	if level_scene == null:
		return null

	var scene_state: SceneState = level_scene.get_state()
	return scene_state


func _get_scene_string_property(scene_state: SceneState, property_name: StringName, fallback: String) -> String:
	if scene_state == null:
		return fallback

	var root_node_index: int = 0
	var property_count: int = scene_state.get_node_property_count(root_node_index)
	for property_index in property_count:
		var current_property_name: StringName = scene_state.get_node_property_name(root_node_index, property_index)
		if current_property_name != property_name:
			continue

		var value: Variant = scene_state.get_node_property_value(root_node_index, property_index)
		if value is String:
			return value
		return fallback

	return fallback


func unload_level() -> void:
	if not is_instance_valid(_level):
		_level = null
		return

	if _level.is_inside_tree():
		return

	var level_to_free: ILevel = _level
	_level = null
	level_to_free.queue_free()


func _load_challenges() -> void:
	var challenge_ids: Array[String] = _load_level_challenge_ids()
	if challenge_ids.is_empty():
		challenges_container.visible = false
		return

	var completed_challenges: Array[String] = []
	if ProgressionManager.data.levels.has(level_id):
		completed_challenges = ProgressionManager.data.levels[level_id].challenges_completed

	## Reuses authored UI slots instead of building nodes dynamically.
	for i in range(3):
		var challenge_node: HBoxContainer = challenges_container.get_child(i)
		if i < challenge_ids.size():
			challenge_node.visible = true
			var c_id: String = challenge_ids[i]
			_setup_challenge_ui(challenge_node, c_id, c_id in completed_challenges)
		else:
			challenge_node.visible = false


func _load_level_challenge_ids() -> Array[String]:
	var path: String = LEVEL_JSON_PATH_PATTERN % level_id
	var data: Dictionary = _read_json_dictionary(path)
	if data.is_empty():
		return []

	var challenge_ids: Array[String] = []
	var raw_challenges: Variant = data.get(LEVEL_DATA_CHALLENGES_KEY, [])
	if raw_challenges is Array:
		for challenge_id in raw_challenges:
			if challenge_id is String:
				challenge_ids.append(challenge_id)
	return challenge_ids


func _read_json_dictionary(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}

	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		return parsed
	return {}


func _on_play_button_pressed() -> void:
	Log.trace(Log.Level.DEBUG, "Playing level [%s]" % level_name_label.text)
	start_level.emit(level)


func _setup_challenge_ui(node: HBoxContainer, c_id: String, is_completed: bool) -> void:
	var challenge_index: int = node.get_index() + 1
	var indicator: TextureRect = node.get_node("Challenge%dIndicator" % challenge_index)
	var label: Label = node.get_node("Challenge%dLabel" % challenge_index)

	indicator.texture = CONDITION_DONE if is_completed else CONDITION_TODO

	var path: String = CHALLENGE_JSON_PATH_PATTERN % c_id
	var challenge_data: Dictionary = _read_json_dictionary(path)
	if challenge_data.is_empty():
		label.text = c_id
		return

	var challenge_name: String = challenge_data.get(CHALLENGE_NAME_KEY, "")
	var challenge_description: String = challenge_data.get(CHALLENGE_DESCRIPTION_KEY, "")
	if challenge_name.is_empty() or challenge_description.is_empty():
		label.text = c_id
		return

	label.text = "%s: %s" % [tr(challenge_name), tr(challenge_description)]
