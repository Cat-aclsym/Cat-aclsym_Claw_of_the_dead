## © [2026] A7 Studio. All rights reserved. Trademark.

class_name SplitterZombie
extends IEnemy

## The scene of the small zombie to spawn upon death
const SMALL_ZOMBIE_SCENE = preload("res://scenes/gameplay/entities/enemy/enemies/small_zombie.tscn")

## Number of small zombies to spawn
const SPAWN_COUNT: int = 4

## Visual tint for the splitter zombie
const SPLITTER_TINT: Color = Color(1.0, 0.3, 0.3, 1.0)


func _ready() -> void:
	super._ready()
	old_modulate = SPLITTER_TINT
	sprite.modulate = SPLITTER_TINT


## Overriding _dead_state to implement splitting logic
func _dead_state() -> void:
	_spawn_small_zombies()
	super._dead_state()


func _spawn_small_zombies() -> void:
	if path == null or path_follow == null:
		return
		
	var current_progress = path_follow.get_progress()
	
	for i in range(SPAWN_COUNT):
		var small_zombie: IEnemy = SMALL_ZOMBIE_SCENE.instantiate()
		
		# Add a bit of randomness to the progress to avoid overlapping
		var random_offset = randf_range(-10.0, 10.0)
		
		# We use the EnemySpawner to handle the PathFollow2D creation
		EnemySpawner.spawn_enemy(path, small_zombie)
		
		# Adjust the progress of the newly created PathFollow2D
		if small_zombie.path_follow:
			small_zombie.path_follow.set_progress(max(0.0, current_progress + random_offset))
			# Add vertical offset randomness too
			small_zombie.path_follow.v_offset += randf_range(-5.0, 5.0)
	
	Log.trace(Log.Level.DEBUG, "SplitterZombie spawned %d small zombies at progress %f" % [SPAWN_COUNT, current_progress])
