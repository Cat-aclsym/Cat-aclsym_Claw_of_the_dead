## © [2026] A7 Studio. All rights reserved. Trademark.
##
## Base class of the map tiles that modify the towers placed on them ([BonusTile], [MalusTile]).
@tool
@abstract
class_name SpecialTile
extends Node2D

const ROOT_Z_BIAS: int = 16

var _tint: Color = Color.WHITE

func _ready() -> void:
	z_as_relative = false
	z_index = int(global_position.y) - ROOT_Z_BIAS
	_setup_layers()
	_ensure_unique_particle_materials()
	_resolve_tint_from_map()
	_apply_configuration()

## Configures the particle tint.
## [param label_text] Kept for compatibility with the map generator.
## [param tint] Tint applied to the particle effect.
func configure(_label_text: String, tint: Color) -> void:
	_tint = tint
	if is_node_ready():
		_apply_configuration()

## Applies [member _tint] to the ground sprite and the particles, then starts the particles.
@abstract func _apply_configuration() -> void

## Particle emitters whose process material must not be shared between tile instances.
@abstract func _get_particles() -> Array[GPUParticles2D]

## Sets the z indices of the tile's child nodes.
@abstract func _setup_layers() -> void

func _ensure_unique_particle_materials() -> void:
	for particles: GPUParticles2D in _get_particles():
		if particles.process_material:
			particles.process_material = (particles.process_material as ParticleProcessMaterial).duplicate(true)

func _find_parent_tilemap() -> TileMapLayer:
	var current: Node = self
	while current != null:
		if current is TileMapLayer:
			return current as TileMapLayer
		current = current.get_parent()
	return null

## Reads the tint of the modifier generated for this tile's cell by the parent [IMap].
func _resolve_tint_from_map() -> void:
	var tile_map: TileMapLayer = _find_parent_tilemap()
	if tile_map == null:
		return

	var map: IMap = tile_map.get_parent() as IMap
	if map == null:
		return

	var tile_pos: Vector2i = tile_map.local_to_map(tile_map.to_local(global_position))
	if not map.special_tiles.has(tile_pos):
		return

	var modifier: Dictionary = map.special_tiles[tile_pos]
	if modifier.has("color"):
		_tint = modifier["color"]
