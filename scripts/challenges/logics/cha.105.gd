## © [2024] A7 Studio. All rights reserved. Trademark.

extends Challenge
## Challenge: Boss must be hit by every trap type (Active, Passive, Limited).

var _hit_types: Array[String] = []
const REQUIRED_TYPES = ["active", "passive", "limited"]

func start_monitoring() -> void:
	super.start_monitoring()
	_hit_types.clear()

func on_enemy_hit(enemy: IEnemy, source: Variant) -> void:
	if enemy.type != IEnemy.EnemyType.BIG_DADDY:
		return

	# Assuming traps have a 'trap_type' property or we can infer it
	var type: String = ""
	if source.has_method("get_trap_type"):
		type = source.get_trap_type().to_lower()
	elif "trap_type" in source:
		type = source.trap_type.to_lower()

	if type != "" and type in REQUIRED_TYPES:
		if not type in _hit_types:
			_hit_types.append(type)

			if _hit_types.size() >= REQUIRED_TYPES.size():
				complete()

func check_completion() -> bool:
	return _hit_types.size() >= REQUIRED_TYPES.size()
