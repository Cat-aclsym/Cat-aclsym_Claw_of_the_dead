## © [2026] A7 Studio. All rights reserved. Trademark.
##
## Manages game progression via console.
extends ICommand


# Public functions
func description() -> String:
	return "Manages game progression: challenges, reset, show, unlock, armory debug (stars / grant / clear)."


func get_args() -> Array[Dictionary]:
	return [
		{"name": "action", "type": Types.ARG_ENUM, "enum_values": ["armory", "challenge", "reset", "show", "unlock"]}
	]


func get_args_dynamic(current_args: Array) -> Array[Dictionary]:
	var action_arg := {"name": "action", "type": Types.ARG_ENUM, "enum_values": ["armory", "challenge", "reset", "show", "unlock"]}

	if current_args.is_empty():
		return [action_arg]

	var args: Array[Dictionary] = [action_arg]
	var subcommand: String = current_args[0]

	match subcommand:
		"armory":
			args.append({"name": "armory_action", "type": Types.ARG_ENUM, "enum_values": ["clear", "grant", "stars"]})
			if current_args.size() > 1 and current_args[1] == "grant":
				args.append({"name": "node_id", "type": Types.ARG_STRING})
		"challenge":
			args.append({"name": "level_id", "type": Types.ARG_LEVEL})
			args.append({"name": "challenge_id", "type": Types.ARG_CHALLENGE})
		"unlock":
			args.append({"name": "type", "type": Types.ARG_ENUM, "enum_values": ["enemy", "level", "tower", "trap"]})
			if current_args.size() > 1:
				var utype: String = current_args[1]
				match utype:
					"enemy":
						args.append({"name": "enemy_id", "type": Types.ARG_ENEMY})
					"level":
						args.append({"name": "level_id", "type": Types.ARG_LEVEL})
					"tower":
						args.append({"name": "tower_id", "type": Types.ARG_TOWER})
					"trap":
						args.append({"name": "trap_id", "type": Types.ARG_STRING})

	return args


# Private functions
func _execute(console: Console, args: Array) -> int:
	if args.is_empty():
		console.push_error_("Missing subcommand. Usage: progression [armory|challenge|reset|show|unlock]")
		return OK

	var subcommand: String = args[0]

	match subcommand:
		"armory":
			if args.size() < 2:
				console.push_error_("Usage: progression armory stars|grant <node_id>|clear")
				return OK
			var a: String = args[1]
			match a:
				"stars":
					var earned: int = ArmoryManager.get_total_earned_stars()
					var spent: int = ArmoryManager.get_spent_stars()
					var avail: int = ArmoryManager.get_available_stars()
					console.push_text("Stars earned=%d spent=%d available=%d" % [earned, spent, avail])
				"grant":
					if args.size() < 3:
						console.push_error_("Usage: progression armory grant <node_id>")
						return OK
					var nid: String = args[2]
					if ArmoryManager.debug_grant_node(nid):
						console.push_text("Granted armory node: %s" % nid)
					else:
						console.push_error_("Unknown armory node: %s" % nid)
				"clear":
					ArmoryManager.debug_clear_purchases()
					console.push_text("Armory purchases cleared.")
				_:
					console.push_error_("Unknown armory action. Use stars, grant, or clear.")
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
				console.push_error_("Usage: progression unlock <level|enemy|tower|trap> <id>")
				return OK

			var ut: String = args[1]
			var uid: String = args[2]

			match ut:
				"enemy":
					ProgressionManager.mark_enemy_seen(uid)
					console.push_text("Marked enemy as seen: " + uid)
				"level":
					ProgressionManager.unlock_level(uid)
					console.push_text("Unlocked level: " + uid)
				"tower":
					ProgressionManager.unlock_tower(uid)
					console.push_text("Unlocked tower: " + uid)
				"trap":
					ProgressionManager.unlock_trap(uid)
					console.push_text("Unlocked trap: " + uid)
				_:
					console.push_error_("Unknown type: " + ut + ". Expected: level, enemy, tower, trap")
		_:
			console.push_error_("Unknown subcommand: " + subcommand)

	return OK
