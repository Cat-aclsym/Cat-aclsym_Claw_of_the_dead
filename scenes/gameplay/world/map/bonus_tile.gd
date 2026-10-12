## © [2026] A7 Studio. All rights reserved. Trademark.
##
## Visual representation for a bonus tile on the map.
@tool
class_name BonusTile
extends SpecialTile

const BONUS_PARTICLE_ALPHA: float = 0.8
const BONUS_GROUND_ALPHA: float = 0.8
const BONUS_PARTICLE_LAYER_Z_OFFSET: int = 16
const BONUS_DECORATION_LAYER_Z_OFFSET: int = 10
const BONUS_GROUND_LAYER_Z_OFFSET: int = 1
const BONUS_PARTICLE_TINT_WHITE_BLEND: float = 0.72
const BONUS_GROUND_TINT_WHITE_BLEND: float = 0.42

@onready var _bonus_ground: Sprite2D = $BonusGround
@onready var _back_particles: GPUParticles2D = $BonusParticlesBehind
@onready var _front_particles: GPUParticles2D = $BonusParticlesFront
@onready var _emitting_particle: GPUParticles2D = $EmittingParticle

func _apply_configuration() -> void:
	modulate = Color.WHITE

	var particle_tint := _tint.lerp(Color.WHITE, BONUS_PARTICLE_TINT_WHITE_BLEND)
	particle_tint.a = 1.0
	var ground_tint := _tint.lerp(Color.WHITE, BONUS_GROUND_TINT_WHITE_BLEND)
	ground_tint.a = 1.0

	_bonus_ground.modulate = Color(ground_tint.r, ground_tint.g, ground_tint.b, BONUS_GROUND_ALPHA)

	var particle_color: Color = Color(particle_tint.r, particle_tint.g, particle_tint.b, BONUS_PARTICLE_ALPHA)

	(_back_particles.process_material as ParticleProcessMaterial).color = particle_color
	(_emitting_particle.process_material as ParticleProcessMaterial).color = Color(1, 1, 1, 0.65)
	(_front_particles.process_material as ParticleProcessMaterial).color = particle_color

	_back_particles.emitting = true
	_emitting_particle.emitting = true
	_front_particles.emitting = true

func _get_particles() -> Array[GPUParticles2D]:
	return [_back_particles, _emitting_particle, _front_particles]

func _setup_layers() -> void:
	_bonus_ground.z_index = -BONUS_GROUND_LAYER_Z_OFFSET
	_back_particles.z_index = -BONUS_PARTICLE_LAYER_Z_OFFSET
	_emitting_particle.z_index = BONUS_DECORATION_LAYER_Z_OFFSET
	_front_particles.z_index = BONUS_PARTICLE_LAYER_Z_OFFSET
