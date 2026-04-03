## © [2026] A7 Studio. All rights reserved. Trademark.

class_name Challenge002
extends Challenge
## Challenge: No Traps
## No traps must be placed during the level.


# Public functions
## Notifies the challenge about a trap placement.
func on_trap_placed(_trap: Variant) -> void:
	fail()
