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
		buttons[node.get_child(0).get_child(0)] = node.get_child(0).get_child(1) # yo wtf ?

	for bt in buttons:
		bt.text = "{0}".format([tr(buttons[bt].level_name)])
		bt.get_parent().connect("pressed",
		func():
			assert(buttons[bt].level_scene != null, "Level scene is null.")
			visible = false

			var level: ILevel = buttons[bt].level_scene.instantiate()
			get_tree().get_root().add_child(level)
			level.initialize(buttons[bt])
			ILevel.current_level = level

			Global.hud.start_level()
			emit_signal("level_selected")
		)


# signal


# event


# setget

