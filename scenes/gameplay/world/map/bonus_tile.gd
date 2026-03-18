## © [2026] A7 Studio. All rights reserved. Trademark.
##
## Visual representation for a bonus tile on the map.
class_name BonusTile
extends Node2D

const BONUS_PARTICLE_ALPHA: float = 1.0
const BONUS_GROUND_ALPHA: float = 1.0
const BONUS_PARTICLE_LAYER_Z_OFFSET: int = 16

var _tint: Color = Color.WHITE

@onready var _bonus_ground: Sprite2D = $BonusGround
@onready var _back_particles: GPUParticles2D = $BonusParticlesBehind
@onready var _front_particles: GPUParticles2D = $BonusParticlesFront

func _ready() -> void:
	z_index = int(global_position.y)
	_apply_configuration()

## Configures the bonus particle tint.
## [param label_text] Kept for compatibility with the map generator.
## [param tint] Tint applied to the particle effect.
func configure(_label_text: String, tint: Color) -> void:
	_tint = tint
	if is_node_ready():
		_apply_configuration()

func _apply_configuration() -> void:
	_bonus_ground.modulate = Color(_tint.r, _tint.g, _tint.b, BONUS_GROUND_ALPHA)
	_back_particles.modulate = Color(_tint.r, _tint.g, _tint.b, BONUS_PARTICLE_ALPHA)
	_front_particles.modulate = Color(_tint.r, _tint.g, _tint.b, BONUS_PARTICLE_ALPHA)
	_back_particles.emitting = true
	_front_particles.emitting = true
