class_name ILevel
extends Node2D
signal stats_updated

var coins: int = 50:
	set(val):
		coins = val
		stats_updated.emit()
		
var health: int = 10:
	set(val):
		health = val
		stats_updated.emit()

@export var map_scene: PackedScene = null

@onready var Map: IMap = null
@onready var Metadata: LevelMetadata = null

static var current_level: ILevel = null


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
	Map = map
	
	Global.cursor.map_ref = map
