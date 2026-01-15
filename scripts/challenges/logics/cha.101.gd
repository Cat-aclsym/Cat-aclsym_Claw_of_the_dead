## © [2026] A7 Studio. All rights reserved. Trademark.

class_name Challenge101
extends Challenge
## Challenge: Diversity
## Each tower placed must be of a unique type.


# Private variables
var _placed_types: Array[String] = []


# Public functions
## Called when the level starts to reset state.
func start_monitoring() -> void:
	super.start_monitoring()
	_placed_types.clear()


## Notifies the challenge about a tower placement.
func on_tower_placed(tower: Node) -> void:
	var t_id: String = tower.scene_file_path
	if t_id in _placed_types:
		fail()
	else:
		_placed_types.append(t_id)
