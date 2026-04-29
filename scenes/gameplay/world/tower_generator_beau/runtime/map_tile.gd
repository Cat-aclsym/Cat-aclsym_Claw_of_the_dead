## © [2024] A7 Studio. All rights reserved. Trademark.
##
## Structures de données pour la génération de maps en runtime.

class_name MapTile
## Représente une tuile de la map avec ses propriétés.

var x: int
var y: int
var type: int = 0  # TileType.EMPTY
var score: float = 0.0

func _init(px: int = 0, py: int = 0, ptype: int = 0):  # ptype = TileType.EMPTY
	x = px
	y = py
	type = ptype
