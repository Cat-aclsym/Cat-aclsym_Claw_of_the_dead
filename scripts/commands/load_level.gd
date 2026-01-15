## © [2024] A7 Studio. All rights reserved. Trademark.
##
## Loads a specific level by its ID.
## Instantiates the level scene and starts it, replacing the current level if one exists.
extends ICommand


# Public functions
## Returns the command's description.
func description() -> String:
	return "Loads and starts a level by its ID (e.g., lev.01)."


## Returns the expected arguments for this command.
func get_args() -> Array[Dictionary]:
	return [
		{"name": "level_id", "type": Types.ARG_LEVEL}
	]


# Private functions
## Implements the command's behavior.
func _execute(console: Console, args: Array) -> int:
	var level_id: String = args[0]
	var level_path := "res://scenes/gameplay/world/level/levels/%s.tscn" % level_id

	if not FileAccess.file_exists(level_path):
		console.push_error("Level scene not found: %s" % level_path)
		return ERR_UNKNOWN_BEHAVIOR

	var level_scene = load(level_path)
	if not level_scene:
		console.push_error("Failed to load level scene: %s" % level_path)
		return ERR_UNKNOWN_BEHAVIOR

	# Cleanup current level if it exists
	if ILevel.current_level:
		Global.ui.end_level()
		ILevel.current_level.queue_free()
		ILevel.current_level = null

	# Instantiate and start new level
	var level: ILevel = level_scene.instantiate()
	console.get_tree().get_root().add_child(level)
	level.start_level()

	# Initialize UI
	if Global.ui:
		Global.ui.start_level()

	# Hide home menu if visible
	if Global.ui:
		var home_menu = Global.ui.get_node_or_null("HomeMenu")
		if home_menu:
			home_menu.visible = false

	console.push_text("Level loaded: %s" % level_id)
	return OK
