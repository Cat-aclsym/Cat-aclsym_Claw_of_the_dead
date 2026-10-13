## © [2026] A7 Studio. All rights reserved. Trademark.

class_name Challenge104
extends Challenge
## Challenge: Population Control
## Let exactly 3 rats pass. Each escape costs the rat escape damage, so 3 is the most the base can take: a fourth escape of 5 HP empties the 20 HP.


# Constants
const TARGET_ENEMY_ID: String = "rat"
const TARGET_PASS: int = 3


# Private variables
var _rats_passed: int = 0


# Public functions
## Evaluates if the challenge conditions are met at the end of the level.
func check_completion() -> bool:
	return not is_failed and _rats_passed == TARGET_PASS


## Notifies the challenge about an enemy reaching the end of its path, only rats count.
func on_enemy_escaped(enemy: IEnemy) -> void:
	if enemy.enemy_id != TARGET_ENEMY_ID:
		return

	_rats_passed += 1
	if _rats_passed > TARGET_PASS:
		fail()


## Called when the level starts to reset state.
func start_monitoring() -> void:
	super.start_monitoring()
	_rats_passed = 0

	if is_instance_valid(ILevel.current_level):
		var escape_damage: int = int(StatsDB.get_enemy(TARGET_ENEMY_ID).get("escape_damage", 0))
		if TARGET_PASS * escape_damage >= ILevel.current_level.max_health:
			Log.trace(Log.Level.WARN, "Challenge [%s] is unachievable: %d rats would empty the %d HP of the base." % [title, TARGET_PASS, ILevel.current_level.max_health])
