## © [2026] A7 Studio. All rights reserved. Trademark.

class_name Challenge205
extends Challenge
## Challenge: Fast and Furious
## Finish the level in less than 3 minutes.


# Constants
const MAX_SECONDS: int = 180 # 3 minutes


# Public functions
## Evaluates if the challenge conditions are met at the end of the level.
func check_completion() -> bool:
	if not ILevel.current_level:
		return false

	var elapsed: float = floor(ILevel.current_level.end_time - ILevel.current_level.start_time)
	return elapsed < MAX_SECONDS
