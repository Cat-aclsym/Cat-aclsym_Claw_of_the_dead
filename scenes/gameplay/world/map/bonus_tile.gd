## © [2026] A7 Studio. All rights reserved. Trademark.
##
## Visual representation for a bonus tile on the map.
@tool
class_name BonusTile
extends Node2D

const BONUS_PARTICLE_ALPHA: float = 0.8
const BONUS_GROUND_ALPHA: float = 0.8
const BONUS_ROOT_Z_BIAS: int = 16
const BONUS_PARTICLE_LAYER_Z_OFFSET: int = 16
const BONUS_DECORATION_LAYER_Z_OFFSET: int = 10
const BONUS_GROUND_LAYER_Z_OFFSET: int = 1
const BONUS_PARTICLE_TINT_WHITE_BLEND: float = 0.72
const BONUS_GROUND_TINT_WHITE_BLEND: float = 0.42

var _tint: Color = Color.WHITE

@onready var _bonus_ground: Sprite2D = $BonusGround
@onready var _back_particles: GPUParticles2D = $BonusParticlesBehind
@onready var _front_particles: GPUParticles2D = $BonusParticlesFront
@onready var _emissing_particle: GPUParticles2D = $EmissingParticle

func _ready() -> void:
	z_as_relative = false
	z_index = int(global_position.y) - BONUS_ROOT_Z_BIAS
	_bonus_ground.z_index = -BONUS_GROUND_LAYER_Z_OFFSET
	_back_particles.z_index = -BONUS_PARTICLE_LAYER_Z_OFFSET
	_emissing_particle.z_index = BONUS_DECORATION_LAYER_Z_OFFSET
	_front_particles.z_index = BONUS_PARTICLE_LAYER_Z_OFFSET
	_ensure_unique_particle_materials()
	_resolve_tint_from_map()
	_apply_configuration()

## Configures the bonus particle tint.
## [param label_text] Kept for compatibility with the map generator.
## [param tint] Tint applied to the particle effect.
func configure(_label_text: String, tint: Color) -> void:
	_tint = tint
	if is_node_ready():
		_apply_configuration()

func _apply_configuration() -> void:
	modulate = Color.WHITE

	var particle_tint := _tint.lerp(Color.WHITE, BONUS_PARTICLE_TINT_WHITE_BLEND)
	particle_tint.a = 1.0
	var ground_tint := _tint.lerp(Color.WHITE, BONUS_GROUND_TINT_WHITE_BLEND)
	ground_tint.a = 1.0

	_bonus_ground.modulate = Color(ground_tint.r, ground_tint.g, ground_tint.b, BONUS_GROUND_ALPHA)

	var particle_color = Color(particle_tint.r, particle_tint.g, particle_tint.b, BONUS_PARTICLE_ALPHA)

	(_back_particles.process_material as ParticleProcessMaterial).color = particle_color
	(_emissing_particle.process_material as ParticleProcessMaterial).color = Color(1, 1, 1, 0.65)
	(_front_particles.process_material as ParticleProcessMaterial).color = particle_color

	_back_particles.emitting = true
	_emissing_particle.emitting = true
	_front_particles.emitting = true

func _ensure_unique_particle_materials() -> void:
	if _back_particles.process_material:
		_back_particles.process_material = (_back_particles.process_material as ParticleProcessMaterial).duplicate(true)
	if _emissing_particle.process_material:
		_emissing_particle.process_material = (_emissing_particle.process_material as ParticleProcessMaterial).duplicate(true)
	if _front_particles.process_material:
		_front_particles.process_material = (_front_particles.process_material as ParticleProcessMaterial).duplicate(true)

func _resolve_tint_from_map() -> void:
	var tile_map := _find_parent_tilemap()
	if tile_map == null:
		return

	var map_node := tile_map.get_parent()
	if not (map_node is IMap):
		return

	var map := map_node as IMap
	var tile_pos := tile_map.local_to_map(tile_map.to_local(global_position))
	if not map.special_tiles.has(tile_pos):
		return

	var modifier: Dictionary = map.special_tiles[tile_pos]
	if modifier.has("color"):
		_tint = modifier["color"]

func _find_parent_tilemap() -> TileMap:
	var current: Node = self
	while current != null:
		if current is TileMap:
			return current as TileMap
		current = current.get_parent()
	return null
