## © [2026] A7 Studio. All rights reserved. Trademark.
##
## The level end pauses the gameplay without pausing the scene tree: beams and traps must stop dealing damage meanwhile.
extends GdUnitTestSuite

const BEAM_SCENE: PackedScene = preload("res://scenes/gameplay/entities/bullet/inferno_beam.tscn")
const ENEMY_ID: String = "default_zombie"
const FRAME_DELTA: float = 1.0
const INFERNO_TOWER_ID: String = "bat_09"
const TRAP_ID: String = "bat_03"


func after_test() -> void:
	Global.clear_pauses()


func test_an_inferno_beam_hits_its_target_unless_the_gameplay_is_paused() -> void:
	var enemy: IEnemy = await _spawn_enemy()
	var tower: ITower = auto_free(load(StatsDB.get_tower(INFERNO_TOWER_ID)["scene"]).instantiate())
	add_child(tower)
	var beam: InfernoBeam = auto_free(BEAM_SCENE.instantiate())
	beam.damage = 10.0
	beam.enemy_target = enemy
	beam.tower_owner = tower
	add_child(beam)

	Global.request_pause(&"level_end")
	beam._process(FRAME_DELTA)
	assert_float(enemy.health).is_equal(enemy.max_health)

	Global.release_pause(&"level_end")
	beam._process(FRAME_DELTA)
	assert_float(enemy.health).is_less(enemy.max_health)


func test_a_trap_does_not_trigger_while_the_gameplay_is_paused() -> void:
	var enemy: IEnemy = await _spawn_enemy()
	var trap: ITrap = auto_free(load(StatsDB.get_trap(TRAP_ID)["scene"]).instantiate())
	add_child(trap)
	var feet: Area2D = enemy.get_node("FeetArea")

	Global.request_pause(&"level_end")
	trap._on_area_2d_area_entered(feet)
	assert_float(enemy.health).is_equal(enemy.max_health)

	Global.release_pause(&"level_end")
	trap._on_area_2d_area_exited(feet)
	trap._on_area_2d_area_entered(feet)
	assert_float(enemy.health).is_less(enemy.max_health)


func _spawn_enemy() -> IEnemy:
	var enemy: IEnemy = await TestEnemies.spawn(self, ENEMY_ID)
	auto_free(enemy.path)
	# The popup is added to the current scene, which the test runner does not have
	enemy.popup_score_spawner.damage_popup_node = null
	return enemy
