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


## Lists the stats of [param stats] that [param target] does not hold as the JSON declares them.
## [br]Each key needs a typed script variable of the target. Its value must have the declared type and equal the raw JSON value read as a human does:
## an int variable holds a whole JSON number, a float variable holds the JSON number as a float.
func _mismatches(target: Object, id: String, stats: Dictionary) -> Array[String]:
	var problems: Array[String] = []
	var declared_types: Dictionary[String, int] = {}
	for property: Dictionary in target.get_script().get_script_property_list():
		if int(property["usage"]) & PROPERTY_USAGE_SCRIPT_VARIABLE:
			declared_types[property["name"]] = property["type"]

	for key: String in stats:
		var json_value: Variant = stats[key]
		var declared_type: int = declared_types.get(key, TYPE_NIL)
		var actual: Variant = target.get(key)
		match declared_type:
			TYPE_INT:
				if json_value is not int and not (json_value is float and is_equal_approx(json_value, roundf(json_value))):
					problems.append("%s: %s is %s in the JSON, a whole number was expected for an int variable" % [id, key, json_value])
				elif typeof(actual) != TYPE_INT or actual != int(json_value):
					problems.append("%s: %s is %s (type %s), expected the int %s" % [id, key, actual, typeof(actual), int(json_value)])
			TYPE_FLOAT:
				if json_value is not int and json_value is not float:
					problems.append("%s: %s is %s in the JSON, a number was expected for a float variable" % [id, key, json_value])
				elif typeof(actual) != TYPE_FLOAT or not is_equal_approx(actual, float(json_value)):
					problems.append("%s: %s is %s (type %s), expected the float %s" % [id, key, actual, typeof(actual), float(json_value)])
			TYPE_BOOL:
				if typeof(actual) != TYPE_BOOL or actual != bool(json_value):
					problems.append("%s: %s is %s (type %s), expected the bool %s" % [id, key, actual, typeof(actual), bool(json_value)])
			TYPE_NIL:
				problems.append("%s: no typed script variable '%s'" % [id, key])
			_:
				problems.append("%s: '%s' has the type %s, the test only knows int, float and bool" % [id, key, declared_type])
	return problems

