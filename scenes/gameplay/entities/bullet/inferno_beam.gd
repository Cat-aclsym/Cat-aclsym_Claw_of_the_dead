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

## If true, damage increases over time
@export var is_charging: bool = false
## Damage increase speed (multiplier per second)
@export var charge_speed: float = 0.5
## Maximum damage multiplier
@export var max_damage_multiplier: float = 4.0

## Current target resolved by the tower
var enemy_target: IEnemy = null

var _time: float = 0.0
var _damage_accumulator: float = 0.0

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
	
	# Configure gradients
	var gradient_glow: Gradient = Gradient.new()
	gradient_glow.set_color(0, Color(1.0, 0.3, 0.0, 0.0)) # Transparent start
	gradient_glow.add_point(0.2, Color(1.0, 0.4, 0.1, 0.4))
	gradient_glow.add_point(0.8, Color(1.0, 0.5, 0.2, 0.4))
	gradient_glow.set_color(1, Color(1.0, 0.6, 0.3, 0.0)) # Transparent end
	line_glow.gradient = gradient_glow
	
	var gradient_core: Gradient = Gradient.new()
	gradient_core.set_color(0, COLOR_RED)
	gradient_core.add_point(0.5, COLOR_ORANGE)
	gradient_core.set_color(1, COLOR_YELLOW)
	line_core.gradient = gradient_core
	
	var gradient_inner: Gradient = Gradient.new()
	gradient_inner.set_color(0, Color(1.0, 1.0, 0.8, 1.0)) # Off-white
	gradient_inner.add_point(0.5, Color.WHITE)
	gradient_inner.set_color(1, Color(1.0, 1.0, 0.8, 1.0))
	line_inner.gradient = gradient_inner
	
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


func _apply_visual_effect(apply: bool) -> void:
	if is_instance_valid(enemy_target) and enemy_target.has_method("push_inferno_visual"):
		if apply:
			enemy_target.push_inferno_visual()
			set_meta("_visual_applied", true)
		elif get_meta("_visual_applied", false):
			enemy_target.pop_inferno_visual()
			set_meta("_visual_applied", false)

func _process(delta: float) -> void:
	if not is_instance_valid(enemy_target) or not is_instance_valid(tower_owner):
		_start_fade_out()
		return
	
	_time += delta
	
	# Continuous visual update
	var current_multiplier: float = 1.0
	var charging: bool = tower_owner.bullet_stats.get("is_charging", false)
	if charging:
		var seconds_locked: float = tower_owner.target_lock_time
		current_multiplier = pow(2.0, floor(minf(max_damage_multiplier, seconds_locked)))
	
	# Accumulate damage to optimize popups
	_damage_accumulator += float(damage) * current_multiplier * delta * (1.0 / tower_owner.fire_rate_timer.wait_time)
	if _damage_accumulator >= 0.1: # Reduced threshold for better responsiveness with the new popup system
		enemy_target.take_damage(_damage_accumulator, IEnemy.DamageType.DEFAULT, tower_owner)
		_damage_accumulator = 0.0
	
	_update_beam_visuals(current_multiplier)


func _update_beam_visuals(multiplier: float) -> void:
	var from_pos: Vector2 = Vector2.ZERO
	var to_pos: Vector2 = to_local(enemy_target.global_position)
	var distance: float = from_pos.distance_to(to_pos)
	var beam_direction: Vector2 = from_pos.direction_to(to_pos)
	var normal: Vector2 = Vector2(-beam_direction.y, beam_direction.x)
	
	# Create wave effect by segmenting the line
	var points: PackedVector2Array = PackedVector2Array()
	for i in range(SEGMENTS_COUNT + 1):
		var t: float = float(i) / SEGMENTS_COUNT
		var pos: Vector2 = from_pos.lerp(to_pos, t)
		
		# Add sinusoidal noise (wave)
		if i > 0 and i < SEGMENTS_COUNT:
			var wave: float = sin(_time * NOISE_SPEED + t * 10.0) * NOISE_AMPLITUDE
			pos += normal * wave
		
		points.append(pos)
	
	line_core.points = points
	line_glow.points = points
	line_inner.points = points
	
	# Visual intensity based on charge
	var intensity: float = (multiplier - 1.0) / (max_damage_multiplier - 1.0) if max_damage_multiplier > 1.0 else 0.0
	
	# Base size reduced, and about 20% size added per charge tier
	# multiplier is 1.0, 2.0, 4.0, 8.0...
	var step: float = log(multiplier) / log(2.0)
	var size_boost: float = 1.0 + step * 0.2
	line_core.width = BEAM_WIDTH_BASE * size_boost
	line_glow.width = line_core.width * 6.0
	line_inner.width = line_core.width * 0.3
	
	# Visual flash on scale up (when multiplier changes)
	var charging: bool = tower_owner.bullet_stats.get("is_charging", false)
	if charging and multiplier > 1.0:
		var last_multiplier: float = get_meta("_last_multiplier", 1.0)
		if multiplier > last_multiplier:
			_trigger_scale_flash()
		set_meta("_last_multiplier", multiplier)
	
	# Update particles
	fire_particles.global_position = enemy_target.global_position
	fire_particles.emitting = true
	fire_particles.amount = int(lerp(10, 30, intensity))
	fire_particles.scale_amount_min = lerp(1.0, 2.0, intensity)
	fire_particles.scale_amount_max = lerp(2.0, 4.0, intensity)
	
	# Update sparks along the beam
	spark_particles.emission_rect_extents = Vector2(distance / 2.0, 5.0)
	spark_particles.position = from_pos.lerp(to_pos, 0.5)
	spark_particles.rotation = beam_direction.angle()
	spark_particles.amount = int(lerp(20, 60, intensity))
	spark_particles.emitting = true
	
	# Update impact sparks on the zombie
	impact_sparks.global_position = enemy_target.global_position
	impact_sparks.emitting = true
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
	fade.finished.connect(queue_free)
