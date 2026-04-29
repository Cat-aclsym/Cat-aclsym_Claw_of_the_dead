## © [2024] A7 Studio. All rights reserved. Trademark.
##
## Représente un chemin pour les ennemis.

class_name MapPath
extends RefCounted

var points: Array[Vector2i] = []

func _init(ppoints: Array[Vector2i] = []):
	points = ppoints

func get_length() -> int:
	return points.size()
