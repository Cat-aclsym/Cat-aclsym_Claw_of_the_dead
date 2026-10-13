## © [2026] A7 Studio. All rights reserved. Trademark.
##
## Toggles a green overlay on every tile where a tower can currently be placed.
extends ICommand


func description() -> String:
	return "Toggles a debug overlay showing all tiles where towers can be placed."


func get_args() -> Array[Dictionary]:
	return []


func _execute(console: Console, _args: Array) -> int:
	if not ILevel.current_level:
		console.push_error_("You must be in a level to use this command.")
		return ERR_UNKNOWN_BEHAVIOR

	var map: IMap = ILevel.current_level.map
	if not is_instance_valid(map):
		console.push_error_("No map found in the current level.")
		return ERR_UNKNOWN_BEHAVIOR

	var visible: bool = map.toggle_placement_debug_overlay()
	console.push_text("Tower placement overlay: %s" % ("ON" if visible else "OFF"))

	return OK
