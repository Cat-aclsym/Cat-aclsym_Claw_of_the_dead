## © [2026] A7 Studio. All rights reserved. Trademark.

class_name Challenge104
extends Challenge
## Challenge: Population Control
## Let exactly 5 enemies pass.


# Constants
const TARGET_PASS: int = 5


# Private variables
var _initial_health: int = 20


# Public functions
## Called when the level starts to reset state.
func start_monitoring() -> void:
	super.start_monitoring()
	if ILevel.current_level:
		_initial_health = ILevel.current_level.health


## Evaluates if the challenge conditions are met at the end of the level.
func check_completion() -> bool:
	# Logic based on base damage taken (which corresponds to rats passing)
	if not ILevel.current_level:
		return false

	var damage_taken: int = _initial_health - ILevel.current_level.health
	return damage_taken == TARGET_PASS
