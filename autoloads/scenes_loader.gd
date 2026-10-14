## © [2026] A7 Studio. All rights reserved. Trademark.
##
## Manages loading of game scenes and resources.
extends Node

const END_GAME_MENU: PackedScene = preload("res://ui/menus/end_game/end_game.tscn")
const HOME_SCENE_PATH: String = "res://main.tscn"
const LEVEL_SCENE_PATH: String = "res://game/level/levels/%s.tscn"


# public
## Frees the running level and goes back to the home scene, every pause is released.
func go_home() -> void:
	Global.clear_pauses()
	if is_instance_valid(ILevel.current_level):
		ILevel.current_level.queue_free()
	get_tree().change_scene_to_file(HOME_SCENE_PATH)


## Replaces the running level (if any) by a new instance of [param level_id] and starts it, every pause is released.
## [br]Returns the new level, or [code]null[/code] when the level scene cannot be loaded.
func start_level(level_id: String) -> ILevel:
	var level_scene_path: String = LEVEL_SCENE_PATH % level_id
	var level_scene: PackedScene = load(level_scene_path) as PackedScene
	var level: ILevel = level_scene.instantiate() as ILevel if level_scene != null else null
	if level == null:
		Log.trace(Log.Level.ERROR, "Failed to load the level scene: %s" % level_scene_path)
		return null

	Global.clear_pauses()
	var previous_level: ILevel = ILevel.current_level
	if is_instance_valid(previous_level) and previous_level.is_inside_tree():
		previous_level.queue_free()
		await previous_level.tree_exited

	get_tree().root.add_child(level)
	level.start_level()
	Global.ui.start_level()
	return level
