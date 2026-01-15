## © [2026] A7 Studio. All rights reserved. Trademark.

class_name Challenge103
extends Challenge
## Challenge: Half-Half
## No enemy must reach halfway through the path.


# Built-in functions
func _process(_delta: float) -> void:
	if is_failed or is_completed:
		return

	var enemies: Array[Node] = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if not is_instance_valid(enemy) or enemy.is_already_dead:
			continue

		if enemy.path_follow and enemy.path_follow.get_progress_ratio() > 0.5:
			Log.trace(Log.Level.DEBUG, "Challenge [%s] failed: enemy reached halfway" % title)
			fail()
			return
