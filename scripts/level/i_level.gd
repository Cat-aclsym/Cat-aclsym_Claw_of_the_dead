class_name ILevel
extends Node2D

signal stats_updated

static var current_level: ILevel = null

@export var map_scene: PackedScene = null

var coins: int = 75:
	set = _set_coins
var health: int = 20:
	set =  _set_health
var map: IMap = null
var metadata: LevelMetadata = null

# core


# public
func initialize(meta: LevelMetadata) -> void:
	metadata = meta.duplicate()
	Log.trace(Log.Level.INFO, "Level initializing [{0}] : {1}".format([metadata.id, metadata.level_name]))
	_load_map()


func start_new_wave() -> void:
	pass


func win() -> void:
	pass


func loose() -> void:
	pass


# private
func _load_map() -> void:
	Log.trace(Log.Level.INFO, "Loading map ...")
	if not map_scene:
		Log.trace(Log.Level.ERROR, "An IMap must be provided to create a level!")
		return

	var new_map: IMap = map_scene.instantiate()
	add_child(new_map)
	map = new_map

	Global.cursor.map_ref = map


func _set_coins(new_value):
	coins = new_value
	stats_updated.emit()


func _set_health(new_value):
	health = new_value
	stats_updated.emit()

# signal


# event


# setget
