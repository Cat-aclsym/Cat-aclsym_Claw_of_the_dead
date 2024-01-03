extends CharacterBody2D

@onready var path = get_parent()

var speed = 100

func _ready():
	pass
	
func _physics_process(delta):
	follow_path(path, delta)

func _die():
	# play death animation, wait for it to finish, then queue_free()
	# todo: add money
	# todo: play sound
	# todo: decrease enemy count
	$AnimationPlayer.play("Death")
	await $AnimationPlayer.animation_finished
	queue_free()

func follow_path(path, delta) -> void:
	if path.get_progress_ratio() >= 1:
		# path finished
		# _hit_state()
		self.queue_free() # destroy enemy
		return
	path.set_progress(path.get_progress() +(speed * delta))
	# todo: walk animation
