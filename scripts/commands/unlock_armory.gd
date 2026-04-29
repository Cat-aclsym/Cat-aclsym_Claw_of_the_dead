## © [2026] A7 Studio. All rights reserved. Trademark.
##
## Unlocks all armory nodes from the debug console.
extends ICommand


# Public functions
func description() -> String:
	return "Unlocks every armory node instantly."


func get_args() -> Array[Dictionary]:
	return []


# Private functions
func _execute(console: Console, _args: Array) -> int:
	var node_ids: Array[String] = ArmoryManager.get_node_ids_ordered()
	if node_ids.is_empty():
		console.push_error_("No armory nodes found.")
		return ERR_UNKNOWN_BEHAVIOR

	var granted_count: int = 0
	for node_id in node_ids:
		var was_purchased: bool = ArmoryManager.is_node_purchased(node_id)
		if ArmoryManager.debug_grant_node(node_id) and not was_purchased:
			granted_count += 1

	console.push_text("Armory unlocked: %d/%d nodes granted." % [granted_count, node_ids.size()])
	return OK
