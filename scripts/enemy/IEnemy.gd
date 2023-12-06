extends CharacterBody2D

@onready var path_follow = get_parent()

var speed = 40

func _ready():
	pass
	
func _physics_process(delta):
		path_follow.set_progress(path_follow.get_progress() +(speed * delta))
