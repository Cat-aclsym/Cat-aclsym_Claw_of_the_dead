## © [2026] A7 Studio. All rights reserved. Trademark.

class_name Challenge104
extends Challenge
## Challenge: Population Control
## Let exactly 5 enemies pass.


# Constants
const TARGET_PASS: int = 5


# Public functions
## Evaluates if the challenge conditions are met at the end of the level.
func check_completion() -> bool:
	# Logic based on base damage taken (which corresponds to rats passing)
	if not ILevel.current_level:
		return false

	var damage_taken: int = 20 - ILevel.current_level.health
	return damage_taken == TARGET_PASS
