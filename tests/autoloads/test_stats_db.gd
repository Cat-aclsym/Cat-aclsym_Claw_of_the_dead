## © [2026] A7 Studio. All rights reserved. Trademark.
##
## [StatsDB] getters against the content of [code]stats.json[/code].
extends GdUnitTestSuite

var _expected: Dictionary = {}


func before() -> void:
	_expected = JsonUtil.load_dict(StatsDB.STATS_PATH)


func test_get_bullet_returns_the_json_data() -> void:
	var bullets: Dictionary = _expected["bullets"]

	assert_array(bullets.keys()).is_not_empty()
	for id: String in bullets:
		assert_dict(StatsDB.get_bullet(id)).is_equal(bullets[id])
	assert_dict(StatsDB.get_bullet("unknown")).is_empty()


func test_get_enemy_returns_the_json_data() -> void:
	var enemies: Dictionary = _expected["enemies"]

	assert_array(StatsDB.get_enemy_ids()).contains_exactly_in_any_order(enemies.keys())
	for id: String in enemies:
		assert_bool(StatsDB.has_enemy(id)).is_true()
		assert_dict(StatsDB.get_enemy(id)).is_equal(enemies[id])
	assert_bool(StatsDB.has_enemy("unknown")).is_false()
	assert_dict(StatsDB.get_enemy("unknown")).is_empty()


func test_get_enemy_scene_caches_the_loaded_scene() -> void:
	var id: String = StatsDB.get_enemy_ids()[0]

	assert_object(StatsDB.get_enemy_scene(id)).is_same(StatsDB.get_enemy_scene(id))


func test_get_enemy_scene_loads_a_scene_for_every_enemy() -> void:
	var problems: Array[String] = []
	for id: String in StatsDB.get_enemy_ids():
		var scene: PackedScene = StatsDB.get_enemy_scene(id)
		if scene == null or not scene.can_instantiate():
			problems.append(id)

	assert_array(problems).is_empty()


func test_get_enemy_scene_of_an_unknown_id_is_null() -> void:
	assert_object(StatsDB.get_enemy_scene("unknown")).is_null()


func test_get_tile_modifiers_keeps_the_declared_order() -> void:
	var tile_modifiers: Dictionary = _expected["tile_modifiers"]

	for kind: String in ["bonus", "malus"]:
		var modifiers: Array[Dictionary] = StatsDB.get_tile_modifiers(kind)
		assert_array(modifiers).is_not_empty()
		assert_array(modifiers).is_equal(tile_modifiers[kind])
		for modifier: Dictionary in modifiers:
			assert_array(modifier.keys()).contains_exactly_in_any_order(["stat", "multiplier"])
			assert_float(modifier["multiplier"]).is_greater(0.0)
	assert_array(StatsDB.get_tile_modifiers("unknown")).is_empty()


func test_get_tower_returns_the_json_data() -> void:
	var towers: Dictionary = _expected["towers"]

	assert_array(StatsDB.get_tower_ids()).contains_exactly_in_any_order(towers.keys())
	for id: String in towers:
		assert_bool(StatsDB.has_tower(id)).is_true()
		assert_dict(StatsDB.get_tower(id)).is_equal(towers[id])
		assert_int(StatsDB.get_tower_level(id)).is_equal(int(towers[id].get("level", 1)))
	assert_bool(StatsDB.has_tower("unknown")).is_false()
	assert_dict(StatsDB.get_tower("unknown")).is_empty()
	assert_int(StatsDB.get_tower_level("unknown")).is_equal(1)


func test_get_trap_returns_the_json_data() -> void:
	var traps: Dictionary = _expected["traps"]

	assert_array(StatsDB.get_trap_ids()).contains_exactly_in_any_order(traps.keys())
	for id: String in traps:
		assert_bool(StatsDB.has_trap(id)).is_true()
		assert_dict(StatsDB.get_trap(id)).is_equal(traps[id])
	assert_bool(StatsDB.has_trap("unknown")).is_false()
	assert_dict(StatsDB.get_trap("unknown")).is_empty()


func test_get_upgrade_price_matches_the_json_data() -> void:
	var upgrades: Dictionary = _expected["upgrades"]

	for id: String in upgrades:
		assert_int(StatsDB.get_upgrade_price(id)).is_equal(int(upgrades[id].get("price", 0)))
	assert_int(StatsDB.get_upgrade_price("unknown")).is_equal(0)


func test_get_upgrade_returns_the_json_data() -> void:
	var upgrades: Dictionary = _expected["upgrades"]

	assert_dict(upgrades).is_not_empty()
	for id: String in upgrades:
		assert_bool(StatsDB.has_upgrade(id)).is_true()
		assert_dict(StatsDB.get_upgrade(id)).is_equal(upgrades[id])
		assert_dict(StatsDB.get_upgrade_changes(id)).is_equal(upgrades[id].get("changes", {}))
		assert_dict(StatsDB.get_upgrade_bullet_stats(id)).is_equal(upgrades[id].get("bullet_stats", {}))
		assert_dict(StatsDB.get_upgrade_tower_stats(id)).is_equal(upgrades[id].get("tower_stats", {}))
	assert_bool(StatsDB.has_upgrade("unknown")).is_false()
	assert_dict(StatsDB.get_upgrade("unknown")).is_empty()


func test_load_packed_scene_of_an_empty_path_is_null() -> void:
	assert_object(StatsDB.load_packed_scene("")).is_null()


func test_name_key_is_the_uppercase_category_and_id() -> void:
	assert_str(StatsDB.name_key("TOWER", "bat_01")).is_equal("TOWER.BAT_01.NAME")
	assert_str(StatsDB.name_key("TRAP", "bat_03")).is_equal("TRAP.BAT_03.NAME")
	assert_str(StatsDB.name_key("ENEMY", "default_zombie")).is_equal("ENEMY.DEFAULT_ZOMBIE.NAME")


func test_tower_scenes_and_upgrade_references_exist() -> void:
	var problems: Array[String] = []
	for id: String in StatsDB.get_tower_ids():
		if StatsDB.load_packed_scene(StatsDB.get_tower(id).get("scene", "")) == null:
			problems.append("%s: no scene" % id)
		for upgrade_id: String in StatsDB.get_upgrade_ids_for_tower(id):
			if not StatsDB.has_upgrade(upgrade_id):
				problems.append("%s: unknown upgrade %s" % [id, upgrade_id])
	for id: String in _expected["upgrades"]:
		for next_id: String in StatsDB.get_upgrade_next_ids(id):
			if not StatsDB.has_upgrade(next_id):
				problems.append("%s: unknown next upgrade %s" % [id, next_id])

	assert_array(problems).is_empty()
