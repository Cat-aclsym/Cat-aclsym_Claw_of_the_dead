## © [2026] A7 Studio. All rights reserved. Trademark.

class_name Challenge002
extends Challenge
## Challenge: No Traps
## No traps must be placed during the level.


# Public functions
## Notifies the challenge about a tower placement.
func on_tower_placed(tower: Node) -> void:
	# Check if tower is a trap
	if "trap" in tower.name.to_lower():
		fail()
