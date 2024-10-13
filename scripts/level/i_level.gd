class_name ILevel
extends Node2D
signal stats_updated

var coins: int = 75: set = _set_coins
var health: int = 20: set =  _set_health


@export var map_scene: PackedScene = null

@onready var Map: IMap = null
@onready var Metadata: LevelMetadata = null

static var current_level: ILevel = null


# core


# public
func initialize(meta: LevelMetadata) -> void:
	Metadata = meta.duplicate()
	Log.trace(Log.Level.INFO, "Level initializing [{0}] : {1}".format([Metadata.id, Metadata.level_name]))
	_load_map()


func startNewWave() -> void:
	pass


func win() -> void:
	pass


func loose() -> void:
	pass


# private
func _load_map() -> void:
	Log.trace(Log.Level.INFO, "Loading map ...")
	if !map_scene:
		Log.trace(Log.Level.ERROR, "An IMap must be provided to create a level!")
		return

	var map: IMap = map_scene.instantiate()
	add_child(map)
	Map = map

	Global.cursor.map_ref = map


# signal


# event


# setget
func _set_coins(new_value):
	coins = new_value
	stats_updated.emit()


func _set_health(new_value):
	health = new_value
	stats_updated.emit()

