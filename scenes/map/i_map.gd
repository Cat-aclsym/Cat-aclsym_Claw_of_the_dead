class_name IMap 
extends Node2D

var paths: Array[Path2D] = []

@onready var Paths: Node2D = $Paths


func _ready() -> void:
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
