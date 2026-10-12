## © [2026] A7 Studio. All rights reserved. Trademark.
##
## Small level indicator on level selection menu
## @experimental
class_name LevelIndicator extends TextureButton

signal selected(indicator: LevelIndicator)

enum Status {
	CURRENT,
	COMPLETED,
	LOCKED,
	ERROR
}

var level: int = 0
var status: LevelIndicator.Status = LevelIndicator.Status.CURRENT
var textures: Dictionary[LevelIndicator.Status, Texture2D] = {
	LevelIndicator.Status.CURRENT: preload("res://assets/ui/level_selection/bt_level/Level_number.png"),
	LevelIndicator.Status.COMPLETED: preload("res://assets/ui/level_selection/bt_level/Level_number2.png"),
	LevelIndicator.Status.LOCKED: null
}

@onready var label: Label = $Label

@onready var signals: Array[Dictionary] = [
	{SignalUtil.WHO: self, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_pressed}
]


func configure(in_level: int, in_status: LevelIndicator.Status) -> void:
	level = in_level
	status = in_status
	SignalUtil.connects(signals)
	update()
	ButtonEffects.apply(self)


func update() -> void:
	label.text = str(level)
	disabled = status == LevelIndicator.Status.LOCKED
	if not disabled:
		texture_normal = textures[status]


func _on_pressed() -> void:
	selected.emit(self)
