## © [2026] A7 Studio. All rights reserved. Trademark.

class_name Challenge106
extends Challenge
## Challenge: Survive
## Survive until the end: the base must still stand when the last wave is cleared.


# Public functions
## Evaluates if the challenge conditions are met at the end of the level.
func check_completion() -> bool:
	if is_failed or not is_instance_valid(ILevel.current_level):
		return false
	return ILevel.current_level.health > 0


## Notifies the challenge about damage taken, the base falling to 0 HP ends the run.
func on_damage_taken(_amount: int) -> void:
	if is_instance_valid(ILevel.current_level) and ILevel.current_level.health <= 0:
		fail()
