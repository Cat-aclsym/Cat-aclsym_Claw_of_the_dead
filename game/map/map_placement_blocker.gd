## © [2026] A7 Studio. All rights reserved. Trademark.
##
## Sprite decoration that blocks tower placement on overlapping tilemap cells, collected by [method IMap.get_blocked_cells].
class_name MapPlacementBlocker
extends Sprite2D

## Extra tile offsets from this sprite's anchor cell (map space).
@export var blocked_tile_offsets: Array[Vector2i] = []

## Shrinks the effective blocking rect on each side (pixels).
## Increase to allow placement closer to concave rock edges.
@export_range(0, 64, 1) var bounds_inset_px: int = 12

## When true, every tile whose center lies inside the sprite bounds is blocked.
## The bounds are the texture size around the node origin, the node scale is ignored.
@export var use_sprite_bounds: bool = true


## Returns the cells (as a set) of [param tilemap] that must not accept towers under this decoration.
## [param tilemap] The map [TileMapLayer] used for coordinate conversion.
func get_blocked_cells(tilemap: TileMapLayer) -> Dictionary[Vector2i, bool]:
	var cells: Dictionary[Vector2i, bool] = {}
	if use_sprite_bounds and texture != null:
		var sprite_rect: Rect2 = _get_drawn_world_rect().grow(-bounds_inset_px)
		var corners: Array[Vector2] = [
			sprite_rect.position,
			sprite_rect.end,
			Vector2(sprite_rect.position.x, sprite_rect.end.y),
			Vector2(sprite_rect.end.x, sprite_rect.position.y),
		]
		var min_cell: Vector2i = tilemap.local_to_map(tilemap.to_local(corners[0]))
		var max_cell: Vector2i = min_cell
		for corner: Vector2 in corners:
			var corner_cell: Vector2i = tilemap.local_to_map(tilemap.to_local(corner))
			min_cell = min_cell.min(corner_cell)
			max_cell = max_cell.max(corner_cell)

		for x: int in range(min_cell.x - 2, max_cell.x + 3):
			for y: int in range(min_cell.y - 2, max_cell.y + 3):
				var cell: Vector2i = Vector2i(x, y)
				if sprite_rect.has_point(tilemap.to_global(tilemap.map_to_local(cell))):
					cells[cell] = true

	if not blocked_tile_offsets.is_empty():
		var anchor_cell: Vector2i = tilemap.local_to_map(tilemap.to_local(_get_anchor_global_position()))
		for offset_cell: Vector2i in blocked_tile_offsets:
			cells[anchor_cell + offset_cell] = true

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
