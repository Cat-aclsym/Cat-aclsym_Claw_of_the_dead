## © [2026] A7 Studio. All rights reserved. Trademark.

class_name Challenge204
extends Challenge
## Challenge: I love traps
## Finish the level using only traps: placing a tower fails it.


# Public functions
## Notifies the challenge about a tower placement.
func on_tower_placed(_tower: ITower) -> void:
	fail()
