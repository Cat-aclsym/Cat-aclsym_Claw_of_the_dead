extends Control

var buttons: Dictionary = {}

@onready var container: VBoxContainer = $CenterContainer/LevelSelectVBoxContainer


# core
func _ready() -> void: _initialize()


# functionnal

# internal
func _initialize() -> void:
	for button in container.get_children():
		if not button is TextureButton:
			continue
		buttons[button.get_child(0)] = button.get_child(1)

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
		)

		# signals
