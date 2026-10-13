## © [2026] A7 Studio. All rights reserved. Trademark.
##
## Consistency of the level files ([code]data/levels[/code]) with [code]stats.json[/code] and the challenge files.
extends GdUnitTestSuite

const CHALLENGES_DIR: String = "res://data/challenges"
const LEVELS_DIR: String = "res://data/levels"


func test_every_challenge_script_compiles() -> void:
	var problems: Array[String] = []
	for path: String in _json_paths(CHALLENGES_DIR, "cha."):
		var script_path: String = JsonUtil.load_dict(path).get("script", "")
		var script: GDScript = load(script_path) as GDScript if ResourceLoader.exists(script_path) else null
		if script == null or not script.can_instantiate():
			problems.append("%s: script '%s' does not compile" % [path.get_file(), script_path])

	assert_array(_json_paths(CHALLENGES_DIR, "cha.")).is_not_empty()
	assert_array(problems).is_empty()


func test_every_challenge_file_matches_its_name() -> void:
	var problems: Array[String] = []
	for path: String in _json_paths(CHALLENGES_DIR, "cha."):
		var data: Dictionary = JsonUtil.load_dict(path)
		if data.get("id", "") != path.get_file().get_basename():
			problems.append("%s: id '%s'" % [path.get_file(), data.get("id", "")])
		for key: String in ["name", "description", "difficulty", "script"]:
			if str(data.get(key, "")).is_empty():
				problems.append("%s: missing '%s'" % [path.get_file(), key])

	assert_array(problems).is_empty()


func test_every_level_challenge_has_a_file() -> void:
	var problems: Array[String] = []
	for path: String in _json_paths(LEVELS_DIR, "lev."):
		for challenge_id: String in JsonUtil.load_dict(path).get("challenges", []):
			if not FileAccess.file_exists("%s/%s.json" % [CHALLENGES_DIR, challenge_id]):
				problems.append("%s: no file for %s" % [path.get_file(), challenge_id])

	assert_array(problems).is_empty()


func test_every_level_file_parses() -> void:
	var paths: Array[String] = _json_paths(LEVELS_DIR, "lev.")
	var problems: Array[String] = []
	for path: String in paths:
		var level: Dictionary = JsonUtil.load_dict(path)
		for key: String in ["start_coins", "max_health", "waves"]:
			if not level.has(key):
				problems.append("%s: missing '%s'" % [path.get_file(), key])
		if level.get("waves", []).is_empty():
			problems.append("%s: no wave" % path.get_file())

	assert_array(paths).is_not_empty()
	assert_array(problems).is_empty()


func test_every_wave_step_is_a_spawn_or_a_wait() -> void:
	var problems: Array[String] = []
	for path: String in _json_paths(LEVELS_DIR, "lev."):
		for wave: Array in JsonUtil.load_dict(path).get("waves", []):
			for step: Dictionary in wave:
				var is_spawn: bool = step.has("enemy_id") and step.has("count") and step.has("spawner")
				var is_wait: bool = step.has("wait_s")
				if is_spawn == is_wait:
					problems.append("%s: invalid step %s" % [path.get_file(), step])

	assert_array(problems).is_empty()


func test_every_wave_enemy_exists_in_the_stats() -> void:
	var problems: Array[String] = []
	for path: String in _json_paths(LEVELS_DIR, "lev."):
		for wave: Array in JsonUtil.load_dict(path).get("waves", []):
			for step: Dictionary in wave:
				if step.has("enemy_id") and not StatsDB.has_enemy(step["enemy_id"]):
					problems.append("%s: unknown enemy '%s'" % [path.get_file(), step["enemy_id"]])

	assert_array(problems).is_empty()


## Returns the sorted paths of the JSON files of [param dir] whose name starts with [param prefix].
func _json_paths(dir: String, prefix: String) -> Array[String]:
	var paths: Array[String] = []
	for file: String in DirAccess.get_files_at(dir):
		if file.begins_with(prefix) and file.get_extension() == "json":
			paths.append(dir.path_join(file))
	paths.sort()
	return paths
