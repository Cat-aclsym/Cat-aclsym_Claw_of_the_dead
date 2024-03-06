class_name ILevel
extends Node2D

var waves: Array[String] = []
var currentWave: int = 1

@export var map_scene: PackedScene = null

@onready var Metadata: LevelMetadata = null

# functionnal
func initialize(meta: LevelMetadata) -> void:
	Metadata = meta
	Log.info("Level initializing [{0}] : {1}".format([Metadata.id, Metadata.level_name]))
	_load_map()


func startNewWave() -> void:
	pass


func win() -> void:
	pass


func loose() -> void:
	pass


# internal
func _load_map() -> void:
	Log.info("Loading map ...")
	if !map_scene:
		Log.error("An IMap must be provided to create a level!")
		return
		
	var map: IMap = map_scene.instantiate()
	add_child(map)
