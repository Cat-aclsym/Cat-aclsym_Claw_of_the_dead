## © [2026] A7 Studio. All rights reserved. Trademark.

extends Challenge

var _placed_types: Array[String] = []

func start_monitoring() -> void:
    super.start_monitoring()
    _placed_types.clear()

func on_tower_placed(tower: Node) -> void:
    var t_id: String = tower.scene_file_path
    if t_id in _placed_types:
        fail()
    else:
        _placed_types.append(t_id)
