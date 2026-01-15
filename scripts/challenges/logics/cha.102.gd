## © [2026] A7 Studio. All rights reserved. Trademark.

class_name Challenge102
extends Challenge
## Challenge: Social Distancing
## Towers must be placed far enough from each other.

# Public functions
## Notifies the challenge that a tower has been placed.
func on_tower_placed(tower: ITower) -> void:
	if not (tower is ITower):
		return

	# Check distance with all other towers
	if not ILevel.current_level or not ILevel.current_level.map:
		return

	for child in ILevel.current_level.map.get_children():
		if child is ITower and child != tower:
			if _is_in_range(tower, child):
				fail()
				return


# Private functions
func _is_in_range(t1: ITower, t2: ITower) -> bool:
	# Start simple with fixed safe distance
	var r1: float = 100.0
	var r2: float = 100.0

	var d: float = t1.global_position.distance_to(t2.global_position)
	return d < (r1 + r2)
