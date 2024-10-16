class_name LevelMetadata
extends Node2D

@export var id: int = -1
@export var level_name: String
@export var level_scene: PackedScene = null

var completed: bool = false

# core
func _ready() -> void:
	if get_parent() is ILevel:
		return

	if level_scene == null:
		Log.trace(Log.Level.WARN, "LevelMetada [{0}] don't have level scene".format([id]))
		return

	assert(level_scene.instantiate() is ILevel, "LevelMetadata: Provided level scene isn't a ILevel node.")


# public


# private


# signal


# event


# setget
