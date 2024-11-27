## © [2024] A7 Studio. All rights reserved. Trademark.
##
## Contains metadata for a level.
class_name LevelMetadata
extends Node2D

## Unique identifier for the level
@export var id: int = -1

## Name of the level
@export var level_name: String

## Scene containing the level layout
@export var level_scene: PackedScene = null

## Whether the level has been completed
var completed: bool = false

# core
func _ready() -> void:
	if get_parent() is ILevel:
		return

	if level_scene == null:
		Log.trace(Log.Level.WARN, "LevelMetada [{0}] don't have level scene".format([id]))
		return

	assert(level_scene.instantiate() is ILevel, "LevelMetadata: Provided level scene isn't a ILevel node.")
