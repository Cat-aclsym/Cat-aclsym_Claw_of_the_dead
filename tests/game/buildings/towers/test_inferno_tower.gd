## © [2026] A7 Studio. All rights reserved. Trademark.
##
## The inferno tower keeps the beam that burns its target instead of firing a new one.
extends GdUnitTestSuite

const BEAM_SCENE: PackedScene = preload("res://game/projectiles/inferno_beam.tscn")
const ENEMY_ID: String = "default_zombie"
const INFERNO_TOWER_ID: String = "bat_09"

var _enemy: IEnemy = null
var _tower: InfernoTower = null


func before_test() -> void:
	_enemy = await TestEnemies.spawn(self, ENEMY_ID)
	auto_free(_enemy.path)
	_tower = auto_free(load(StatsDB.get_tower(INFERNO_TOWER_ID)["scene"]).instantiate())
	add_child(_tower)
	_tower.target = _enemy


func test_a_target_without_beam_is_left_to_the_standard_fire_loop() -> void:
	assert_bool(_tower._handle_custom_fire()).is_false()
	assert_int(_beams().size()).is_equal(0)


func test_a_target_that_already_burns_gets_no_new_beam() -> void:
	var beam: InfernoBeam = auto_free(BEAM_SCENE.instantiate())
	beam.enemy_target = _enemy
	beam.tower_owner = _tower
	_tower.add_child(beam)
	_tower._active_beams[beam] = _enemy
	_tower.fire_rate_timer.stop()

	assert_bool(_tower._handle_custom_fire()).is_true()

	assert_array(_beams()).contains_exactly([beam])
	assert_int(_tower._active_beams.size()).is_equal(1)
	assert_bool(_tower.fire_rate_timer.is_stopped()).is_false()


func test_firing_at_a_burning_target_keeps_its_beam() -> void:
	_tower.enemy_array.append(_enemy)
	_tower.fire()
	var beams: Array[Node] = _beams()
	assert_int(beams.size()).is_equal(1)

	_tower.fire()

	assert_array(_beams()).contains_exactly(beams)
	assert_bool(_tower.fire_rate_timer.is_stopped()).is_false()


## The beams that are children of the tower.
func _beams() -> Array[Node]:
	var beams: Array[Node] = []
	beams.assign(_tower.get_children().filter(func(child: Node) -> bool: return child is InfernoBeam))
	return beams
