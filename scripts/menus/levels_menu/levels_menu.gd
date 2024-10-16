class_name LevelsMenu
extends Control

signal menu_close
signal level_selected

@onready var container: VBoxContainer = $GuiMarginContainer/MenuMarginContainer/LevelSelectVBoxContainer
var buttons: Dictionary = {}

# core
func _ready() -> void:
	_initialize()


# public


# private
func _initialize() -> void:
	for node in container.get_children():
		if not node is AspectRatioContainer:
			continue
		var button: TextureButton = node.get_child(0)
		var level_label: Label = button.get_child(0)
		var level_metadata: LevelMetadata = button.get_child(1)
		buttons[level_label] = level_metadata

	for bt in buttons:
		var metadata: LevelMetadata = buttons[bt]
		bt.text = "{0}".format([tr(metadata.level_name)])
		bt.get_parent().connect("pressed",
		func():
			assert(metadata.level_scene != null, "Level scene is null.")
			visible = false

			var level: ILevel = metadata.level_scene.instantiate()
			get_tree().get_root().add_child(level)
			level.initialize(metadata)
			ILevel.current_level = level

			Global.hud.start_level()
			emit_signal("level_selected")
		)


# signal


# event


# setget
