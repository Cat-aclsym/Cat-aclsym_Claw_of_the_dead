## © [2024] A7 Studio. All rights reserved. Trademark.

extends Challenge
## Challenge: Use only one type of tower.

var _first_tower_type: String = ""

func start_monitoring() -> void:
    super.start_monitoring()
    _first_tower_type = ""

func on_tower_placed(tower: Node) -> void:
    var t_id: String = tower.scene_file_path

    if _first_tower_type == "":
        _first_tower_type = t_id
    elif _first_tower_type != t_id:
        fail()
