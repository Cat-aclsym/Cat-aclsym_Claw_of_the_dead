class_name IMap 
extends Node2D

var ienemy_scene: PackedScene = preload("res://scenes/enemy/ienemy_scene.tscn")

var paths: Array[Path2D] = []
var max_spawn: int = 20
var current_spawning: int = 0:
	get:
		current_spawning += 1
		return current_spawning - 1
		
@onready var Paths: Node2D = $Paths


# core
func _ready() -> void:
	_load_all_paths()


# functionnal
func get_paths() -> Array[Path2D]:
	return paths


# internal
func _load_all_paths() -> void:
	for child in Paths.get_children():
		assert(child is Path2D, "You are an idiot")
		paths.append(child as Path2D)
		
		
# signals
func _on_timer_timeout():
	if current_spawning == max_spawn:
		return
		
	var path: Path2D = get_paths()[randi() % get_paths().size()]
	var enemy: IEnemy = ienemy_scene.instantiate()
	IEnemySpawner.spawn_enemy(path, enemy)
