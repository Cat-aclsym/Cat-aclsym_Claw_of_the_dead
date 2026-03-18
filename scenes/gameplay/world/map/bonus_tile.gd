## © [2026] A7 Studio. All rights reserved. Trademark.
##
## Visual representation for a bonus tile on the map.
class_name BonusTile
extends Node2D

const BONUS_PARTICLE_ALPHA: float = 1.0

var _tint: Color = Color.WHITE

@onready var _particles: GPUParticles2D = $GPUParticles2D

func _ready() -> void:
	_apply_configuration()

## Configures the bonus particle tint.
## [param label_text] Kept for compatibility with the map generator.
## [param tint] Tint applied to the particle effect.
func configure(_label_text: String, tint: Color) -> void:
	_tint = tint
	if is_node_ready():
		_apply_configuration()

func _apply_configuration() -> void:
	_particles.modulate = Color(_tint.r, _tint.g, _tint.b, BONUS_PARTICLE_ALPHA)
	_particles.emitting = true
