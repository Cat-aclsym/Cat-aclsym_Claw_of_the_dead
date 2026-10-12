## © [2026] A7 Studio. All rights reserved. Trademark.
##
## [SettingsData] serialization and the migration of the legacy [code]armory_intro_seen[/code] key.
extends GdUnitTestSuite


func test_from_dictionary_defaults() -> void:
	var settings: SettingsData = SettingsData.new()

	settings.from_dictionary({})

	assert_dict(settings.flags).is_empty()
	assert_str(settings.language).is_equal("fr")
	assert_bool(settings.music_enabled).is_true()
	assert_bool(settings.sound_enabled).is_true()
	assert_bool(settings.tutorial_completed).is_false()


func test_from_dictionary_keeps_the_flags() -> void:
	var settings: SettingsData = SettingsData.new()

	settings.from_dictionary({"flags": {"first_boss_seen": true}})

	assert_dict(settings.flags).is_equal({"first_boss_seen": true})


func test_from_dictionary_migrates_the_legacy_armory_intro_key() -> void:
	var settings: SettingsData = SettingsData.new()

	settings.from_dictionary({"armory_intro_seen": true, "flags": {"first_boss_seen": true}})

	assert_dict(settings.flags).is_equal({"first_boss_seen": true, "armory_intro_seen": true})


func test_from_dictionary_ignores_a_false_legacy_armory_intro_key() -> void:
	var settings: SettingsData = SettingsData.new()

	settings.from_dictionary({"armory_intro_seen": false})

	assert_dict(settings.flags).is_empty()


func test_save_round_trips_through_from_dictionary() -> void:
	var settings: SettingsData = SettingsData.new()
	settings.flags["first_boss_seen"] = true
	settings.language = "en"
	settings.music_enabled = false
	settings.sound_enabled = false
	settings.tutorial_completed = true
	var restored: SettingsData = SettingsData.new()

	restored.from_dictionary(settings.save())

	assert_dict(restored.save()).is_equal(settings.save())


func test_save_returns_a_copy_of_the_flags() -> void:
	var settings: SettingsData = SettingsData.new()
	var saved: Dictionary = settings.save()

	saved["flags"]["first_boss_seen"] = true

	assert_dict(settings.flags).is_empty()
