## © [2026] A7 Studio. All rights reserved. Trademark.

extends Challenge

func on_tower_placed(tower: Node) -> void:
    # Check distance with all other towers
    if not ILevel.current_level or not ILevel.current_level.map:
        return

    for child in ILevel.current_level.map.get_children():
        if child is ITower and child != tower:
            if _is_in_range(tower, child):
                fail()
                return

func _is_in_range(t1: ITower, t2: ITower) -> bool:
    # Start simple with fixed safe distance
    var r1 = 100.0
    var r2 = 100.0

    var d = t1.global_position.distance_to(t2.global_position)
    return d < r1 or d < r2
