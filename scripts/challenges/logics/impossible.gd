## © [2026] A7 Studio. All rights reserved. Trademark.

class_name ChallengeImpossible
extends Challenge

## Challenge logic for impossible/unimplemented challenges.
##
## This script ensures the challenge can never be completed.

# Built-in functions
func start_monitoring() -> void:
	super.start_monitoring()
	# Immediately fail or ensure check_completion returns false
	is_failed = true

func check_completion() -> bool:
	return false
