## © [2026] A7 Studio. All rights reserved. Trademark.
##
## [Narrative] timeline lookup by locale and the one-time playback guard.
extends GdUnitTestSuite

const BASE: String = "armory_intro"
const FLAG: StringName = &"test_narrative_flag"

var _data_before: ProgressionData = null
var _locale_before: String = ""
var _persistence_before: bool = true


func before_test() -> void:
	_locale_before = TranslationServer.get_locale()
	_data_before = ProgressionManager.data
	_persistence_before = ProgressionManager.persistence_enabled
	ProgressionManager.data = ProgressionData.new()
	ProgressionManager.persistence_enabled = false
	Global.clear_pauses()


func after_test() -> void:
	Dialogic.current_timeline = null
	if Dialogic.Styles.has_active_layout_node():
		Dialogic.clear(Dialogic.ClearFlags.FULL_CLEAR)
	Global.clear_pauses()
	ProgressionManager.data = _data_before
	ProgressionManager.persistence_enabled = _persistence_before
	TranslationServer.set_locale(_locale_before)


func test_play_once_is_refused_when_the_flag_is_already_set() -> void:
	ProgressionManager.set_flag(FLAG)

	assert_bool(Narrative.play_once(FLAG, BASE)).is_false()
	assert_bool(Global.paused).is_false()
	assert_object(Dialogic.current_timeline).is_null()


func test_play_once_is_refused_while_a_timeline_runs() -> void:
	Dialogic.current_timeline = DialogicTimeline.new()

	assert_bool(Narrative.play_once(FLAG, BASE)).is_false()
	assert_bool(ProgressionManager.is_flag_set(FLAG)).is_false()
	assert_bool(Global.paused).is_false()


@warning_ignore("unused_parameter")
func test_play_once_sets_the_flag_and_pauses_until_the_timeline_ends(timeout: int = 10000) -> void:
	var process_mode_before: Node.ProcessMode = Dialogic.process_mode

	assert_bool(Narrative.play_once(FLAG, BASE)).is_true()
	assert_bool(ProgressionManager.is_flag_set(FLAG)).is_true()
	assert_bool(Global.paused).is_true()

	Dialogic.end_timeline(true)
	await await_idle_frame()

	assert_bool(Global.paused).is_false()
	assert_int(Dialogic.process_mode).is_equal(process_mode_before)
	assert_bool(Narrative.play_once(FLAG, BASE)).is_false()


func test_timeline_path_falls_back_to_english_for_a_locale_without_timeline() -> void:
	TranslationServer.set_locale("de")

	assert_str(Narrative.timeline_path(BASE)).is_equal("res://assets/narrative/armory_intro.en.dtl")


func test_timeline_path_follows_the_locale() -> void:
	TranslationServer.set_locale("fr")
	assert_str(Narrative.timeline_path(BASE)).is_equal("res://assets/narrative/armory_intro.fr.dtl")

	TranslationServer.set_locale("en")
	assert_str(Narrative.timeline_path(BASE)).is_equal("res://assets/narrative/armory_intro.en.dtl")


func test_timeline_path_uses_the_language_of_a_regional_locale() -> void:
	TranslationServer.set_locale("fr_CA")

	assert_str(Narrative.timeline_path(BASE)).is_equal("res://assets/narrative/armory_intro.fr.dtl")
