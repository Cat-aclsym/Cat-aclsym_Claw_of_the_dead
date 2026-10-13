## © [2026] A7 Studio. All rights reserved. Trademark.
##
## Represents a sound entity that is routed to an audio bus by the [Class]SoundManager[/Class].
## Automatically registers itself with the sound manager, which sets its bus from its group.
class_name SoundEntity extends AudioStreamPlayer

## The group this sound entity belongs to.
@export_enum("sfx", "music", "gui") var group: String


# core
func _ready() -> void:
	SoundManager.register(group, self)
