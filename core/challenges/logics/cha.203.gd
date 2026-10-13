## © [2026] A7 Studio. All rights reserved. Trademark.

class_name Challenge203
extends Challenge
## Challenge: Not One More
## Every wave must end with at most 4 buildings (towers and traps) standing on the map.


# Constants
const MAX_BUILDINGS: int = 4


# Private variables
## Instance ids of every building placed so far, sold or consumed ones are no longer valid.
var _placed_buildings: Array[int] = []


# Public functions
## Evaluates if the challenge conditions are met at the end of the level, which is the end of the last wave.
func check_completion() -> bool:
	return not is_failed and _count_buildings() <= MAX_BUILDINGS


## Notifies the challenge about a tower placement.
func on_tower_placed(tower: ITower) -> void:
	_placed_buildings.append(tower.get_instance_id())


## Notifies the challenge about a trap placement.
func on_trap_placed(trap: ITrap) -> void:
	_placed_buildings.append(trap.get_instance_id())


## Called when the level starts to reset state, and starts following the waves.
func start_monitoring() -> void:
	super.start_monitoring()
	_placed_buildings.clear()
	if is_instance_valid(ILevel.current_level) and not ILevel.current_level.wave_started.is_connected(_on_wave_started):
		SignalUtil.connects([{SignalUtil.WHO: ILevel.current_level, SignalUtil.WHAT: "wave_started", SignalUtil.TO: _on_wave_started}])


# Private functions
func _count_buildings() -> int:
	return _placed_buildings.filter(func(building_id: int) -> bool: return is_instance_id_valid(building_id)).size()


## A new wave starts, so the previous one just ended.
func _on_wave_started(wave_number: int) -> void:
	if wave_number > 1 and _count_buildings() > MAX_BUILDINGS:
		fail()
