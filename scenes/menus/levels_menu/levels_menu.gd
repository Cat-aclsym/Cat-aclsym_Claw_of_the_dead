extends Control

var buttons: Dictionary = {}

@onready var container: VBoxContainer = $VBoxContainer

# core
func _ready() -> void:
	_initialize()
	
	
# functionnal

# internal
func _initialize() -> void:
	for button in container.get_children():
		buttons[button] = button.get_child(0)
	
	for bt in buttons:
		bt.text = "{0} - {1}".format([buttons[bt].id, buttons[bt].level_name])
		bt.connect("pressed", 
		func():
			assert(buttons[bt].level_scene != null, "Level scene is null.")
			visible = false
			
			var level: ILevel = buttons[bt].level_scene.instantiate()
			get_tree().get_root().add_child(level)
			level.initialize(buttons[bt])
			)

# signals
