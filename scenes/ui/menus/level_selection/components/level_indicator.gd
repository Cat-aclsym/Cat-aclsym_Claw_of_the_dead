## © [2024] A7 Studio. All rights reserved. Trademark.
##
## Small level indicator on level selection menu
class_name LevelIndicator extends TextureButton

signal selected(LevelIndicator)

enum Status {
	CURRENT,
	COMPLETED,
	LOCKED,
	ERROR
}

var status := LevelIndicator.Status.CURRENT
var level := 0

var textures: Dictionary = {
	LevelIndicator.Status.CURRENT: preload("res://assets/ui/level_selection/bt_level/level_current.svg"),
	LevelIndicator.Status.COMPLETED: preload("res://assets/ui/level_selection/bt_level/level_done.svg"),
	LevelIndicator.Status.LOCKED: null
}

@onready var label: Label = $Label

@onready var signals: Array[Dictionary] = [
	{SignalUtil.WHO: self, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_pressed}
]

# core


# public
func configure(in_level: int, in_status: LevelIndicator.Status) -> void:
	level = in_level
	status = in_status
	SignalUtil.connects(signals)
	update()


func update() -> void:
	label.text = str(level)
	disabled = status == LevelIndicator.Status.LOCKED
	if not disabled:
		texture_normal = textures[status]

static func string_to_status(s: String) -> LevelIndicator.Status:
	match s:
		"current":
			return LevelIndicator.Status.CURRENT
		"done":
			return LevelIndicator.Status.COMPLETED
		"locked":
			return LevelIndicator.Status.LOCKED
	return LevelIndicator.Status.ERROR

# private


# signal
func _on_pressed() -> void:
	selected.emit(self)

# event


# setget

