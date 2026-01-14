## © [2024] A7 Studio. All rights reserved. Trademark.
##
## Manages game progression via console.
extends ICommand


# Public functions
func description() -> String:
	return "Manage game progression."


func get_args() -> Array[Dictionary]:
	return [
		{"name": "action", "type": Types.ARG_STRING},
		{"name": "level", "type": Types.ARG_STRING, "optional": true},
		{"name": "id", "type": Types.ARG_STRING, "optional": true}
	]


func is_variable_args() -> bool:
	return true


# Private functions
func _execute(console: Console, args: Array) -> int:
	if args.is_empty():
		console.push_error("Missing subcommand. Usage: progression [reset|unlock|challenge]")
		return OK

	var subcommand: String = args[0]

	match subcommand:
		"reset":
			ProgressionManager.reset_progression()
			console.push_text("Progression reset.")

		"unlock":
			if args.size() < 2:
				console.push_error("Usage: progression unlock <level_id>")
				return OK
			var level_id: String = args[1]
			if not ProgressionManager.data.levels.has(level_id):
				ProgressionManager.data.levels[level_id] = LevelData.new()
			ProgressionManager.data.levels[level_id].unlocked = true
			ProgressionManager.save_game()
			console.push_text("Unlocked level: " + level_id)

		"challenge":
			if args.size() < 3:
				console.push_error("Usage: progression challenge <level_id> <challenge_id>")
				return OK
			var level_id: String = args[1]
			var challenge_id: String = args[2]
			ProgressionManager.complete_challenge(level_id, challenge_id)
			console.push_text("Completed challenge " + challenge_id + " for level " + level_id)

		_:
			console.push_error("Unknown subcommand: " + subcommand)

	return OK
