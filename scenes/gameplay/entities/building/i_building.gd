## © [2026] A7 Studio. All rights reserved. Trademark.
##
## Base class for entities placed via [BuildPlacement] (towers, traps).
class_name IBuilding
extends Node2D

## Discriminator for building-specific gameplay and challenges.
enum BuildingKind {
	TOWER,
	TRAP,
}

## Purchase cost (towers: filled from StatsDB; traps: inspector).
@export var cost: int = 0

## Called when build preview is cancelled (before the preview node is freed).
func cancel_build_preview() -> void:
	pass

## Called when the player enters build preview mode with this building.
func enter_build_preview() -> void:
	pass

## Must be overridden by [ITower] and [ITrap].
func get_building_kind() -> BuildingKind:
	push_error("IBuilding.get_building_kind() must be overridden")
	return IBuilding.BuildingKind.TOWER

## Vertical offset between cursor tile anchor and this node's position during preview.
func get_placement_vertical_offset() -> float:
	return 0.0
