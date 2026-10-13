## © [2026] A7 Studio. All rights reserved. Trademark.
##
## [JsonUtil] loading of JSON objects and its empty result on every kind of invalid file.
extends GdUnitTestSuite

const TEMP_DIR: String = "json_util"


func after() -> void:
	clean_temp_dir()


func test_load_dict_of_a_missing_file_is_empty() -> void:
	assert_dict(JsonUtil.load_dict("res://tests/core/utilities/missing.json")).is_empty()


func test_load_dict_of_a_valid_object() -> void:
	var path: String = _write("valid.json", '{"name": "cat", "count": 3, "nested": {"ok": true}}')

	assert_dict(JsonUtil.load_dict(path)).is_equal({"name": "cat", "count": 3.0, "nested": {"ok": true}})


func test_load_dict_of_invalid_json_is_empty() -> void:
	assert_dict(JsonUtil.load_dict(_write("invalid.json", '{"name": '))).is_empty()


func test_load_dict_of_a_non_object_root_is_empty() -> void:
	assert_dict(JsonUtil.load_dict(_write("array.json", "[1, 2, 3]"))).is_empty()


func test_load_dict_reads_the_stats_file() -> void:
	assert_dict(JsonUtil.load_dict(StatsDB.STATS_PATH)).contains_keys(["towers", "traps", "enemies", "upgrades"])


## Writes [param content] to a temporary file and returns its path.
func _write(file_name: String, content: String) -> String:
	var file: FileAccess = create_temp_file(TEMP_DIR, file_name)
	file.store_string(content)
	file.close()
	return file.get_path()
