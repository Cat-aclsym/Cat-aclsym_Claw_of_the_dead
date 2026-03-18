## © [2026] A7 Studio. All rights reserved. Trademark.
##
## Manages game progression via console.
extends ICommand


# Public functions
func description() -> String:
	return "Manages game progression, allowing to reset, unlock levels/enemies/towers, complete challenges, or show data."


func get_args() -> Array[Dictionary]:
	return [
		{"name": "action", "type": Types.ARG_ENUM, "enum_values": ["challenge", "reset", "show", "unlock"]}
	]


func get_args_dynamic(current_args: Array) -> Array[Dictionary]:
	var action_arg := {"name": "action", "type": Types.ARG_ENUM, "enum_values": ["challenge", "reset", "show", "unlock"]}

	if current_args.is_empty():
		return [action_arg]

	var args: Array[Dictionary] = [action_arg]
	var subcommand: String = current_args[0]

	match subcommand:
		"challenge":
			args.append({"name": "level_id", "type": Types.ARG_LEVEL})
			args.append({"name": "challenge_id", "type": Types.ARG_CHALLENGE})
		"unlock":
			args.append({"name": "type", "type": Types.ARG_ENUM, "enum_values": ["enemy", "level", "tower"]})
			if current_args.size() > 1:
				var type: String = current_args[1]
				match type:
					"enemy":
						args.append({"name": "enemy_id", "type": Types.ARG_ENEMY})
					"level":
						args.append({"name": "level_id", "type": Types.ARG_LEVEL})
					"tower":
						args.append({"name": "tower_id", "type": Types.ARG_TOWER})

	return args


# Private functions
func _execute(console: Console, args: Array) -> int:
	if args.is_empty():
		console.push_error("Missing subcommand. Usage: progression [challenge|reset|show|unlock]")
		return OK

	var subcommand: String = args[0]

	match subcommand:
		"challenge":
			if args.size() < 3:
				console.push_error_("Usage: progression challenge <level_id> <challenge_id>")
				return OK
			var level_id: String = args[1]
			var challenge_id: String = args[2]
			ProgressionManager.complete_challenge(level_id, challenge_id)
			console.push_text("Completed challenge " + challenge_id + " for level " + level_id)
		"reset":
			ProgressionManager.reset_progression()
			console.push_text("Progression reset.")
		"show":
			var data: Dictionary = ProgressionManager.data.save()
			var json_text: String = JSON.stringify(data, "\t")
			console.push_text(json_text)
		"unlock":
			if args.size() < 3:
				console.push_error("Usage: progression unlock <level|enemy|tower> <id>")
				return OK

			var type: String = args[1]
			var id: String = args[2]

			match type:
				"enemy":
					ProgressionManager.mark_enemy_seen(id)
					console.push_text("Marked enemy as seen: " + id)
				"level":
					ProgressionManager.unlock_level(id)
					console.push_text("Unlocked level: " + id)
				"tower":
					ProgressionManager.unlock_tower(id)
					console.push_text("Unlocked tower: " + id)
				_:
					console.push_error("Unknown type: " + type + ". Expected: level, enemy, tower")
		_:
			console.push_error("Unknown subcommand: " + subcommand)

	return OK
