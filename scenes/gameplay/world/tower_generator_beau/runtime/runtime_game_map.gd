## © [2024] A7 Studio. All rights reserved. Trademark.
##
## Map générée en runtime avec toutes ses données.

class_name RuntimeGameMap
extends RefCounted

var width: int
var height: int
var grid: Array[Array] = []
var paths: Array[MapPath] = []
var spawns: Array[Vector2i] = []
var exits: Array[Vector2i] = []

func _init(w: int, h: int):
	width = w
	height = h
	grid = []
	for x in range(width):
		var column: Array = []
		for y in range(height):
			column.append(MapTile.new(x, y))
		grid.append(column)

func get_tile(x: int, y: int) -> MapTile:
	if x >= 0 and x < width and y >= 0 and y < height:
		return grid[x][y]
	return null

func set_tile_type(x: int, y: int, t_type: int) -> void:
	var tile = get_tile(x, y)
	if tile:
		tile.type = t_type
		var pos = Vector2i(x, y)
		if t_type == 3:  # TileType.SPAWN
			if not spawns.has(pos):
				spawns.append(pos)
		elif t_type == 4:  # TileType.EXIT
			if not exits.has(pos):
				exits.append(pos)
