## © [2026] A7 Studio. All rights reserved. Trademark.
##
## Sprite decoration that blocks tower placement on overlapping tilemap cells.
class_name MapPlacementBlocker
extends Sprite2D

## Extra tile offsets from this sprite's anchor cell (map space).
@export var blocked_tile_offsets: Array[Vector2i] = []

## When true, every tile whose center lies inside the sprite bounds is blocked.
@export var use_sprite_bounds: bool = true


## Returns tilemap cells that must not accept towers under this decoration.
## [param tilemap] The map [TileMap] used for coordinate conversion.
func get_blocked_cells(tilemap: TileMap) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	if use_sprite_bounds and texture != null:
		var sprite_rect := _get_drawn_world_rect()
		var min_cell := tilemap.local_to_map(sprite_rect.position) - Vector2i(2, 2)
		var max_cell := tilemap.local_to_map(sprite_rect.end) + Vector2i(2, 2)
		for x: int in range(min_cell.x, max_cell.x + 1):
			for y: int in range(min_cell.y, max_cell.y + 1):
				var cell := Vector2i(x, y)
				if sprite_rect.has_point(tilemap.map_to_local(cell)) and cell not in cells:
					cells.append(cell)

	if not blocked_tile_offsets.is_empty():
		var anchor_cell := tilemap.local_to_map(_get_anchor_global_position())
		for offset: Vector2i in blocked_tile_offsets:
			var cell := anchor_cell + offset
			if cell not in cells:
				cells.append(cell)

	return cells


func _get_anchor_global_position() -> Vector2:
	if centered:
		return global_position
	return global_position + offset


func _get_drawn_world_rect() -> Rect2:
	var texture_size := texture.get_size()
	var top_left := global_position
	if centered:
		top_left -= texture_size * 0.5
	else:
		top_left += offset
	return Rect2(top_left, texture_size)
