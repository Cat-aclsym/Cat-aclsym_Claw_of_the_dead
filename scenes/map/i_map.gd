class_name IMap 
extends Node2D

var enemy1: PackedScene = preload("res://scenes/enemy/ienemy_scene.tscn")

var paths: Array[Path2D] = []
@onready var Paths: Node2D = $Paths
var max_spawn: int = 2
var current_spawning: int = 0

func _ready() -> void:
	_load_all_paths()
	#var enemy: IEnemy = enemy1.instantiate()
	#var path: Path2D = $Paths/Path2DA1
#
	#IEnemySpawner.spawn_enemy(path, enemy)


func get_paths() -> Array[Path2D]:
	return paths


func _load_all_paths() -> void:
	var tmp: Array[Node] = Paths.get_children()
	
	for c in tmp:
		assert(c is Path2D, "You are an idiot")
		paths.append(c as Path2D)
		

func _on_timer_timeout():
	var path: Path2D
	if current_spawning == max_spawn:
		return
	if current_spawning == 0:
		path = $Paths/Path2DA1
	else:
		path = $Paths/Path2DB1
	var enemy: IEnemy = enemy1.instantiate()
	IEnemySpawner.spawn_enemy(path, enemy)
	current_spawning += 1
	#pass
