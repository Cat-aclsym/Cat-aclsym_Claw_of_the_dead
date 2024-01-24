extends Node2D

@onready var lebel = $Label

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	lebel.text = "{0}, {1}".format([get_global_mouse_position().x, get_global_mouse_position().y])
