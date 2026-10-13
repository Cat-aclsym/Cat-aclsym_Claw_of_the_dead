## © [2026] A7 Studio. All rights reserved. Trademark.
##
## Routes sound groups to audio buses and drives their volume and mute state.
## Volumes live on the buses of [code]default_bus_layout.tres[/code], so they apply to sounds created later and keep per-node offsets.
extends Node

## Audio bus name of each [SoundEntity] group.
const GROUP_BUSES: Dictionary[String, StringName] = {
	"gui": &"UI",
	"music": &"Music",
	"sfx": &"SFX",
}

# public
## Sets the volume of the bus of [param group], [param linear_volume] goes from 0.0 (silent) to 1.0 (full scale).
func change_volume(group: String, linear_volume: float) -> void:
	var bus_index: int = _get_bus_index(group)
	if bus_index != -1:
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(linear_volume))


## Routes [param sound] to the audio bus of [param group].
func register(group: String, sound: AudioStreamPlayer) -> void:
	assert(sound != null, "Sound node cannot be null")
	if not GROUP_BUSES.has(group):
		Log.trace(Log.Level.WARN, "SoundManager: unknown sound group '%s' for %s" % [group, sound.name])
		return
	sound.bus = GROUP_BUSES[group]


## Mutes or unmutes the bus of [param group].
func set_group_enabled(group: String, enabled: bool) -> void:
	var bus_index: int = _get_bus_index(group)
	if bus_index != -1:
		AudioServer.set_bus_mute(bus_index, not enabled)


# private
func _get_bus_index(group: String) -> int:
	var bus_index: int = AudioServer.get_bus_index(GROUP_BUSES.get(group, &""))
	if bus_index == -1:
		Log.trace(Log.Level.WARN, "SoundManager: no audio bus for sound group '%s'" % group)
	return bus_index
