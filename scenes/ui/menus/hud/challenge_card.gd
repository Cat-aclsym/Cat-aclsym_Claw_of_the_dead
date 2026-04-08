## © [2026] A7 Studio. All rights reserved. Trademark.

class_name ChallengeCard
extends MarginContainer

const DIFFICULTY_COLORS: Dictionary = {
	"Easy": Color(0.45, 0.85, 0.4),
	"Hard": Color(0.9, 0.3, 0.3),
	"Impossible": Color(0.75, 0.25, 0.85),
	"Medium": Color(0.9, 0.7, 0.2),
}
const ICON_DONE: Texture2D = preload("res://assets/ui/icons/Star.png")
const ICON_TODO: Texture2D = preload("res://assets/ui/icons/Star_Empty.png")
const TINT_DEFAULT: Color = Color.WHITE
const TINT_FAILED: Color = Color(1.0, 0.35, 0.35, 1.0)
const TEXT_FAILED: Color = Color(1.0, 0.35, 0.35, 1.0)
const TEXT_DEFAULT: Color = Color.WHITE

@onready var desc_label: Label = %DescLabel
@onready var diff_label: Label = %DiffLabel
@onready var status_icon: TextureRect = %StatusIcon
@onready var title_label: Label = %TitleLabel
var _challenge_id: String = ""
var _difficulty: String = ""


func setup(c: Challenge, is_done: bool) -> void:
	_challenge_id = c.id
	_difficulty = c.difficulty
	desc_label.text = tr(c.description)
	title_label.text = tr(c.title)
	_apply_status_visual(is_done, c.is_failed)

	SignalUtil.connects([
		{SignalUtil.WHO: ChallengeManager, SignalUtil.WHAT: "challenge_status_updated", SignalUtil.TO: _on_challenge_status_updated},
	])


func _on_challenge_status_updated(challenge_id: String, is_completed: bool, is_failed: bool) -> void:
	if challenge_id != _challenge_id:
		return
	_apply_status_visual(is_completed, is_failed)


func _apply_status_visual(is_completed: bool, is_failed: bool) -> void:
	if is_failed:
		status_icon.texture = ICON_DONE
		status_icon.modulate = TINT_FAILED
		_apply_failed_visual(true)
		return
	status_icon.modulate = TINT_DEFAULT
	status_icon.texture = ICON_DONE if is_completed else ICON_TODO
	_apply_failed_visual(false)


func _apply_failed_visual(is_failed: bool) -> void:
	if is_failed:
		title_label.add_theme_color_override("font_color", TEXT_FAILED)
		desc_label.add_theme_color_override("font_color", TEXT_FAILED)
		diff_label.add_theme_color_override("font_color", TEXT_FAILED)
		diff_label.text = tr("CHALLENGE.STATUS.FAILED")
		return

	title_label.add_theme_color_override("font_color", TEXT_DEFAULT)
	desc_label.add_theme_color_override("font_color", TEXT_DEFAULT)
	diff_label.add_theme_color_override("font_color", DIFFICULTY_COLORS.get(_difficulty, Color.WHITE))
	diff_label.text = tr("CHALLENGE.DIFFICULTY.%s" % _difficulty.to_upper())
