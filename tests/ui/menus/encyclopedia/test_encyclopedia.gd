## © [2026] A7 Studio. All rights reserved. Trademark.
##
## [Encyclopedia]: the name label fits its text through theme variations, the stats page switches to the compact variations when it has many rows.
extends GdUnitTestSuite

const ENCYCLOPEDIA_SCENE: PackedScene = preload("res://ui/menus/encyclopedia/encyclopedia.tscn")
const COMPACT_STATS: Array[String] = [
	"ENCYCLOPEDIA.STATS.ATTACK_DURATION", "ENCYCLOPEDIA.STATS.COOLDOWN", "ENCYCLOPEDIA.STATS.COST", "ENCYCLOPEDIA.STATS.DAMAGE",
	"ENCYCLOPEDIA.STATS.DISABLE_DURATION", "ENCYCLOPEDIA.STATS.FIRERATE", "ENCYCLOPEDIA.STATS.HEALTH", "ENCYCLOPEDIA.STATS.POST_ATTACK",
	"ENCYCLOPEDIA.STATS.PRE_ATTACK", "ENCYCLOPEDIA.STATS.RANGE", "ENCYCLOPEDIA.STATS.REWARD", "ENCYCLOPEDIA.STATS.SPEED",
]

var _data_before: ProgressionData = null
var _persistence_before: bool = true


func before_test() -> void:
	_data_before = ProgressionManager.data
	_persistence_before = ProgressionManager.persistence_enabled
	ProgressionManager.data = ProgressionData.new()
	ProgressionManager.persistence_enabled = false
	ProgressionManager.unlock_tower_no_save("bat_01")


func after_test() -> void:
	ProgressionManager.data = _data_before
	ProgressionManager.persistence_enabled = _persistence_before


func test_the_name_label_takes_a_variation_per_name_length() -> void:
	var encyclopedia: Encyclopedia = _open()
	var expected: Dictionary[int, StringName] = {
		5: &"BookName",
		14: &"BookName",
		15: &"BookNameTitleLarge",
		18: &"BookNameTitleLarge",
		19: &"BookNameTitle",
		22: &"BookNameTitle",
		23: &"BookNameBodyLarge",
		28: &"BookNameBodyLarge",
		29: &"BookNameBody",
	}

	for length: int in expected:
		encyclopedia._all_entries["TOWERS"][0]["name"] = "x".repeat(length)
		encyclopedia._update_ui_elements()

		assert_str(encyclopedia.name_label.theme_type_variation).override_failure_message("%d characters" % length).is_equal(expected[length])


func test_an_undiscovered_entry_shows_the_giant_question_mark() -> void:
	var encyclopedia: Encyclopedia = _open()
	encyclopedia._current_index = 1

	encyclopedia._update_ui_elements()

	assert_str(encyclopedia.name_label.text).is_equal("?")
	assert_str(encyclopedia.name_label.theme_type_variation).is_equal(&"BookNameGiant")


func test_a_short_stats_page_uses_the_regular_variations() -> void:
	var encyclopedia: Encyclopedia = _open()
	await await_idle_frame()

	assert_str(encyclopedia.stats_grid.theme_type_variation).is_equal(&"BookStatsGrid")
	assert_str(_live_label_variations(encyclopedia)).is_equal("BookHeading BookStatKey BookStatValue")


func test_a_long_stats_page_uses_the_compact_variations() -> void:
	var encyclopedia: Encyclopedia = _open()
	var stats: Dictionary[String, String] = {}
	for key: String in COMPACT_STATS:
		stats[key] = "1"
	encyclopedia._all_entries["TOWERS"][0]["stats"] = stats

	encyclopedia._update_ui_elements()
	await await_idle_frame()

	assert_str(encyclopedia.stats_grid.theme_type_variation).is_equal(&"BookStatsGridCompact")
	assert_str(_live_label_variations(encyclopedia)).is_equal("BookHeadingCompact BookStatKeyCompact BookStatValueCompact")
	assert_int(encyclopedia.stats_grid.get_theme_constant(&"v_separation")).is_equal(8)


func test_an_undiscovered_entry_after_a_compact_one_uses_the_regular_variations() -> void:
	var encyclopedia: Encyclopedia = _open()
	var stats: Dictionary[String, String] = {}
	for key: String in COMPACT_STATS:
		stats[key] = "1"
	encyclopedia._all_entries["TOWERS"][0]["stats"] = stats
	encyclopedia._update_ui_elements()
	encyclopedia._current_index = 1

	encyclopedia._update_ui_elements()
	await await_idle_frame()

	assert_str(encyclopedia.stats_grid.theme_type_variation).is_equal(&"BookStatsGrid")
	assert_str(_live_label_variations(encyclopedia)).is_equal("BookHeading")


func _live_label_variations(encyclopedia: Encyclopedia) -> String:
	var found: Array[String] = []
	var labels: Array[Node] = encyclopedia.stats_grid.find_children("*", "Label", true, false)
	for label: Label in labels:
		if not label.is_queued_for_deletion() and str(label.theme_type_variation) not in found:
			found.append(str(label.theme_type_variation))
	found.sort_custom(func(a: String, b: String) -> bool: return a < b)
	return " ".join(found)


func _open() -> Encyclopedia:
	var encyclopedia: Encyclopedia = auto_free(ENCYCLOPEDIA_SCENE.instantiate())
	add_child(encyclopedia)
	encyclopedia._current_category = "TOWERS"
	encyclopedia._current_index = 0
	encyclopedia._update_ui_elements()
	return encyclopedia
