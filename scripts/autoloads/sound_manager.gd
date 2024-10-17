## © [2024] A7 Studio. All rights reserved. Trademark.
extends Node


var groups: Dictionary = {}


# core


# public
func register(group: String, sound: Node) -> void:
	if groups.has(group):
		groups[group].append(sound)
	else:
		groups[group] = [sound]

func remove(group: String, sound: Node) -> void:
	if sound in groups[group]:
		groups[group].erase(sound)

func change_volume(group: String, vol: float) -> void:
	if !groups.has(group): return

	for s in groups[group]:
		s.set_volume(vol)
		

# private


# signal


# event


# setget

