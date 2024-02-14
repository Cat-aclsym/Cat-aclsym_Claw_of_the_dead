class_name IMap 
extends Node2D

var enemy1: PackedScene = preload("res://scenes/enemy/default_enemy_scene.tscn")

var paths: Array[Path2D] = []
var factory: EnemyFactory

@onready var Paths: Node2D = $Paths

func _ready() -> void:
	factory = EnemyFactory.new()
	_load_all_paths()


func get_paths() -> Array[Path2D]:
	return paths


func _load_all_paths() -> void:
	var tmp: Array[Node] = Paths.get_children()
	
	for c in tmp:
		if !c is Path2D:
			Log.error("you are an idiot")
			return
			
		paths.append(c as Path2D)
		

func _on_timer_timeout():
	var enemy: IEnemy = enemy1.instantiate()
	var path: Path2D = $Paths/Path2DA1

	factory.spawn_enemy(path, enemy)
