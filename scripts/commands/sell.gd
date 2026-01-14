## © [2024] A7 Studio. All rights reserved. Trademark.
##
## Command to sell a tower in the current level.
extends ICommand


# Public functions
func description() -> String:
	return "Sell a tower."


func get_args() -> Array[Dictionary]:
	return [{"name": "tower_name", "type": Types.ARG_STRING}]


# Private functions
func _execute(console: Console, args: Array) -> int:
	if not ILevel.current_level:
		console.push_error("You must be in a level to use this command.")
		return ERR_UNKNOWN_BEHAVIOR

	var tower_name: String = args[0]
	var tower: ITower = ILevel.current_level.map.get_tower_by_name(tower_name)

	if not tower:
		console.push_error("Tower '%s' not found." % tower_name)
		return ERR_UNKNOWN_BEHAVIOR

	tower.sell_tower()
	console.push_text("Sold tower: %s" % tower_name)

	return OK
