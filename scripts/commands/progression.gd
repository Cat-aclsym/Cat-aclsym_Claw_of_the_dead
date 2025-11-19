## © [2024] A7 Studio. All rights reserved. Trademark.
##
## Manages game progression via console.
extends ICommand

# public
func command_token() -> String:
	return "progression"

func description() -> String:
	return "Manage game progression. Usage: progression [reset|unlock <level>|challenge <level> <number>]"

func expected_args_types() -> Array[ICommand.Types]:
	return [] # Not used when is_variable_args returns true

func is_variable_args() -> bool:
	return true

# private
func _execute(console: Console, args: Array) -> int:
	if args.is_empty():
		console.push_error("Missing subcommand. Usage: progression [reset|unlock|challenge]")
		return OK

	var subcommand = args[0]

	match subcommand:
		"reset":
			ProgressionManager.reset_progression()
			console.push_text("Progression reset.")

		"unlock":
			if args.size() < 2:
				console.push_error("Usage: progression unlock <level_id>")
				return OK
			var level_id = args[1]
			ProgressionManager.unlock_level(level_id)
			console.push_text("Unlocked level: " + level_id)

		"challenge":
			if args.size() < 3:
				console.push_error("Usage: progression challenge <level_id> <challenge_id>")
				return OK
			var level_id = args[1]
			var challenge_id = args[2]
			ProgressionManager.complete_challenge(level_id, challenge_id)
			console.push_text("Completed challenge " + challenge_id + " for level " + level_id)

		_:
			console.push_error("Unknown subcommand: " + subcommand)

	return OK
