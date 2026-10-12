## © [2026] A7 Studio. All rights reserved. Trademark.
##
## One-time flags, level unlocks, challenge stars and armory unlocks of [ProgressionManager], without touching the save file.
extends GdUnitTestSuite

const FLAG: StringName = &"test_flag"
const OTHER_FLAG: StringName = &"test_other_flag"

var _data_before: ProgressionData = null
var _persistence_before: bool = true


func before_test() -> void:
	_data_before = ProgressionManager.data
	_persistence_before = ProgressionManager.persistence_enabled
	ProgressionManager.data = ProgressionData.new()
	ProgressionManager.persistence_enabled = false


func after_test() -> void:
	ProgressionManager.data = _data_before
	ProgressionManager.persistence_enabled = _persistence_before


func test_complete_challenge_counts_once_per_challenge_as_a_star() -> void:
	ProgressionManager.complete_challenge("lev.01", "cha.000")
	ProgressionManager.complete_challenge("lev.01", "cha.000")
	ProgressionManager.complete_challenge("lev.02", "cha.000")

	assert_int(ProgressionManager.get_total_earned_stars()).is_equal(2)


func test_complete_level_unlocks_the_next_level() -> void:
	assert_bool(ProgressionManager.is_level_unlocked("lev.02")).is_false()

	ProgressionManager.complete_level("lev.01")

	assert_bool(ProgressionManager.is_level_unlocked("lev.02")).is_true()
	assert_bool(ProgressionManager.is_level_unlocked("lev.03")).is_false()


func test_flags_are_independent() -> void:
	ProgressionManager.set_flag(FLAG)

	assert_bool(ProgressionManager.is_flag_set(FLAG)).is_true()
	assert_bool(ProgressionManager.is_flag_set(OTHER_FLAG)).is_false()


func test_flags_start_unset_and_setting_one_twice_keeps_it_set() -> void:
	assert_bool(ProgressionManager.is_flag_set(FLAG)).is_false()

	ProgressionManager.set_flag(FLAG)
	ProgressionManager.set_flag(FLAG)

	assert_bool(ProgressionManager.is_flag_set(FLAG)).is_true()


func test_flag_of_a_legacy_save_is_set() -> void:
	ProgressionManager.data.parameters.from_dictionary({"armory_intro_seen": true})

	assert_bool(ProgressionManager.is_flag_set(&"armory_intro_seen")).is_true()


func test_get_next_level_id() -> void:
	assert_str(ProgressionManager.get_next_level_id("lev.01")).is_equal("lev.02")
	assert_str(ProgressionManager.get_next_level_id("lev.09")).is_equal("lev.10")
	assert_str(ProgressionManager.get_next_level_id("tutorial")).is_empty()


func test_mark_tutorial_completed() -> void:
	assert_bool(ProgressionManager.is_tutorial_completed()).is_false()

	ProgressionManager.mark_tutorial_completed()

	assert_bool(ProgressionManager.is_tutorial_completed()).is_true()


func test_save_is_skipped_while_persistence_is_disabled() -> void:
	var modified_before: int = FileAccess.get_modified_time(ProgressionManager.SAVE_PATH)

	ProgressionManager.set_flag(FLAG)
	ProgressionManager.unlock_level("lev.05")

	assert_int(FileAccess.get_modified_time(ProgressionManager.SAVE_PATH)).is_equal(modified_before)


func test_starter_towers_are_unlocked_and_the_others_need_an_unlock() -> void:
	var locked_id: String = StatsDB.get_tower_ids().filter(func(id: String) -> bool: return id not in ProgressionManager.ARMORY_STARTER_TOWER_IDS)[0]

	for id: String in ProgressionManager.ARMORY_STARTER_TOWER_IDS:
		assert_bool(ProgressionManager.is_tower_unlocked(id)).is_true()
	assert_bool(ProgressionManager.is_tower_unlocked(locked_id)).is_false()

	ProgressionManager.unlock_tower(locked_id)

	assert_bool(ProgressionManager.is_tower_unlocked(locked_id)).is_true()


func test_trap_unlock_and_legacy_mode() -> void:
	var trap_id: String = StatsDB.get_trap_ids()[0]
	assert_bool(ProgressionManager.is_trap_unlocked(trap_id)).is_false()

	ProgressionManager.unlock_trap(trap_id)

	assert_bool(ProgressionManager.is_trap_unlocked(trap_id)).is_true()

	ProgressionManager.data = ProgressionData.new()
	ProgressionManager.data.armory_legacy_mode = true

	assert_bool(ProgressionManager.is_trap_unlocked(trap_id)).is_true()
	assert_bool(ProgressionManager.is_tower_unlocked(StatsDB.get_tower_ids()[0])).is_true()
