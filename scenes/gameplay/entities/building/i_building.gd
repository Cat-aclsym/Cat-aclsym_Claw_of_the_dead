## © [2026] A7 Studio. All rights reserved. Trademark.
##
## Base class for entities placed via [BuildPlacement] (towers, traps).
@abstract
class_name IBuilding
extends Node2D

## Discriminator for building-specific gameplay and challenges.
enum BuildingKind {
	TOWER,
	TRAP,
}

## Purchase cost (towers: filled from StatsDB; traps: inspector).
@export var cost: int = 0

## Tile position used by the placement system occupancy checks.
var tile_pos: Vector2i = Vector2i.ZERO

## Called when build preview is cancelled (before the preview node is freed).
func cancel_build_preview() -> void:
	pass

## Called when the player enters build preview mode with this building.
func enter_build_preview() -> void:
	pass

## Implemented by [ITower] and [ITrap].
@abstract func get_building_kind() -> BuildingKind

## Vertical offset between cursor tile anchor and this node's position during preview.
func get_placement_vertical_offset() -> float:
	return 0.0


## Marks [member tile_pos] as occupied in the placement system, computing it from the position when it is not set yet.
## [br]Returns true when the cell was registered.
func _register_with_cursor() -> bool:
	if not is_inside_tree():
		return false

	var placement_system: BuildPlacement = Global.cursor
	if not is_instance_valid(placement_system):
		return false

	if tile_pos == Vector2i.ZERO and placement_system.tm_ref:
		tile_pos = placement_system.tm_ref.local_to_map(placement_system.tm_ref.to_local(global_position))
	placement_system.add_invalid_cell(tile_pos)
	return true
