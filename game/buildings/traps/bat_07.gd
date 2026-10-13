## © [2026] A7 Studio. All rights reserved. Trademark.
##
## A trap that stuns all enemies in range after a charge-up.
## Charge time, stun duration and range come from [code]traps.bat_07.base[/code] in stats.json.
class_name Bat07
extends ITrap

const STUN_CENTER_PARTICLES_AMOUNT: int = 30
const STUN_PARTICLES_AMOUNT: int = 15
const STUN_PARTICLES_LIFETIME: float = 0.5
const STUN_Z_INDEX: int = 801

## Charge-up time before activation.
@export var charge_time: float = 0.0

## Duration of the stun effect in seconds.
@export var stun_duration: float = 0.0

## Range of the stun effect in pixels.
@export var stun_range: float = 0.0

## Stun materials shared by every trap, keyed by "is the center of the stun area".
static var _stun_materials: Dictionary[bool, ParticleProcessMaterial] = {}


## Starts the charge-up sequence when an enemy triggers the trap.
func apply_effect(_enemy: IEnemy) -> void:
	if is_usable:
		_start_activation_sequence()


## Yellow spark burst, bigger at the center of the stun area, it frees itself.
func _create_stun_visual_effect(pos: Vector2, is_center: bool = true) -> void:
	var amount: int = STUN_CENTER_PARTICLES_AMOUNT if is_center else STUN_PARTICLES_AMOUNT
	VfxUtil.burst(get_tree().root, pos, _get_stun_material(is_center), null, amount, STUN_PARTICLES_LIFETIME, 1.0, 0.0, STUN_Z_INDEX)


func _fade_out(circle: Polygon2D) -> void:
	var fade_tween: Tween = create_tween()
	fade_tween.set_parallel(true)
	fade_tween.tween_property(circle, "modulate:a", 0.0, 0.8) # Fade out plus long
	fade_tween.tween_property(self, "modulate:a", 0.0, 0.8)
	fade_tween.chain().tween_callback(_finish_sequence)


func _finish_sequence() -> void:
	is_activating = false
	queue_free()


## Spark material shared by every stun burst, one for the center and one for the surrounding tiles.
func _get_stun_material(is_center: bool) -> ParticleProcessMaterial:
	if _stun_materials.has(is_center):
		return _stun_materials[is_center]

	var material: ParticleProcessMaterial = ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = 10.0 if is_center else 5.0
	material.direction = Vector3(0, -1, 0)
	material.spread = 180.0
	material.gravity = Vector3(0, 0, 0)
	material.initial_velocity_min = 30.0
	material.initial_velocity_max = 60.0
	material.scale_min = 2.0
	material.scale_max = 4.0
	material.color_ramp = VfxUtil.make_ramp({0.0: Color(1.0, 1.0, 0.0, 1.0), 1.0: Color(1.0, 1.0, 0.0, 0.0)})

	_stun_materials[is_center] = material
	return material


## Triggers the stun once the circle is full, then keeps the trap for the stun duration before it fades away.
func _on_charge_complete(circle: Polygon2D) -> void:
	# The level end pauses the gameplay without pausing the tree: the stun must not trigger after it
	if Global.paused:
		return
	circle.color.a = 0.6 # Raise the opacity on activation (full visual)
	_trigger_stun()

	# The circle and the trap stay for the stun duration, then fade out together
	var cleanup_tween: Tween = create_tween()
	cleanup_tween.tween_interval(stun_duration)
	cleanup_tween.tween_callback(_fade_out.bind(circle))


func _start_activation_sequence() -> void:
	is_usable = false # Prevent multiple triggers
	is_activating = true # Tell ITrap to wait

	# Faint yellow charge circle, it grows from nothing to the stun range
	var circle: Polygon2D = _spawn_range_circle(stun_range, Color(1.0, 1.0, 0.0, 0.2))
	circle.scale = Vector2.ZERO
	var tween: Tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_QUAD)

	# The circle grows during the whole charge
	tween.tween_property(circle, "scale", Vector2.ONE, charge_time)

	# Once it is full, the stun triggers
	tween.tween_callback(_on_charge_complete.bind(circle))


func _trigger_stun() -> void:
	_create_stun_visual_effect(global_position, true)

	var adjacent_offsets: Array[Vector2] = [
		Vector2(64, 0), Vector2(-64, 0),
		Vector2(0, 32), Vector2(0, -32),
		Vector2(32, 16), Vector2(-32, 16),
		Vector2(32, -16), Vector2(-32, -16)
	]

	for offset: Vector2 in adjacent_offsets:
		_create_stun_visual_effect(global_position + offset, false)

	for enemy: IEnemy in _enemies_within(stun_range):
		enemy.stun(stun_duration)

	current_durability = 0
	# The stun is over but is_activating stays true until the final cleanup, ITrap would delete the trap too early otherwise.
