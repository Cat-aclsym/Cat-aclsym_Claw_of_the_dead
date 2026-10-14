## © [2026] A7 Studio. All rights reserved. Trademark.
##
## A trap that explodes when an enemy walks on it, dealing area damage after a delay.
## Damage, range and delay come from [code]traps.bat_05.base[/code] in stats.json.
class_name Bat05
extends ITrap

## Seconds the explosion particles need to fade out after the blast, the trap stays alive for them.
const EXPLOSION_VFX_DURATION: float = 2.0

const FIRE_LIFETIME: float = 0.5
const FIRE_PARTICLES_AMOUNT: int = 80
const FIRE_Z_INDEX: int = 801
const SMOKE_LIFETIME: float = 1.5
const SMOKE_PARTICLES_AMOUNT: int = 60
const SMOKE_Z_INDEX: int = 800

## The amount of damage dealt by the explosion
@export var damage: int = 0

## Delay before explosion after trigger
@export var explosion_delay: float = 0.0

## The range of the explosion in pixels.
## Since tiles are 64x32, a range of 80-100 should cover adjacent tiles.
@export var explosion_range: float = 0.0

## Explosion materials shared by every bomb, one per explosion range.
static var _fire_materials: Dictionary[float, ParticleProcessMaterial] = {}
static var _smoke_materials: Dictionary[float, ParticleProcessMaterial] = {}


## Starts the explosion sequence when an enemy triggers the trap.
func apply_effect(_enemy: IEnemy) -> void:
	if is_usable:
		_start_explosion_sequence()


## Fire and smoke bursts that fill the blast circle, they free themselves.
func _create_explosion_effect(explosion_position: Vector2) -> void:
	VfxUtil.burst(get_tree().root, explosion_position, _get_fire_material(), null, FIRE_PARTICLES_AMOUNT, FIRE_LIFETIME, 1.0, 0.0, FIRE_Z_INDEX)
	VfxUtil.burst(get_tree().root, explosion_position, _get_smoke_material(), null, SMOKE_PARTICLES_AMOUNT, SMOKE_LIFETIME, 0.8, 0.0, SMOKE_Z_INDEX)


func _explode() -> void:
	_create_explosion_effect(global_position)

	for enemy: IEnemy in _enemies_within(explosion_range):
		enemy.take_damage(damage, IEnemy.DamageType.DEFAULT, self)

	# Visual/Audio effects
	if Global.camera:
		Global.camera.handle_effect("shake", 15.0)

	$Sprite2D.visible = false
	current_durability = 0
	is_usable = false
	# ITrap frees the trap once [method _get_post_trigger_lifetime] is over
	is_activating = false
	_refresh_opacity()


## Fire material, emitted over most of the blast circle. Shared by every explosion of the same range.
func _get_fire_material() -> ParticleProcessMaterial:
	if _fire_materials.has(explosion_range):
		return _fire_materials[explosion_range]

	var fire_material: ParticleProcessMaterial = ParticleProcessMaterial.new()
	fire_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	fire_material.emission_sphere_radius = explosion_range * 0.8
	fire_material.direction = Vector3(0, -1, 0)
	fire_material.spread = 45.0
	fire_material.gravity = Vector3(0, 0, 0)
	fire_material.initial_velocity_min = 40.0
	fire_material.initial_velocity_max = 80.0
	fire_material.scale_min = 2.0
	fire_material.scale_max = 4.0
	fire_material.color_ramp = VfxUtil.make_ramp({
		0.0: Color(1, 0.9, 0.2, 1.0), # Opaque yellow
		0.4: Color(1, 0.4, 0.0, 0.8), # Orange starts to fade
		1.0: Color(1, 0.4, 0.0, 0.0), # Fully transparent orange
	})

	_fire_materials[explosion_range] = fire_material
	return fire_material


## The trap outlives the delay before the blast and the explosion effects.
func _get_post_trigger_lifetime() -> float:
	return explosion_delay + EXPLOSION_VFX_DURATION


## Smoke material, emitted over the whole blast circle. Shared by every explosion of the same range.
func _get_smoke_material() -> ParticleProcessMaterial:
	if _smoke_materials.has(explosion_range):
		return _smoke_materials[explosion_range]

	var smoke_material: ParticleProcessMaterial = ParticleProcessMaterial.new()
	smoke_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	smoke_material.emission_sphere_radius = explosion_range
	smoke_material.direction = Vector3(0, -1, 0)
	smoke_material.spread = 45.0
	smoke_material.gravity = Vector3(0, -30.0, 0)
	smoke_material.initial_velocity_min = 15.0
	smoke_material.initial_velocity_max = 40.0
	smoke_material.scale_min = 4.0
	smoke_material.scale_max = 10.0
	smoke_material.color_ramp = VfxUtil.make_ramp({
		0.0: Color(0.3, 0.3, 0.3, 0.0), # Start transparent
		0.2: Color(0.4, 0.4, 0.4, 0.5), # Fade in
		1.0: Color(0.6, 0.6, 0.6, 0.0), # Fade out end
	})

	_smoke_materials[explosion_range] = smoke_material
	return smoke_material


func _on_explosion_delay_over(blink_tween: Tween, circle: Polygon2D) -> void:
	blink_tween.kill()
	circle.queue_free()
	# The level end pauses the gameplay without pausing the tree: a bomb still ticking then must not explode
	if Global.paused:
		return
	_explode()


func _start_explosion_sequence() -> void:
	is_usable = false
	is_activating = true

	# Transparent red/orange alert circle
	var circle: Polygon2D = _spawn_range_circle(explosion_range, Color(1.0, 0.2, 0.1, 0.3))

	# Blink until the explosion
	var blink_tween: Tween = create_tween()
	var loops: int = int(explosion_delay / 0.3) # 0.3s per loop (0.15 + 0.15)
	blink_tween.set_loops(loops)
	blink_tween.tween_property(circle, "modulate:a", 0.8, 0.15)
	blink_tween.tween_property(circle, "modulate:a", 0.3, 0.15)

	# Wait for the delay
	var delay_tween: Tween = create_tween()
	delay_tween.tween_interval(explosion_delay)
	delay_tween.tween_callback(_on_explosion_delay_over.bind(blink_tween, circle))
