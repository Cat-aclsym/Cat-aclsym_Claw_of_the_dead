## © [2026] A7 Studio. All rights reserved. Trademark.

class_name Challenge003
extends Challenge
## Challenge: Mono-tower
## Use only one type of tower.


# Private variables
var _first_tower_type: String = ""


# Public functions
## Called when the level starts to reset state.
func start_monitoring() -> void:
	super.start_monitoring()
	_first_tower_type = ""


## Notifies the challenge about a tower placement.
func on_tower_placed(tower: ITower) -> void:
	var t_id: String = tower.scene_file_path

	if _first_tower_type == "":
		_first_tower_type = t_id
	elif _first_tower_type != t_id:
		fail()
