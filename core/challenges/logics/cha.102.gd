## © [2026] A7 Studio. All rights reserved. Trademark.

class_name Challenge102
extends Challenge
## Challenge: Social Distancing
## No tower may be in the range of another one.

# Public functions
## Notifies the challenge that a tower has been placed.
func on_tower_placed(tower: ITower) -> void:
	if not is_instance_valid(ILevel.current_level) or not is_instance_valid(ILevel.current_level.map):
		return

	# Towers are placed as children of the map
	for child: Node in ILevel.current_level.map.get_children():
		if child is ITower and child != tower and _is_in_range(tower, child as ITower):
			fail()
			return


# Private functions
## True when one of the two towers is inside the shooting range of the other.
func _is_in_range(t1: ITower, t2: ITower) -> bool:
	var distance: float = t1.global_position.distance_to(t2.global_position)
	return distance <= maxf(t1.shoot_range, t2.shoot_range)
