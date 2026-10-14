## © [2026] A7 Studio. All rights reserved. Trademark.

class_name ChallengeCard
extends MarginContainer

## Theme variation of the difficulty label per difficulty, [code]CardText[/code] for an unknown one.
const DIFFICULTY_VARIATIONS: Dictionary[String, StringName] = {
	"Easy": &"DifficultyEasy",
	"Hard": &"DifficultyHard",
	"Impossible": &"DifficultyImpossible",
	"Medium": &"DifficultyMedium",
}
const ICON_DONE: Texture2D = preload("res://assets/ui/icons/star.png")
const ICON_TODO: Texture2D = preload("res://assets/ui/icons/star_empty.png")
const TINT_DEFAULT: Color = Color.WHITE
const TINT_FAILED: Color = Color(1.0, 0.35, 0.35, 1.0)

var _challenge_id: String = ""
var _difficulty: String = ""

@onready var desc_label: Label = %DescLabel
@onready var diff_label: Label = %DiffLabel
@onready var status_icon: TextureRect = %StatusIcon
@onready var title_label: Label = %TitleLabel


func setup(c: Challenge, is_done: bool) -> void:
	_challenge_id = c.id
	_difficulty = c.difficulty
	desc_label.text = tr(c.description)
	title_label.text = tr(c.title)
	_apply_status_visual(is_done, c.is_failed)

	SignalUtil.connects([
		{SignalUtil.WHO: ChallengeManager, SignalUtil.WHAT: "challenge_status_updated", SignalUtil.TO: _on_challenge_status_updated},
	])


func _apply_failed_visual(is_failed: bool) -> void:
	if is_failed:
		title_label.theme_type_variation = &"CardTitleFailed"
		desc_label.theme_type_variation = &"CardTextFailed"
		diff_label.theme_type_variation = &"CardTextFailed"
		diff_label.text = tr("CHALLENGE.STATUS.FAILED")
		return

	title_label.theme_type_variation = &"CardTitle"
	desc_label.theme_type_variation = &"CardText"
	diff_label.theme_type_variation = DIFFICULTY_VARIATIONS.get(_difficulty, &"CardText")
	diff_label.text = tr("CHALLENGE.DIFFICULTY.%s" % _difficulty.to_upper())


func _apply_status_visual(is_completed: bool, is_failed: bool) -> void:
	if is_failed:
		status_icon.texture = ICON_DONE
		status_icon.modulate = TINT_FAILED
		_apply_failed_visual(true)
		return
	status_icon.modulate = TINT_DEFAULT
	status_icon.texture = ICON_DONE if is_completed else ICON_TODO
	_apply_failed_visual(false)


func _on_challenge_status_updated(challenge_id: String, is_completed: bool, is_failed: bool) -> void:
	if challenge_id != _challenge_id:
		return
	_apply_status_visual(is_completed, is_failed)
