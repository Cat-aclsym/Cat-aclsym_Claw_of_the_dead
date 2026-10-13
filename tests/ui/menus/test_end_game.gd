## © [2026] A7 Studio. All rights reserved. Trademark.
##
## [EndGame]: the title takes the victory or the defeat theme variation.
extends GdUnitTestSuite

const END_GAME_SCENE: PackedScene = preload("res://ui/menus/end_game/end_game.tscn")
const UI_SCENE: PackedScene = preload("res://ui/ui.tscn")

var _data_before: ProgressionData = null
var _hud_before: HUD = null
var _level_before: ILevel = null
var _persistence_before: bool = true
var _ui_before: UI = null


func before_test() -> void:
	_data_before = ProgressionManager.data
	_hud_before = Global.hud
	_level_before = ILevel.current_level
	_persistence_before = ProgressionManager.persistence_enabled
	_ui_before = Global.ui
	ProgressionManager.data = ProgressionData.new()
	ProgressionManager.persistence_enabled = false
	ProgressionManager.data.parameters.flags["first_victory_seen"] = true
	ProgressionManager.data.parameters.flags["first_defeat_seen"] = true


func after_test() -> void:
	ProgressionManager.data = _data_before
	ProgressionManager.persistence_enabled = _persistence_before
	Global.hud = _hud_before if is_instance_valid(_hud_before) else null
	Global.ui = _ui_before if is_instance_valid(_ui_before) else null
	ILevel.current_level = _level_before if is_instance_valid(_level_before) else null
	Global.clear_pauses()


func test_a_victory_shows_the_victory_title_variation() -> void:
	var end_game: EndGame = _open(true)

	assert_str(end_game.title_label.theme_type_variation).is_equal(&"VictoryTitle")
	assert_str(end_game.title_label.text).is_equal(tr("ENDGAMEMENU.LEVEL.TITLE.WIN"))


func test_a_defeat_shows_the_defeat_title_variation() -> void:
	var end_game: EndGame = _open(false)

	assert_str(end_game.title_label.theme_type_variation).is_equal(&"DefeatTitle")
	assert_str(end_game.title_label.text).is_equal(tr("ENDGAMEMENU.LEVEL.TITLE.LOSE"))


func test_the_challenge_lines_use_the_challenge_line_and_body_variations() -> void:
	var end_game: EndGame = _open(true)
	var challenge: Challenge = auto_free(Challenge.new("cha.test", "CHALLENGE.TITLE", "CHALLENGE.DESC", "Easy"))
	ChallengeManager.active_challenges.append(challenge)

	end_game._display_challenges()
	ChallengeManager.active_challenges.erase(challenge)

	var line: HBoxContainer = end_game.challenges_vbox.get_child(0)
	assert_str(line.theme_type_variation).is_equal(&"ChallengeLine")
	assert_str(line.get_child(1).theme_type_variation).is_equal(&"BodyText")


func _open(victory: bool) -> EndGame:
	var ui: UI = auto_free(UI_SCENE.instantiate())
	add_child(ui)
	var level: ILevel = auto_free(ILevel.new())
	level.level_id = "lev.01"
	ILevel.current_level = level
	var end_game: EndGame = auto_free(END_GAME_SCENE.instantiate())
	add_child(end_game)
	end_game.init(victory)
	return end_game
