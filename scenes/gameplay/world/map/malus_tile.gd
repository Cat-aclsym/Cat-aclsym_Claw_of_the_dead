## © [2026] A7 Studio. All rights reserved. Trademark.
##
## Visual representation for a malus tile on the map.
@tool
class_name MalusTile
extends Node2D

const MALUS_GROUND_ALPHA: float = 0.85
const MALUS_GROUND_LAYER_Z_OFFSET: int = 1
const MALUS_GROUND_TINT_WHITE_BLEND: float = 0.28
const MALUS_PARTICLE_ALPHA: float = 0.75
const MALUS_PARTICLE_LAYER_Z_OFFSET: int = 12
const MALUS_PARTICLE_TINT_WHITE_BLEND: float = 0.5
const MALUS_ROOT_Z_BIAS: int = 16
const MALUS_INTRO_FADE_IN_SECONDS: float = 0.4

var _tint: Color = Color.WHITE
var _intro_started: bool = false

@onready var _ground: Sprite2D = $MalusGround
@onready var _particles: GPUParticles2D = $MalusParticles

func _ready() -> void:
	z_as_relative = false
	z_index = int(global_position.y) - MALUS_ROOT_Z_BIAS
	_ground.z_index = -MALUS_GROUND_LAYER_Z_OFFSET
	_particles.z_index = MALUS_PARTICLE_LAYER_Z_OFFSET
	_ensure_unique_particle_material()
	_resolve_tint_from_map()
	modulate.a = 0.0
	_apply_configuration()
	if not _intro_started:
		_intro_started = true
		var intro_tween: Tween = create_tween()
		intro_tween.tween_property(self, "modulate:a", 1.0, MALUS_INTRO_FADE_IN_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

## Configures the malus particle tint.
## [param label_text] Kept for compatibility with the map generator.
## [param tint] Tint applied to the particle effect.
func configure(_label_text: String, tint: Color) -> void:
	_tint = tint
	if is_node_ready():
		_apply_configuration()

func _apply_configuration() -> void:
	modulate = Color(1.0, 1.0, 1.0, modulate.a)

	var particle_tint := _tint.lerp(Color.WHITE, MALUS_PARTICLE_TINT_WHITE_BLEND)
	particle_tint.a = 1.0
	var ground_tint := _tint.lerp(Color.WHITE, MALUS_GROUND_TINT_WHITE_BLEND)
	ground_tint.a = 1.0

	_ground.modulate = Color(ground_tint.r, ground_tint.g, ground_tint.b, MALUS_GROUND_ALPHA)
	(_particles.process_material as ParticleProcessMaterial).color = Color(particle_tint.r, particle_tint.g, particle_tint.b, MALUS_PARTICLE_ALPHA)
	_particles.emitting = true

func _ensure_unique_particle_material() -> void:
	if _particles.process_material:
		_particles.process_material = (_particles.process_material as ParticleProcessMaterial).duplicate(true)

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
