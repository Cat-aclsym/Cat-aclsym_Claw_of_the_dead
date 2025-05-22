class_name LevelIndicator extends TextureButton

enum Status {
	CURRENT,
	COMPLETED,
	LOCKED
}

var status := LevelIndicator.Status.CURRENT
var level := 0

var textures: Dictionary = {
	LevelIndicator.Status.CURRENT: preload("res://assets/ui/level_selection/bt_level/level_current.svg"),
	LevelIndicator.Status.COMPLETED: preload("res://assets/ui/level_selection/bt_level/level_done.svg"),
	LevelIndicator.Status.LOCKED: null
}

@onready var label: Label = $Label

# core


# public
func configure(in_level: int, in_status: LevelIndicator.Status) -> void:
	level = in_level
	status = in_status
	update()
	

func update() -> void:
	label.text = str(level)
	disabled = status == LevelIndicator.Status.LOCKED
	if not disabled:
		texture_normal = textures[status]

# private


# signal


# event


# setget

