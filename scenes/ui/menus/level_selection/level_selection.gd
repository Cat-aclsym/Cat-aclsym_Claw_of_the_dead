## © [2024] A7 Studio. All rights reserved. Trademark.
##
## Manages the level selection menu interface and functionality.
## Handles level loading and initialization of level metadata.
class_name LevelSelection
extends Control

# signals
signal menu_close
signal level_selected

## Dictionary containing level selection buttons and their metadata.
var _buttons: Dictionary = {}

## Contains the level selection buttons and metadata.
@onready var container: VBoxContainer = $GuiMarginContainer/MenuMarginContainer/LevelSelectVBoxContainer

# core
func _ready() -> void:
	assert(container != null, "container node not found")
	_initialize()

# private
## Initializes the level selection menu by setting up level buttons and their metadata.
## [br]Connects button signals to handle level loading when selected.
func _initialize() -> void:
	for node in container.get_children():
		if not node is AspectRatioContainer:
			continue
		var button: TextureButton = node.get_child(0)
		var level_label: Label = button.get_child(0)
		var level: ILevel = button.get_child(1)
		_buttons[level_label] = level

	for bt in _buttons:
		var level: ILevel = _buttons[bt]
		bt.text = "{0}".format([tr(level.level_name)])
		bt.get_parent().connect("pressed",
		func() -> void:
			visible = false

			level.reparent(get_tree().get_root())
			level.start_level()

			Global.ui.start_level()
			level_selected.emit()
		)
