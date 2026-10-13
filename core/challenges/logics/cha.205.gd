## © [2026] A7 Studio. All rights reserved. Trademark.

class_name Challenge205
extends Challenge
## Challenge: Fast and Furious
## Finish the level in less than 3 minutes.


# Constants
const TARGET_TIME_LIMIT_SECONDS: int = 180 # 3 minutes


# Public functions
## Evaluates if the challenge conditions are met at the end of the level.
func check_completion() -> bool:
	if not ILevel.current_level:
		return false

	return floori(ILevel.current_level.elapsed_time) < TARGET_TIME_LIMIT_SECONDS
