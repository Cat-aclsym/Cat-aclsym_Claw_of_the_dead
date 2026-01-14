## © [2024] A7 Studio. All rights reserved. Trademark.
##
## Command to upgrade a tower in the current level.
extends ICommand


# Public functions
func description() -> String:
	return "Upgrades the specified tower along a chosen path."


func get_args() -> Array[Dictionary]:
	return [
		{"name": "tower_name", "type": Types.ARG_INGAME_TOWER},
		{"name": "path", "type": Types.ARG_INT, "optional": true}
	]


# Private functions
func _execute(console: Console, args: Array) -> int:
	if not ILevel.current_level:
		console.push_error("You must be in a level to use this command.")
		return ERR_UNKNOWN_BEHAVIOR

	var tower_name: String = args[0]
	var upgrade_path: int = int(args[1]) if args.size() > 1 else 1

	var tower: ITower = ILevel.current_level.map.get_tower_by_name(tower_name)
	if not tower:
		console.push_error("Tower '%s' not found." % tower_name)
		return ERR_UNKNOWN_BEHAVIOR

	if tower.available_upgrade.is_empty():
		console.push_error("No upgrades available for this tower.")
		return ERR_UNKNOWN_BEHAVIOR

	if upgrade_path < 1 or upgrade_path > tower.available_upgrade.size():
		console.push_error("Invalid upgrade path: %d." % upgrade_path)
		return ERR_UNKNOWN_BEHAVIOR

	tower.start_upgrade(tower.available_upgrade[upgrade_path - 1])
	console.push_text("Upgrading tower: %s (Path %d)" % [tower_name, upgrade_path])

	return OK
