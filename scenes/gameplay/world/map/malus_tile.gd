## © [2026] A7 Studio. All rights reserved. Trademark.
##
## Visual representation for a malus tile on the map.
@tool
class_name MalusTile
extends SpecialTile

const MALUS_GROUND_ALPHA: float = 0.85
const MALUS_GROUND_LAYER_Z_OFFSET: int = 1
const MALUS_GROUND_TINT_WHITE_BLEND: float = 0.28
const MALUS_INTRO_FADE_IN_SECONDS: float = 0.4
const MALUS_PARTICLE_ALPHA: float = 0.75
const MALUS_PARTICLE_LAYER_Z_OFFSET: int = 12
const MALUS_PARTICLE_TINT_WHITE_BLEND: float = 0.5

var _intro_started: bool = false

@onready var _ground: Sprite2D = $MalusGround
@onready var _particles: GPUParticles2D = $MalusParticles

func _ready() -> void:
	super()
	modulate.a = 0.0
	if not _intro_started:
		_intro_started = true
		var intro_tween: Tween = create_tween()
		intro_tween.tween_property(self, "modulate:a", 1.0, MALUS_INTRO_FADE_IN_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _apply_configuration() -> void:
	modulate = Color(1.0, 1.0, 1.0, modulate.a)

	var particle_tint := _tint.lerp(Color.WHITE, MALUS_PARTICLE_TINT_WHITE_BLEND)
	particle_tint.a = 1.0
	var ground_tint := _tint.lerp(Color.WHITE, MALUS_GROUND_TINT_WHITE_BLEND)
	ground_tint.a = 1.0

	_ground.modulate = Color(ground_tint.r, ground_tint.g, ground_tint.b, MALUS_GROUND_ALPHA)
	(_particles.process_material as ParticleProcessMaterial).color = Color(particle_tint.r, particle_tint.g, particle_tint.b, MALUS_PARTICLE_ALPHA)
	_particles.emitting = true

func _get_particles() -> Array[GPUParticles2D]:
	return [_particles]

func _setup_layers() -> void:
	_ground.z_index = -MALUS_GROUND_LAYER_Z_OFFSET
	_particles.z_index = MALUS_PARTICLE_LAYER_Z_OFFSET
