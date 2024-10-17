## © [2024] A7 Studio. All rights reserved. Trademark.
class_name SoundEntity
extends AudioStreamPlayer

@export_enum("sfx", "music", "gui") var group: String


# core
func _ready():
	SoundManager.register(group, self)

func _exit_tree():
	SoundManager.remove(group, self)


# public
func set_volume(vol: float) -> void:
	volume_db = vol


# private


# signal


# event


# setget

