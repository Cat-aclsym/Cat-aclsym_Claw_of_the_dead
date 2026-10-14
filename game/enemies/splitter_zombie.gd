## © [2026] A7 Studio. All rights reserved. Trademark.

class_name SplitterZombie
extends IEnemy

## Visual tint for the splitter zombie
const SPLITTER_TINT: Color = Color(1.0, 0.3, 0.3, 1.0)

## Number of small zombies to spawn
var spawn_count: int


func _ready() -> void:
	super._ready()
	old_modulate = SPLITTER_TINT
	sprite.modulate = SPLITTER_TINT


## Overriding _dead_state to implement splitting logic
func _dead_state() -> void:
	_spawn_small_zombies()
	super._dead_state()


func _spawn_small_zombies() -> void:
	if path == null or path_follow == null or not is_instance_valid(ILevel.current_level):
		return

	var small_zombie_scene: PackedScene = StatsDB.get_enemy_scene("small_zombie")
	if small_zombie_scene == null:
		return

	var current_progress: float = path_follow.get_progress()

	for i in range(spawn_count):
		var small_zombie: IEnemy = small_zombie_scene.instantiate()

		# Add a bit of randomness to the progress to avoid overlapping
		var random_offset: float = randf_range(-10.0, 10.0)

		# The level creates the PathFollow2D
		ILevel.current_level.spawn_enemy(path, small_zombie)

		# Adjust the progress of the newly created PathFollow2D
		if small_zombie.path_follow:
			small_zombie.path_follow.set_progress(max(0.0, current_progress + random_offset))
			# Add vertical offset randomness too
			small_zombie.path_follow.v_offset += randf_range(-5.0, 5.0)
