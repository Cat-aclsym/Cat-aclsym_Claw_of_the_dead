## © [2026] A7 Studio. All rights reserved. Trademark.

class_name InfernoBeam
extends IBullet
## Beam-type projectile for the Inferno Tower.
## Handles instant damage and enhanced beam visual effect.

## Gradient colors (yellow -> orange -> red)
const COLOR_YELLOW: Color = Color(1.0, 0.9, 0.3, 1.0)
const COLOR_ORANGE: Color = Color(1.0, 0.5, 0.1, 1.0)
const COLOR_RED: Color = Color(0.9, 0.1, 0.1, 1.0)

## Base widths
const BEAM_WIDTH_BASE: float = 1.5
const BEAM_WIDTH_MAX: float = 4.0
const FADE_DURATION: float = 0.5

## Wave effect parameters
const NOISE_SPEED: float = 10.0
const NOISE_AMPLITUDE: float = 1.8
const SEGMENTS_COUNT: int = 16

## Gameplay values set by [method ITower._apply_projectile_config] from the tower bullet stats.
## If true, damage doubles over time while the tower stays locked on the target
var is_charging: bool = false
## Damage doubling speed (1.0 doubles the damage every second)
var charge_speed: float = 1.0
## Maximum damage multiplier
var max_damage_multiplier: float = 1.0

## Current target resolved by the tower
var enemy_target: IEnemy = null

## Gradients shared by every beam, built on first use.
static var _glow_gradient: Gradient = null
static var _core_gradient: Gradient = null
static var _inner_gradient: Gradient = null

var _time: float = 0.0
var _damage_accumulator: float = 0.0
var _is_visual_applied: bool = false
var _last_multiplier: float = 1.0
## Multiplier the particle amounts were last computed for, so they are only written when it changes.
var _particles_multiplier: float = 0.0
## Beam points, written in place every frame.
var _points: PackedVector2Array = PackedVector2Array()

@onready var line_core: Line2D = $LineCore
@onready var line_glow: Line2D = $LineGlow
@onready var line_inner: Line2D = $LineInner
@onready var fire_particles: CPUParticles2D = $FireParticles
@onready var spark_particles: CPUParticles2D = $SparkParticles
@onready var impact_sparks: CPUParticles2D = $ImpactSparks

func _ready() -> void:
	assert(is_instance_valid(line_core), "InfernoBeam requires LineCore child")
	assert(is_instance_valid(line_glow), "InfernoBeam requires LineGlow child")
	assert(is_instance_valid(line_inner), "InfernoBeam requires LineInner child")
	assert(is_instance_valid(fire_particles), "InfernoBeam requires FireParticles child")
	assert(is_instance_valid(spark_particles), "InfernoBeam requires SparkParticles child")
	assert(is_instance_valid(impact_sparks), "InfernoBeam requires ImpactSparks child")

	if not is_instance_valid(enemy_target) or not is_instance_valid(tower_owner):
		queue_free()
		return

	_points.resize(SEGMENTS_COUNT + 1)
	_build_gradients()
	line_glow.gradient = _glow_gradient
	line_core.gradient = _core_gradient
	line_inner.gradient = _inner_gradient

	# Configure sparks
	spark_particles.emitting = true

	# Initialize opacity to 0 for fade in
	modulate.a = 0.0
	var fade_in: Tween = create_tween()
	fade_in.tween_property(self, "modulate:a", 1.0, FADE_DURATION)

	# Apply visual effect to the enemy
	_apply_visual_effect(true)


func _exit_tree() -> void:
	# Safety: remove effect if beam is removed abruptly
	_apply_visual_effect(false)


func _process(delta: float) -> void:
	if not is_instance_valid(enemy_target) or not is_instance_valid(tower_owner):
		_start_fade_out()
		return

	_time += delta

	# Continuous visual update
	var current_multiplier: float = 1.0
	if is_charging:
		current_multiplier = minf(pow(2.0, floorf(tower_owner.target_lock_time * charge_speed)), max_damage_multiplier)

	# Accumulate damage to optimize popups
	_damage_accumulator += float(damage) * current_multiplier * delta * (1.0 / tower_owner.fire_rate_timer.wait_time)
	if _damage_accumulator >= 0.1: # Reduced threshold for better responsiveness with the new popup system
		enemy_target.take_damage(_damage_accumulator, IEnemy.DamageType.DEFAULT, tower_owner)
		_damage_accumulator = 0.0

	_update_beam_visuals(current_multiplier)


