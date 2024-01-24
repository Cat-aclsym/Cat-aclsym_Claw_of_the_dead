extends Node2D

var default_zombie_scene: PackedScene = preload("res://scenes/enemy/default_enemy_scene.tscn")
var zombie_types: Array = ['default']

func _ready():
	var enemy: IEnemy = default_zombie_scene.instantiate()
	var path: Path2D = get_node('Path2D') # set the path name to where you want to go
	var path_follow: PathFollow2D = path.get_node('PathFollow2D')
	enemy.path = path_follow
	spawn_enemy(path_follow, enemy)
	
func spawn_enemy(path: PathFollow2D, enemy: IEnemy):
	path.add_child(enemy)
