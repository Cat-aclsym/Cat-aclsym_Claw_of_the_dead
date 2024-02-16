class_name IMap 
extends Node2D

var enemy1: PackedScene = preload("res://scenes/enemy/ienemy_scene.tscn")

var paths: Array[Path2D] = []
@onready var Paths: Node2D = $Paths


func _ready() -> void:
	_load_all_paths()


func get_paths() -> Array[Path2D]:
	return paths


func _load_all_paths() -> void:
	var tmp: Array[Node] = Paths.get_children()
	
	for c in tmp:
		assert(c is Path2D, "You are an idiot")
		paths.append(c as Path2D)
		

func _on_timer_timeout():
	var enemy: IEnemy = enemy1.instantiate()
	var path: Path2D = $Paths/Path2DA1

	IEnemySpawner.spawn_enemy(path, enemy)
