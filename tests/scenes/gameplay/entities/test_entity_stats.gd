## © [2026] A7 Studio. All rights reserved. Trademark.
##
## Every trap and enemy scene gets its stats from [code]stats.json[/code] once it is ready.
extends GdUnitTestSuite

## Stat of an enemy that is stored under another property name.
const ENEMY_PROPERTY_RENAMES: Dictionary[String, String] = {"speed": "base_speed"}
## Keys of an enemy entry that are not stats.
const ENEMY_NON_STAT_KEYS: Array[String] = ["extra", "scene"]


func test_every_enemy_scene_gets_its_stats_from_the_json() -> void:
	var problems: Array[String] = []
	for id: String in StatsDB.get_enemy_ids():
		var enemy: IEnemy = await TestEnemies.spawn(self, id)
		auto_free(enemy.path)
		var data: Dictionary = StatsDB.get_enemy(id)
		var stats: Dictionary = {}
		for key: String in data:
			if key not in ENEMY_NON_STAT_KEYS:
				stats[ENEMY_PROPERTY_RENAMES.get(key, key)] = data[key]
		stats.merge(data.get("extra", {}))
		problems.append_array(_mismatches(enemy, id, stats))
		# The speed is the base speed while no effect slows the enemy down
		if not is_equal_approx(enemy.speed, float(data["speed"])):
			problems.append("%s: speed is %s, expected %s" % [id, enemy.speed, data["speed"]])

	assert_array(problems).is_empty()


func test_every_trap_scene_gets_its_stats_from_the_json() -> void:
	var problems: Array[String] = []
	for id: String in StatsDB.get_trap_ids():
		var scene: PackedScene = load(StatsDB.get_trap(id)["scene"])
		var trap: ITrap = auto_free(scene.instantiate())
		add_child(trap)
		problems.append_array(_mismatches(trap, id, StatsDB.get_trap(id)["base"]))

	assert_array(problems).is_empty()


func test_the_trap_stats_are_applied_to_an_orphan_instance() -> void:
	var problems: Array[String] = []
	for id: String in StatsDB.get_trap_ids():
		var scene: PackedScene = load(StatsDB.get_trap(id)["scene"])
		var trap: ITrap = auto_free(scene.instantiate())
		trap.apply_stats_from_db()
		problems.append_array(_mismatches(trap, id, StatsDB.get_trap(id)["base"]))

	assert_array(problems).is_empty()


## Lists the stats of [param stats] whose property of [param target] holds another value, a missing property counts as a mismatch.
func _mismatches(target: Object, id: String, stats: Dictionary) -> Array[String]:
	var problems: Array[String] = []
	for key: String in stats:
		if key not in target:
			problems.append("%s: no property '%s'" % [id, key])
			continue
		var actual: Variant = target.get(key)
		var expected: Variant = type_convert(stats[key], typeof(actual))
		if actual != expected:
			problems.append("%s: %s is %s, expected %s" % [id, key, actual, expected])
	return problems


