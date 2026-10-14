## © [2026] A7 Studio. All rights reserved. Trademark.
##
## The frame callback of the traps, the lifetime of a LIMITED trap and its opacity.
extends GdUnitTestSuite

const ENEMY_ID: String = "default_zombie"
## LIMITED trap with a single use and a short effect (the PASSIVE one of the processing test is bat_04).
const LIMITED_TRAP_ID: String = "bat_03"
const STEP: float = 0.1


func test_only_the_preview_and_the_limited_traps_process(trap_id: String, is_limited: bool, test_parameters: Array = [["bat_03", true], ["bat_04", false]]) -> void:
	var template: ITrap = auto_free(load(StatsDB.get_trap(trap_id)["scene"]).instantiate())

	# BuildPlacement shows a duplicate of the template that follows the cursor...
	var preview: ITrap = auto_free(template.duplicate())
	preview.enter_build_preview()
	add_child(preview)
	assert_bool(preview.is_processing()).is_true()

	# ...and places a duplicate of it
	var placed: ITrap = auto_free(preview.duplicate())
	placed.state = ITrap.TrapState.ACTIVE
	add_child(placed)
	assert_bool(placed.is_processing()).is_equal(is_limited)


func test_a_spent_trap_stays_until_its_effect_is_over() -> void:
	var enemy: IEnemy = await _spawn_enemy()
	var trap: ITrap = _add_trap(LIMITED_TRAP_ID)
	trap._on_area_2d_area_entered(enemy.get_node("FeetArea"))
	assert_bool(trap.is_usable).is_false()
	assert_bool(trap.active_affected_enemies.has(enemy)).is_true()

	# The effect lasts effect_duration, the trap is freed with its last effect
	trap._process(STEP)
	trap._process(STEP)
	assert_bool(trap.is_queued_for_deletion()).is_false()
	trap._process(STEP)
	assert_bool(trap.is_queued_for_deletion()).is_true()
	assert_bool(trap.active_affected_enemies.is_empty()).is_true()


func test_a_spent_trap_stays_until_the_effect_of_a_dead_enemy_is_over() -> void:
	var enemy: IEnemy = await _spawn_enemy()
	var trap: ITrap = _add_trap(LIMITED_TRAP_ID)
	trap._on_area_2d_area_entered(enemy.get_node("FeetArea"))

	# The waiting time after the last trigger is over, only the effect left on the enemy that died keeps the trap
	trap._post_trigger_remaining = 0.0
	enemy._dead_state()
	assert_bool(trap.active_affected_enemies.is_empty()).is_true()
	assert_float(trap._linger_remaining).is_equal_approx(trap.effect_duration, 0.001)

	trap._process(STEP)
	assert_bool(trap.is_queued_for_deletion()).is_false()
	trap._process(trap.effect_duration)
	assert_bool(trap.is_queued_for_deletion()).is_true()


func test_the_opacity_follows_the_durability() -> void:
	var first: IEnemy = await _spawn_enemy()
	var second: IEnemy = await _spawn_enemy()
	var trap: ITrap = _add_trap(LIMITED_TRAP_ID)
	trap.max_durability = 2
	trap.current_durability = 2

	trap._on_area_2d_area_entered(first.get_node("FeetArea"))
	assert_int(trap.current_durability).is_equal(1)
	assert_float(trap.modulate.a).is_equal_approx(0.6, 0.001)

	trap._on_area_2d_area_entered(second.get_node("FeetArea"))
	assert_int(trap.current_durability).is_equal(0)
	assert_float(trap.modulate.a).is_equal_approx(0.2, 0.001)


## Adds the trap after the enemies are spawned and without waiting for a frame afterwards: the physics would trigger it by overlap otherwise.
func _add_trap(trap_id: String) -> ITrap:
	var trap: ITrap = auto_free(load(StatsDB.get_trap(trap_id)["scene"]).instantiate())
	add_child(trap)
	return trap


func _spawn_enemy() -> IEnemy:
	var enemy: IEnemy = await TestEnemies.spawn(self, ENEMY_ID)
	auto_free(enemy.path)
	# The popup is added to the current scene, which the test runner does not have
	enemy.popup_score_spawner.damage_popup_node = null
	return enemy
