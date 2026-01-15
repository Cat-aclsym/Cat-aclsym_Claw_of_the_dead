## © [2026] A7 Studio. All rights reserved. Trademark.

class_name EndGame
extends Control
## Manages the win screen interface and UI interactions.
##
## Displays level statistics (time, life) and challenge results.
## Handles navigation back to menus or next level.

# Constants
const CONDITION_DONE: Texture2D = preload("res://assets/ui/level_selection/window/condition_done.svg")
const CONDITION_TODO: Texture2D = preload("res://assets/ui/level_selection/window/condition_todo.svg")


# Variables
var elapsed_time_minutes: int
var elapsed_time_seconds: int
var elapsed_time_text: String

@onready var challenges_vbox: VBoxContainer = $GUIMarginContainer/BackgroundTextureRect/ContentMarginContainer/VBoxContainerMain/ChallengesVBoxContainer
@onready var end_game_image: TextureRect = $GUIMarginContainer/BackgroundTextureRect/ContentMarginContainer/VBoxContainerMain/ResultIconTextureRect
@onready var home_button: TextureButton = $GUIMarginContainer/BackgroundTextureRect/ContentMarginContainer/VBoxContainerMain/ButtonsHBoxContainer/HomeButtonAspectRatioContainer/HomeTextureButton
@onready var life_label: Label = $GUIMarginContainer/BackgroundTextureRect/ContentMarginContainer/VBoxContainerMain/StatsHBoxContainer/LifeAspectRatioContainer/LifeHBoxContainer/LifeStatisticLabel
@onready var next_button: TextureButton = $GUIMarginContainer/BackgroundTextureRect/ContentMarginContainer/VBoxContainerMain/ButtonsHBoxContainer/NextButtonAspectRatioContainer/NextTextureButton
@onready var restart_button: TextureButton = $GUIMarginContainer/BackgroundTextureRect/ContentMarginContainer/VBoxContainerMain/ButtonsHBoxContainer/RestartButtonAspectRatioContainer/RestartTextureButton
@onready var time_label: Label = $GUIMarginContainer/BackgroundTextureRect/ContentMarginContainer/VBoxContainerMain/StatsHBoxContainer/TimeAspectRatioContainer/TimeHBoxContainer/TimeStatisticLabel
@onready var title_label: Label = $GUIMarginContainer/BackgroundTextureRect/ContentMarginContainer/VBoxContainerMain/TitleLabel

@onready var default_health_text: String = life_label.text
@onready var default_time_text: String = time_label.text

@onready var signals: Array[Dictionary] = [
	{SignalUtil.WHO: home_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_home_texture_button_pressed},
	{SignalUtil.WHO: restart_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_restart_texture_button_pressed},
	{SignalUtil.WHO: next_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_next_texture_button_pressed}
]


# Built-in functions
func _ready() -> void:
	SignalUtil.connects(signals)


# Public functions
## Initializes the end game screen with victory or defeat state.
func init(victory: bool) -> void:
	if Global.ui.get_node("TowerSelection") :
		Global.ui.get_node("TowerSelection").queue_free()
		Global.hud.get_node("TowerSelectionMarginContainer/TowerSelectionButton").set_pressed_no_signal(false)

	assert(time_label != null, "time_label node not found")
	assert(life_label != null, "life_label node not found")
	assert(home_button != null, "home_button node not found")
	assert(restart_button != null, "restart_button node not found")
	assert(next_button != null, "next_button node not found")

	elapsed_time_seconds = floor(ILevel.current_level.end_time - ILevel.current_level.start_time)
	elapsed_time_minutes = floor(elapsed_time_seconds / 60.)

	if elapsed_time_seconds > 60:
		elapsed_time_seconds = elapsed_time_seconds - (elapsed_time_minutes * 60)
		elapsed_time_text = str(elapsed_time_minutes) + "m " + str(elapsed_time_seconds) + "s"
	else:
		elapsed_time_text = str(elapsed_time_seconds) + "s"
	time_label.text = tr(default_time_text) % str(elapsed_time_text)
	life_label.text = tr(default_health_text) % (str(ILevel.current_level.health) + "/20")

	if victory:
		title_label.text = tr("ENDGAMEMENU.LEVEL.TITLE.WIN")
		end_game_image.texture = ResourceLoader.load("res://assets/ui/icons/Victory Gold.svg")
		ProgressionManager.complete_level(ILevel.current_level.level_id)
	else:
		title_label.text = tr("ENDGAMEMENU.LEVEL.TITLE.LOOSE")
		end_game_image.texture = ResourceLoader.load("res://assets/ui/icons/Defeat.svg")
		next_button.get_parent().visible = false

	_display_challenges()


# Private functions
func _display_challenges() -> void:
	for child in challenges_vbox.get_children():
		child.queue_free()

	var active_challenges := ChallengeManager.get_active_challenges()
	for challenge in active_challenges:
		var hbox := HBoxContainer.new()
		hbox.alignment = BoxContainer.ALIGNMENT_CENTER
		hbox.add_theme_constant_override("separation", 15)

		var icon_rect := TextureRect.new()
		icon_rect.custom_minimum_size = Vector2(30, 30)
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.texture = CONDITION_DONE if challenge.is_completed else CONDITION_TODO

		var label := Label.new()
		label.text = tr(challenge.title) + ": " + tr(challenge.description)
		label.add_theme_font_override("font", load("res://assets/ui/fonts/dotgothic/DotGothic16-Regular.ttf"))
		label.add_theme_font_size_override("font_size", 20)

		hbox.add_child(icon_rect)
		hbox.add_child(label)
		challenges_vbox.add_child(hbox)

func _on_home_texture_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")
	ILevel.current_level.queue_free()
	Global.paused = false


func _on_next_texture_button_pressed() -> void:
	var current_level := ILevel.current_level
	var next_level_id := ProgressionManager.get_next_level_id(current_level.level_id)
	var next_level_path := "res://scenes/gameplay/world/level/levels/%s.tscn" % next_level_id

	if not ResourceLoader.exists(next_level_path):
		Log.trace(Log.Level.ERROR, "Next level scene not found: " + next_level_path)
		_on_home_texture_button_pressed()
		return

	var level_scene: PackedScene = load(next_level_path)

	current_level.queue_free()
	await current_level.tree_exited

	var new_level: ILevel = level_scene.instantiate()
	ILevel.current_level = new_level
	get_tree().get_root().add_child(new_level)
	new_level.start_level()
	Global.ui.start_level()

	Global.paused = false
	queue_free()


func _on_restart_texture_button_pressed() -> void:
	var current_level := ILevel.current_level
	var level_scene: PackedScene = load(current_level.get_scene_file_path())

	current_level.queue_free()
	await current_level.tree_exited

	var new_level: ILevel = level_scene.instantiate()
	get_tree().get_root().add_child(new_level)
	new_level.start_level()
	Global.ui.start_level()

	Global.paused = false
	queue_free()
