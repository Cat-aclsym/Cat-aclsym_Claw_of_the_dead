## © [2026] A7 Studio. All rights reserved. Trademark.

class_name ChallengeCard
extends MarginContainer

const DIFFICULTY_COLORS: Dictionary = {
	"Easy": Color(0.45, 0.85, 0.4),
	"Hard": Color(0.9, 0.3, 0.3),
	"Impossible": Color(0.75, 0.25, 0.85),
	"Medium": Color(0.9, 0.7, 0.2),
}
const ICON_DONE: Texture2D = preload("res://assets/ui/level_selection/window/condition_done.svg")
const ICON_TODO: Texture2D = preload("res://assets/ui/level_selection/window/condition_todo.svg")

@onready var desc_label: Label = %DescLabel
@onready var diff_label: Label = %DiffLabel
@onready var status_icon: TextureRect = %StatusIcon
@onready var title_label: Label = %TitleLabel


func setup(c: Challenge, is_done: bool) -> void:
	desc_label.text = tr(c.description)
	diff_label.add_theme_color_override("font_color", DIFFICULTY_COLORS.get(c.difficulty, Color.WHITE))
	diff_label.text = tr("CHALLENGE.DIFFICULTY.%s" % c.difficulty.to_upper())
	status_icon.texture = ICON_DONE if is_done else ICON_TODO
	title_label.text = tr(c.title)

	SignalUtil.connects([
		{SignalUtil.WHO: c, SignalUtil.WHAT: "completed", SignalUtil.TO: func(_id: String) -> void: status_icon.texture = ICON_DONE},
		{SignalUtil.WHO: c, SignalUtil.WHAT: "failed", SignalUtil.TO: func(_id: String) -> void: status_icon.texture = ICON_TODO},
	])
