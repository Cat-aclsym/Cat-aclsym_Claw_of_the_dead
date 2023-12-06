extends CharacterBody2D

@onready var path = get_parent()

var speed = 100

func _ready():
	pass
	
func _physics_process(delta):
	follow_path(path, delta)

func follow_path(path, delta) -> void:
	if path.get_progress_ratio() >= 1:
		# path finished
		# _hit_state()
		self.queue_free() # destroy enemy
		return
	path.set_progress(path.get_progress() +(speed * delta))
	# todo: walk animation