## Builds the gradients shared by every beam once.
static func _build_gradients() -> void:
	if _glow_gradient != null:
		return

	_glow_gradient = Gradient.new()
	_glow_gradient.set_color(0, Color(1.0, 0.3, 0.0, 0.0)) # Transparent start
	_glow_gradient.add_point(0.2, Color(1.0, 0.4, 0.1, 0.4))
	_glow_gradient.add_point(0.8, Color(1.0, 0.5, 0.2, 0.4))
	_glow_gradient.set_color(1, Color(1.0, 0.6, 0.3, 0.0)) # Transparent end

	_core_gradient = Gradient.new()
	_core_gradient.set_color(0, COLOR_RED)
	_core_gradient.add_point(0.5, COLOR_ORANGE)
	_core_gradient.set_color(1, COLOR_YELLOW)

	_inner_gradient = Gradient.new()
	_inner_gradient.set_color(0, Color(1.0, 1.0, 0.8, 1.0)) # Off-white
	_inner_gradient.add_point(0.5, Color.WHITE)
	_inner_gradient.set_color(1, Color(1.0, 1.0, 0.8, 1.0))


func _apply_visual_effect(apply: bool) -> void:
	if not is_instance_valid(enemy_target):
		return

	if apply:
		enemy_target.push_visual(IEnemy.VISUAL_KEY_INFERNO)
		_is_visual_applied = true
	elif _is_visual_applied:
		enemy_target.pop_visual(IEnemy.VISUAL_KEY_INFERNO)
		_is_visual_applied = false


func _update_beam_visuals(multiplier: float) -> void:
	var from_pos: Vector2 = Vector2.ZERO
	var to_pos: Vector2 = to_local(enemy_target.global_position)
	var distance: float = from_pos.distance_to(to_pos)
	var beam_direction: Vector2 = from_pos.direction_to(to_pos)
	var normal: Vector2 = Vector2(-beam_direction.y, beam_direction.x)

	# Create wave effect by segmenting the line
	for i in range(SEGMENTS_COUNT + 1):
		var t: float = float(i) / SEGMENTS_COUNT
		var pos: Vector2 = from_pos.lerp(to_pos, t)

		# Add sinusoidal noise (wave)
		if i > 0 and i < SEGMENTS_COUNT:
			var wave: float = sin(_time * NOISE_SPEED + t * 10.0) * NOISE_AMPLITUDE
			pos += normal * wave

		_points[i] = pos

	line_core.points = _points
	line_glow.points = _points
	line_inner.points = _points

	# Base size reduced, and about 20% size added per charge tier
	# multiplier is 1.0, 2.0, 4.0, 8.0...
	var step: float = log(multiplier) / log(2.0)
	var size_boost: float = 1.0 + step * 0.2
	line_core.width = BEAM_WIDTH_BASE * size_boost
	line_glow.width = line_core.width * 6.0
	line_inner.width = line_core.width * 0.3

	# Visual flash on scale up (when multiplier changes)
	if multiplier > _last_multiplier:
		_trigger_scale_flash()
	_last_multiplier = multiplier

	# Update particles
	fire_particles.global_position = enemy_target.global_position
	fire_particles.emitting = true
	if multiplier != _particles_multiplier:
		_particles_multiplier = multiplier
		_update_particle_intensity(multiplier)

	# Update sparks along the beam
	spark_particles.emission_rect_extents = Vector2(distance / 2.0, 5.0)
	spark_particles.position = from_pos.lerp(to_pos, 0.5)
	spark_particles.rotation = beam_direction.angle()
	spark_particles.emitting = true

	# Update impact sparks on the zombie
	impact_sparks.global_position = enemy_target.global_position
	impact_sparks.emitting = true


## Scales the particle amounts and sizes with the charge, resizing the particle buffers only when the multiplier changes.
func _update_particle_intensity(multiplier: float) -> void:
	var intensity: float = (multiplier - 1.0) / (max_damage_multiplier - 1.0) if max_damage_multiplier > 1.0 else 0.0
	fire_particles.amount = int(lerp(10, 30, intensity))
	fire_particles.scale_amount_min = lerp(1.0, 2.0, intensity)
	fire_particles.scale_amount_max = lerp(2.0, 4.0, intensity)
	spark_particles.amount = int(lerp(20, 60, intensity))
	impact_sparks.amount = int(lerp(15, 40, intensity))


func _trigger_scale_flash() -> void:
	var flash_tween: Tween = create_tween()
	# Use modulate for flash as default_color is managed by the gradient
	flash_tween.tween_property(line_core, "modulate", Color(2.0, 2.0, 2.0, 1.0), 0.05)
	flash_tween.tween_property(line_core, "modulate", Color.WHITE, 0.15)

	var original_glow: float = line_glow.width
	flash_tween.parallel().tween_property(line_glow, "width", original_glow * 3.0, 0.05)
	flash_tween.tween_property(line_glow, "width", original_glow, 0.15)

func _start_fade_out() -> void:
	set_process(false)

	# Remove visual effect from the enemy
	_apply_visual_effect(false)

	fire_particles.emitting = false
	spark_particles.emitting = false
	impact_sparks.emitting = false

	var fade: Tween = create_tween()
	fade.tween_property(self, "modulate:a", 0.0, FADE_DURATION)
	SignalUtil.connects([{SignalUtil.WHO: fade, SignalUtil.WHAT: "finished", SignalUtil.TO: queue_free}])
