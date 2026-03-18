## © [2026] A7 Studio. All rights reserved. Trademark.

class_name Challenge202
extends Challenge
## Challenge: Near Death Experience
## Finish the level with exactly 1 HP left.


# Public functions
## Evaluates if the challenge conditions are met at the end of the level.
func check_completion() -> bool:
	if not ILevel.current_level:
		return false
	return ILevel.current_level.health == 1
