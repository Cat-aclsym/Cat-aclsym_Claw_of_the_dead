## © [2025] A7 Studio. All rights reserved. Trademark.
##
## Manages the win screen interface and UI interactions.
## Handles restart level, go to next level and return home.
class_name EndGame
extends Control

# Onready Variables
@onready var time_label: Label = $GUIMarginContainer/BackgroundTextureRect/MarginContainer/VBoxContainer/HBoxContainer/TimeAspectRatioContainer/TimeHBoxContainer/TimeStatisticLabel
@onready var life_label: Label = $GUIMarginContainer/BackgroundTextureRect/MarginContainer/VBoxContainer/HBoxContainer/LifeAspectRatioContainer/LifeHBoxContainer/LifeStatisticLabel
@onready var title_label: Label = $GUIMarginContainer/BackgroundTextureRect/MarginContainer/VBoxContainer/TitleLabel
@onready var home_button: TextureButton = $GUIMarginContainer/BackgroundTextureRect/MarginContainer/VBoxContainer/ButtonsHBoxContainer/HomeButtonAspectRatioContainer/HomeTextureButton
@onready var restart_button: TextureButton = $GUIMarginContainer/BackgroundTextureRect/MarginContainer/VBoxContainer/ButtonsHBoxContainer/RestartButtonAspectRatioContainer/RestartTextureButton
@onready var next_button: TextureButton = $GUIMarginContainer/BackgroundTextureRect/MarginContainer/VBoxContainer/ButtonsHBoxContainer/NextButtonAspectRatioContainer/NextTextureButton
@onready var end_game_image: TextureRect = $GUIMarginContainer/BackgroundTextureRect/MarginContainer/VBoxContainer/TextureRect
@onready var default_time_text: String = time_label.text
@onready var default_health_text: String = life_label.text

@onready var signals: Array[Dictionary] = [
	{SignalUtil.WHO: home_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_home_texture_button_pressed},
	{SignalUtil.WHO: restart_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_restart_texture_button_pressed},
	{SignalUtil.WHO: next_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_next_texture_button_pressed}
]

## Elapsed time from the start to the end of the level in text format for display purpose
var elapsed_time_text: String

## Elapsed seconds from the start to the end of the level (minus the minutes if any)
var elapsed_time_seconds: int

## Elapsed minutes from the start to the end of the level
var elapsed_time_minutes: int

# Core
func _ready():
	assert(time_label != null, "time_label node not found")
	assert(life_label != null, "life_label node not found")
	assert(home_button != null, "home_button node not found")
	assert(restart_button != null, "restart_button node not found")
	assert(next_button != null, "next_button node not found")

	elapsed_time_seconds = ILevel.current_level.end_time -ILevel.current_level.start_time
	elapsed_time_minutes = elapsed_time_seconds / 60
	Log.trace(Log.Level.INFO, str(elapsed_time_minutes))
	Log.trace(Log.Level.INFO, str(elapsed_time_seconds))
	if elapsed_time_seconds > 60:
		elapsed_time_seconds = elapsed_time_seconds - (elapsed_time_minutes * 60)
		elapsed_time_text = str(elapsed_time_minutes) + "m " + str(elapsed_time_seconds) + "s"
	else:
		elapsed_time_text = str(elapsed_time_seconds) + "s"
	time_label.text = tr(default_time_text) % str(elapsed_time_text)
	life_label.text = tr(default_health_text) % (str(ILevel.current_level.health) + "/20")

	if ILevel.current_level.current_state == ILevel.STATE_VICTORY:
		title_label.text = tr("ENDGAMEMENU.LEVEL.TITLE.WIN")
		end_game_image.texture = ResourceLoader.load("res://assets/ui/icons/Victory Gold.svg")
	elif ILevel.current_level.current_state == ILevel.STATE_DEFEAT:
		title_label.text = tr("ENDGAMEMENU.LEVEL.TITLE.LOOSE")
		end_game_image.texture = ResourceLoader.load("res://assets/ui/icons/Defeat.svg")

	SignalUtil.connects(signals)


# private
## Restarts the current level with fresh state.
## [br]Creates a new instance of the current level and initializes it.
func _on_restart_texture_button_pressed() -> void:
	var current_level := ILevel.current_level
	var level_metadata: LevelMetadata = current_level.metadata.duplicate()
	var level_scene: PackedScene = load(current_level.get_scene_file_path())

	current_level.queue_free()
	await current_level.tree_exited

	var new_level: ILevel = level_scene.instantiate()
	get_tree().get_root().add_child(new_level)
	new_level.initialize(level_metadata)
	ILevel.current_level = new_level
	Global.ui.start_level()

	Global.paused = false
	queue_free()


## Returns to the main menu and cleans up the current level.
func _on_next_texture_button_pressed() -> void:
	var current_level: ILevel = ILevel.current_level
	var new_level_metadata : LevelMetadata = LevelMetadata.new()
	new_level_metadata.id = current_level.metadata.id
	new_level_metadata.level_name = "SECOND.LEVEL.NAME"
	new_level_metadata.level_scene = load("res://scenes/gameplay/world/level/levels/level_{0}.tscn".format([new_level_metadata.id]))

	current_level.queue_free()
	await current_level.tree_exited

	var new_level: ILevel = new_level_metadata.level_scene.instantiate()
	ILevel.current_level = new_level
	get_tree().get_root().add_child(new_level)
	new_level.initialize(new_level_metadata)
	Global.ui.start_level()

	Global.paused = false
	queue_free()


## Returns to the main menu and cleans up the current level.
func _on_home_texture_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")
	ILevel.current_level.queue_free()
	Global.paused = false
