## © [2024] A7 Studio. All rights reserved. Trademark.
##
## Represents a sound entity that can be managed by the [Class]SoundManager[/Class].
## Automatically registers itself with the sound manager and supports volume control.
class_name SoundEntity extends AudioStreamPlayer

## The group this sound entity belongs to.
@export_enum("sfx", "music", "gui") var group: String


# core
func _ready() -> void:
	SoundManager.register(group, self)


func _exit_tree() -> void:
	SoundManager.remove(group, self)


# public
## Sets the volume of this sound entity.
## [param vol] is the volume in decibels.
func set_volume(vol: float) -> void:
	volume_db = vol
