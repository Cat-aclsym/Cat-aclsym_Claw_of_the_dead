## © [2026] A7 Studio. All rights reserved. Trademark.

class_name EndGame
extends Control
## Manages the win screen interface and UI interactions.
##
## Displays level statistics (time, life) and challenge results.
## Handles navigation back to menus or next level.

# Constants
const CONDITION_DONE: Texture2D = preload("res://assets/ui/icons/star.png")
const CONDITION_TODO: Texture2D = preload("res://assets/ui/icons/star_empty.png")
const DEFEAT_ICON: Texture2D = preload("res://assets/ui/icons/defeat.svg")
const TINT_DEFAULT: Color = Color.WHITE
const TINT_FAILED: Color = Color(1.0, 0.35, 0.35, 1.0)
const VICTORY_ICON: Texture2D = preload("res://assets/ui/icons/victory_gold.svg")


# Variables
var elapsed_time_minutes: int
var elapsed_time_seconds: int
var elapsed_time_text: String
var _is_victory: bool = true

@onready var challenges_vbox: VBoxContainer = $GUIMarginContainer/BackgroundTextureRect/ContentMarginContainer/VBoxContainerMain/ChallengesVBoxContainer
@onready var end_game_image: TextureRect = $GUIMarginContainer/BackgroundTextureRect/ContentMarginContainer/VBoxContainerMain/ResultIconTextureRect
@onready var home_button: GameButton =$GUIMarginContainer/BackgroundTextureRect/ContentMarginContainer/VBoxContainerMain/ButtonsHBoxContainer/HomeButtonAspectRatioContainer/HomeTextureButton
@onready var life_label: Label = $GUIMarginContainer/BackgroundTextureRect/ContentMarginContainer/VBoxContainerMain/StatsHBoxContainer/LifeAspectRatioContainer/LifeHBoxContainer/LifeStatisticLabel

@onready var default_health_text: String = life_label.text
@onready var next_button: GameButton =$GUIMarginContainer/BackgroundTextureRect/ContentMarginContainer/VBoxContainerMain/ButtonsHBoxContainer/NextButtonAspectRatioContainer/NextTextureButton
@onready var restart_button: GameButton =$GUIMarginContainer/BackgroundTextureRect/ContentMarginContainer/VBoxContainerMain/ButtonsHBoxContainer/RestartButtonAspectRatioContainer/RestartTextureButton

@onready var signals: Array[Dictionary] = [
	{SignalUtil.WHO: home_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_home_texture_button_pressed},
	{SignalUtil.WHO: restart_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_restart_texture_button_pressed},
	{SignalUtil.WHO: next_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_next_texture_button_pressed}
]
@onready var time_label: Label = $GUIMarginContainer/BackgroundTextureRect/ContentMarginContainer/VBoxContainerMain/StatsHBoxContainer/TimeAspectRatioContainer/TimeHBoxContainer/TimeStatisticLabel
@onready var default_time_text: String = time_label.text
@onready var title_label: Label = $GUIMarginContainer/BackgroundTextureRect/ContentMarginContainer/VBoxContainerMain/TitleLabel


# Built-in functions
func _ready() -> void:
	assert(challenges_vbox != null, "challenges_vbox node not found")
	assert(end_game_image != null, "end_game_image node not found")
	assert(home_button != null, "home_button node not found")
	assert(life_label != null, "life_label node not found")
	assert(next_button != null, "next_button node not found")
	assert(restart_button != null, "restart_button node not found")
	assert(time_label != null, "time_label node not found")
	assert(title_label != null, "title_label node not found")
	SignalUtil.connects(signals)


# Public functions
## Initializes the end game screen with victory or defeat state.
func init(victory: bool) -> void:
	_is_victory = victory
	var build_menu := Global.ui.get_node_or_null("BuildSelection")
	if build_menu:
		build_menu.queue_free()

	var build_menu_button := Global.hud.get_node_or_null("BuildSelectionMarginContainer/BuildSelectionButton")
	if build_menu_button:
		build_menu_button.set_pressed_no_signal(false)

	elapsed_time_seconds = floori(ILevel.current_level.elapsed_time)
	elapsed_time_minutes = floor(elapsed_time_seconds / 60.)

	if elapsed_time_seconds > 60:
		elapsed_time_seconds = elapsed_time_seconds - (elapsed_time_minutes * 60)
		elapsed_time_text = str(elapsed_time_minutes) + "m " + str(elapsed_time_seconds) + "s"
	else:
		elapsed_time_text = str(elapsed_time_seconds) + "s"
	time_label.text = tr(default_time_text) % str(elapsed_time_text)
	life_label.text = tr(default_health_text) % (str(ILevel.current_level.health) + "/" + str(ILevel.current_level.max_health))

	if victory:
		title_label.text = tr("ENDGAMEMENU.LEVEL.TITLE.WIN")
		title_label.theme_type_variation = &"VictoryTitle"
		end_game_image.texture = VICTORY_ICON
		ProgressionManager.complete_level(ILevel.current_level.level_id)
		Narrative.play_once(&"first_victory_seen", "first_victory")
	else:
		title_label.text = tr("ENDGAMEMENU.LEVEL.TITLE.LOSE")
		title_label.theme_type_variation = &"DefeatTitle"
		end_game_image.texture = DEFEAT_ICON
		next_button.get_parent().visible = false
		Narrative.play_once(&"first_defeat_seen", "first_defeat")

	_display_challenges()


# Private functions
func _display_challenges() -> void:
	for child in challenges_vbox.get_children():
		child.queue_free()

	var active_challenges := ChallengeManager.get_active_challenges()
	for challenge in active_challenges:
		var hbox := HBoxContainer.new()
		hbox.alignment = BoxContainer.ALIGNMENT_CENTER
		hbox.theme_type_variation = &"ChallengeLine"

		var icon_rect := TextureRect.new()
		icon_rect.custom_minimum_size = Vector2(30, 30)
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var is_done: bool = challenge.is_completed
		var is_failed_visual: bool = challenge.is_failed or (not _is_victory and not is_done)
		if is_failed_visual:
			icon_rect.texture = CONDITION_DONE
			icon_rect.modulate = TINT_FAILED
		else:
			icon_rect.texture = CONDITION_DONE if is_done else CONDITION_TODO
			icon_rect.modulate = TINT_DEFAULT

		var label := Label.new()
		label.text = tr(challenge.title) + ": " + tr(challenge.description)
		label.theme_type_variation = &"BodyText"

		hbox.add_child(icon_rect)
		hbox.add_child(label)
		challenges_vbox.add_child(hbox)

func _on_home_texture_button_pressed() -> void:
	ScenesLoader.go_home()


func _on_next_texture_button_pressed() -> void:
	var next_level_id: String = ProgressionManager.get_next_level_id(ILevel.current_level.level_id)
	if not ResourceLoader.exists(ScenesLoader.LEVEL_SCENE_PATH % next_level_id):
		Log.trace(Log.Level.ERROR, "Next level scene not found: " + next_level_id)
		ScenesLoader.go_home()
		return

	await ScenesLoader.start_level(next_level_id)
	queue_free()


func _on_restart_texture_button_pressed() -> void:
	await ScenesLoader.start_level(ILevel.current_level.level_id)
	queue_free()
