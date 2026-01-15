## © [2026] A7 Studio. All rights reserved. Trademark.

class_name Challenge001
extends Challenge
## Challenge: No Damage
## No damage must be taken by the base during the level.


# Public functions
## Notifies the challenge about damage taken.
func on_damage_taken(amount: int) -> void:
	# If any damage is taken, fail
	if amount > 0:
		fail()
