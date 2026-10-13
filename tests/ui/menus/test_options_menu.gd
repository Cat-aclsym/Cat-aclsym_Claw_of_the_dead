## © [2026] A7 Studio. All rights reserved. Trademark.
##
## The music, sound and language buttons of the options menu show and change the saved settings.
extends GdUnitTestSuite

const OPTIONS_SCENE: PackedScene = preload("res://ui/menus/options/options.tscn")

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
	ProgressionManager.apply_settings()


func test_the_toggles_show_the_saved_settings() -> void:
	ProgressionManager.data.parameters.music_enabled = false
	ProgressionManager.data.parameters.sound_enabled = true

	var options: Options = await _open_options_menu()

	assert_bool(options.music_toggle_button.button_pressed).is_true()
	assert_int(options.music_toggle_button.get_effective_icon()).is_equal(GameIcon.Id.MUSIC_OFF)
	assert_bool(options.sound_toggle_button.button_pressed).is_false()
	assert_int(options.sound_toggle_button.get_effective_icon()).is_equal(GameIcon.Id.SOUND)


func test_the_music_toggle_updates_the_music_setting_and_its_bus() -> void:
	var options: Options = await _open_options_menu()
	var music_bus: int = AudioServer.get_bus_index(SoundManager.GROUP_BUSES["music"])

	options.music_toggle_button.button_pressed = true
	assert_bool(ProgressionManager.data.parameters.music_enabled).is_false()
	assert_bool(AudioServer.is_bus_mute(music_bus)).is_true()
	assert_int(options.music_toggle_button.get_effective_icon()).is_equal(GameIcon.Id.MUSIC_OFF)

	options.music_toggle_button.button_pressed = false
	assert_bool(ProgressionManager.data.parameters.music_enabled).is_true()
	assert_bool(AudioServer.is_bus_mute(music_bus)).is_false()
	assert_int(options.music_toggle_button.get_effective_icon()).is_equal(GameIcon.Id.MUSIC)


func test_the_sound_toggle_updates_the_sound_setting_and_its_buses() -> void:
	var options: Options = await _open_options_menu()
	var sfx_bus: int = AudioServer.get_bus_index(SoundManager.GROUP_BUSES["sfx"])
	var gui_bus: int = AudioServer.get_bus_index(SoundManager.GROUP_BUSES["gui"])

	options.sound_toggle_button.button_pressed = true
	assert_bool(ProgressionManager.data.parameters.sound_enabled).is_false()
	assert_bool(AudioServer.is_bus_mute(sfx_bus)).is_true()
	assert_bool(AudioServer.is_bus_mute(gui_bus)).is_true()

	options.sound_toggle_button.button_pressed = false
	assert_bool(ProgressionManager.data.parameters.sound_enabled).is_true()
	assert_bool(AudioServer.is_bus_mute(sfx_bus)).is_false()


func test_the_language_button_shows_the_other_language_and_switches_it() -> void:
	ProgressionManager.data.parameters.language = "en"
	var options: Options = await _open_options_menu()
	assert_int(options.language_toggle_button.game_icon).is_equal(GameIcon.Id.FLAG_FR)

	options.language_toggle_button.pressed.emit()
	assert_str(ProgressionManager.data.parameters.language).is_equal("fr")
	assert_int(options.language_toggle_button.game_icon).is_equal(GameIcon.Id.FLAG_EN)

	options.language_toggle_button.pressed.emit()
	assert_str(ProgressionManager.data.parameters.language).is_equal("en")
	assert_int(options.language_toggle_button.game_icon).is_equal(GameIcon.Id.FLAG_FR)


func _open_options_menu() -> Options:
	var options: Options = auto_free(OPTIONS_SCENE.instantiate())
	add_child(options)
	await get_tree().process_frame
	return options
