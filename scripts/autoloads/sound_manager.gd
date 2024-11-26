## © [2024] A7 Studio. All rights reserved. Trademark.
extends Node

# Private Variables
var _groups: Dictionary = {}

# Public Functions
## Registers a sound node to a specific group
func register(group: String, sound: Node) -> void:
	assert(sound != null, "Sound node cannot be null")
	if _groups.has(group):
		_groups[group].append(sound)
	else:
		_groups[group] = [sound]

## Removes a sound node from a specific group
func remove(group: String, sound: Node) -> void:
	assert(sound != null, "Sound node cannot be null")
	if _groups.has(group) and sound in _groups[group]:
		_groups[group].erase(sound)

## Changes the volume for all sounds in a specific group
func change_volume(group: String, vol: float) -> void:
	if not _groups.has(group):
		return

	for sound in _groups[group]:
		sound.set_volume(vol)
