## © [2026] A7 Studio. All rights reserved. Trademark.
##
## The chain of the lightning only picks living enemies and does not hit while the gameplay is paused.
extends GdUnitTestSuite

const ENEMY_ID: String = "default_zombie"
const LIGHTNING_SCENE: PackedScene = preload("res://game/projectiles/instant_lightning.tscn")
const PAUSE_SOURCE: StringName = &"test_pause"


func after_test() -> void:
	Global.clear_pauses()


func test_the_chain_candidates_exclude_the_first_target_and_the_dead_enemies() -> void:
	var first: IEnemy = await _spawn_enemy()
	var alive: IEnemy = await _spawn_enemy()
	var dead: IEnemy = await _spawn_enemy()
	# The candidates are the enemies on the path of the first target
	alive.path = first.path
	dead.path = first.path
	dead.is_already_dead = true
	var lightning: InstantLightning = _add_lightning()

	assert_array(lightning._get_chain_candidates(first)).contains_exactly([alive])


func test_the_chain_candidates_are_the_enemies_of_the_same_path() -> void:
	var first: IEnemy = await _spawn_enemy()
	await _spawn_enemy()
	var lightning: InstantLightning = _add_lightning()

	assert_array(lightning._get_chain_candidates(first)).is_empty()


func test_a_chained_hit_does_nothing_while_the_gameplay_is_paused() -> void:
	var first: IEnemy = await _spawn_enemy()
	var chained: IEnemy = await _spawn_enemy()
	var lightning: InstantLightning = _add_lightning()
	var chain: Array[IEnemy] = [first, chained]
	lightning._chain = chain

	Global.request_pause(PAUSE_SOURCE)
	lightning._hit_chained_enemy(1, 10.0)
	assert_float(chained.health).is_equal(chained.max_health)

	Global.release_pause(PAUSE_SOURCE)
	lightning._hit_chained_enemy(1, 10.0)
	assert_float(chained.health).is_less(chained.max_health)


func _add_lightning() -> InstantLightning:
	var lightning: InstantLightning = auto_free(LIGHTNING_SCENE.instantiate())
	add_child(lightning)
	return lightning


func _spawn_enemy() -> IEnemy:
	var enemy: IEnemy = await TestEnemies.spawn(self, ENEMY_ID)
	auto_free(enemy.path)
	# The popup is added to the current scene, which the test runner does not have
	enemy.popup_score_spawner.damage_popup_node = null
	return enemy
