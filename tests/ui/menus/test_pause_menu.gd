## © [2026] A7 Studio. All rights reserved. Trademark.
##
## The music and sound buttons of the pause menu change the same settings as the options menu.
extends GdUnitTestSuite

const PAUSE_SCENE: PackedScene = preload("res://ui/menus/pause/pause.tscn")

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


func test_the_buttons_show_the_saved_settings() -> void:
	ProgressionManager.data.parameters.music_enabled = false
	ProgressionManager.data.parameters.sound_enabled = true

	var pause: Pause = await _open_pause_menu()

	assert_bool(pause.music_button.button_pressed).is_true()
	assert_bool(pause.sound_button.button_pressed).is_false()


func test_the_music_button_toggles_the_music_setting_and_its_bus() -> void:
	var pause: Pause = await _open_pause_menu()
	var music_bus: int = AudioServer.get_bus_index(SoundManager.GROUP_BUSES["music"])

	pause.music_button.button_pressed = true
	assert_bool(ProgressionManager.data.parameters.music_enabled).is_false()
	assert_bool(AudioServer.is_bus_mute(music_bus)).is_true()

	pause.music_button.button_pressed = false
	assert_bool(ProgressionManager.data.parameters.music_enabled).is_true()
	assert_bool(AudioServer.is_bus_mute(music_bus)).is_false()


func test_the_sound_button_toggles_the_sound_setting_and_its_buses() -> void:
	var pause: Pause = await _open_pause_menu()
	var sfx_bus: int = AudioServer.get_bus_index(SoundManager.GROUP_BUSES["sfx"])
	var gui_bus: int = AudioServer.get_bus_index(SoundManager.GROUP_BUSES["gui"])

	pause.sound_button.button_pressed = true
	assert_bool(ProgressionManager.data.parameters.sound_enabled).is_false()
	assert_bool(AudioServer.is_bus_mute(sfx_bus)).is_true()
	assert_bool(AudioServer.is_bus_mute(gui_bus)).is_true()

	pause.sound_button.button_pressed = false
	assert_bool(ProgressionManager.data.parameters.sound_enabled).is_true()
	assert_bool(AudioServer.is_bus_mute(sfx_bus)).is_false()


func _open_pause_menu() -> Pause:
	var pause: Pause = auto_free(PAUSE_SCENE.instantiate())
	add_child(pause)
	await get_tree().process_frame
	return pause
