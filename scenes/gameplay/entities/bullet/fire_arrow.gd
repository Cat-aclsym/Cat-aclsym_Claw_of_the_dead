## © [2024] A7 Studio. All rights reserved. Trademark.

class_name FireArrow
extends AOEArrow
## Fire arrow bullet that creates a burning area on impact.
##
## The fire zone persists and deals damage over time to enemies
## within its radius. It creates visual fire effects and applies
## burn damage ticks to all enemies staying in the area.

# Constants
const BURN_DAMAGE_MULTIPLIER: float = 0.5  # Burn damage is 50% of direct hit damage
const BURN_TICK_TIME: float = 1.0  # Time between burn damage ticks
const BASE_BURN_DAMAGE: int = 5  # Base damage per tick
const DEFAULT_AOE_RANGE: int = 80  # Reference size to calculate proportions

# Exports
@export var burn_duration: float = 5.0  # Duration of the burning area effect
@export var burn_damage_base: int = 5  # Base damage per tick
## Parameter explanation:
## - burn_duration: Duration in seconds for which the fire area persists
## - burn_damage_base: Base damage per tick (1 tick per second)
## - aoe_range: Size of the fire area radius (in pixels)
##   Note: Size affects damage and number of particles

# Variables
var _is_burning: bool = false
var _burn_time_remaining: float = 0.0
var _burn_tick_timer: float = 0.0
var _burning_enemies: Array[IEnemy] = []
var _area_size_ratio: float = 1.0  # Ratio calculated relative to standard size

@onready var burn_area_sprite: Sprite2D = $BurnAreaSprite
@onready var burn_area_circle: Polygon2D = $BurnAreaCircle
@onready var arrow_sprite: Sprite2D = $Sprite2D
@onready var burn_particles: GPUParticles2D = $BurnParticles
@onready var burn_area: Area2D = $BurnArea
@onready var burn_area_collision: CollisionShape2D = $BurnArea/CollisionShape2D

# Signals
@onready var burn_signals: Array[Dictionary] = [
	{SignalUtil.WHO: burn_area, SignalUtil.WHAT: "body_entered", SignalUtil.TO: _on_burn_area_body_entered},
	{SignalUtil.WHO: burn_area, SignalUtil.WHAT: "body_exited", SignalUtil.TO: _on_burn_area_body_exited}
]

#region Built-in functions
# Override _ready to initialize burning area
func _ready() -> void:
	super._ready()
	
	# Calculate size ratio compared to standard size
	_area_size_ratio = float(aoe_range) / DEFAULT_AOE_RANGE
	
	# Set up burn area
	if burn_area_collision.shape is CircleShape2D:
		burn_area_collision.shape.radius = aoe_range
	
	# Initially hide burn visuals
	burn_area_sprite.visible = false
	burn_area_circle.visible = false
	burn_particles.emitting = false
	
	# Adjust scale for burn area size
	_adjust_burn_area_size()
	
	# Initially set scale to zero for grow animation
	burn_area_circle.scale = Vector2.ZERO
	
	SignalUtil.connects(burn_signals)

# Override physics process to handle burning effect
func _physics_process(delta: float) -> void:
	if Global.paused:
		return
	
	if _is_burning:
		_process_burning_area(delta)
	else:
		# Normal arrow movement
		super._physics_process(delta)
#endregion

#region Signal handlers
# Override the body entered function to create burning area on impact
func _on_body_entered(body: Node2D) -> void:
	if not body is IEnemy or _touched_enemy != null or _is_burning:
		return

	_touched_enemy = body as IEnemy
	var enemy := body as IEnemy
	
	# Apply direct hit damage
	enemy.take_damage(damage, IEnemy.DamageType.DEFAULT)
	
	# Apply AOE damage to nearby enemies
	if len(aoe_enemies) > 0:
		for nearby_enemy in aoe_enemies:
			if nearby_enemy != enemy and is_instance_valid(nearby_enemy):
				var aoe_damage = roundi(damage * AOE_DAMAGE_MULTIPLIER)
				nearby_enemy.take_damage(aoe_damage, IEnemy.DamageType.DEFAULT)
	
	# Activate burning area instead of destroying
	_activate_burning_area()

# Called when an enemy enters the burn area
func _on_burn_area_body_entered(body: Node2D) -> void:
	if body is IEnemy and not _burning_enemies.has(body):
		_burning_enemies.append(body)

# Called when an enemy exits the burn area
func _on_burn_area_body_exited(body: Node2D) -> void:
	if body is IEnemy:
		_burning_enemies.erase(body)
#endregion

#region Private functions
# Process burning area effect
func _process_burning_area(delta: float) -> void:
	_burn_time_remaining -= delta
	
	if _burn_time_remaining <= 0:
		# Time's up, start fade out instead of immediately removing
		_start_fade_out()
		return
	
	# Start fade out animation when less than 1 second remains
	if _burn_time_remaining < 1.0 and burn_area_circle.modulate.a == 1.0:
		_start_partial_fade()
	
	# Process burn damage ticks
	_burn_tick_timer -= delta
	if _burn_tick_timer <= 0:
		_apply_burn_damage()
		_burn_tick_timer = BURN_TICK_TIME

# Apply burn damage to all enemies in the area
func _apply_burn_damage() -> void:
	# Clean up invalid references
	_burning_enemies = _burning_enemies.filter(func(enemy): return is_instance_valid(enemy))
	
	# Apply burn damage to all enemies in burn area
	for enemy in _burning_enemies:
		if is_instance_valid(enemy):
			var burn_damage = burn_damage_base + roundi(damage * BURN_DAMAGE_MULTIPLIER)
			enemy.take_damage(burn_damage, IEnemy.DamageType.FIRE)

# Activate the burning area effect
func _activate_burning_area() -> void:
	_is_burning = true
	_burn_time_remaining = burn_duration
	_burn_tick_timer = BURN_TICK_TIME
	
	# Show burn area visuals and hide arrow sprite
	arrow_sprite.visible = false
	burn_area_circle.visible = true
	
	# Make sure opacity is at full
	burn_area_circle.modulate.a = 1.0
	burn_particles.modulate.a = 1.0

	# Set rotation
	burn_area_circle.rotation = deg_to_rad(32.5)
	rotation = deg_to_rad(0)
	
	# Start grow animation
	_start_grow_animation()
	
	# Stop movement
	direction = Vector2.ZERO
	speed = 0 

# Animation to grow the burn area when activated
func _start_grow_animation() -> void:
	# Start with a small scale
	burn_area_circle.scale = Vector2(0.1, 0.1) * _area_size_ratio
	
	# Create a tween for smooth, realistic growth - but fast
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	
	# Final target with size multiplier
	var target_scale = Vector2(1.0, 1.0) * _area_size_ratio
	var overshoot_scale = Vector2(1.05, 1.05) * _area_size_ratio
	
	# Very fast growth at the beginning
	tween.tween_property(burn_area_circle, "scale", overshoot_scale, 0.18)
	tween.tween_property(burn_area_circle, "scale", target_scale, 0.12)
	
	# Adjust opacity normally but with a more visible start
	burn_area_circle.modulate.a = 0.5
	var opacity_tween = create_tween()
	opacity_tween.tween_property(burn_area_circle, "modulate:a", 1.0, 0.35)
	
	# Start particles quickly
	burn_particles.amount = 25
	burn_particles.emitting = true
	
	# Increase number of particles
	var particle_tween = create_tween()
	particle_tween.tween_property(burn_particles, "amount", 30, 0.35)
	
	# Heat effect with slight pulsation - kept as before
	await get_tree().create_timer(0.18).timeout
	_add_heat_pulse()

# Adds a slight pulsation effect to simulate fire heat
func _add_heat_pulse() -> void:
	# Don't create the effect if the fire is already fading
	if _burn_time_remaining <= 1.0:
		return
		
	# Creates a subtle pulsation effect
	var pulse_tween = create_tween()
	pulse_tween.set_loops() # Continuous loop
	pulse_tween.set_trans(Tween.TRANS_SINE)
	
	# Base scale with size factor
	var base_scale = Vector2(1.0, 1.0) * _area_size_ratio
	
	# Slight faster pulsation
	pulse_tween.tween_property(burn_area_circle, "scale", base_scale * 1.02, 1.0)
	pulse_tween.tween_property(burn_area_circle, "scale", base_scale * 0.98, 1.0)
	
	# Stop pulsation when time is almost up
	await get_tree().create_timer(_burn_time_remaining - 1.0).timeout
	pulse_tween.kill()
	
	# Return to normal scale
	var reset_tween = create_tween()
	reset_tween.tween_property(burn_area_circle, "scale", base_scale, 0.2)

# Start a partial fade when approaching the end of duration
func _start_partial_fade() -> void:
	# Create a subtle fade to indicate the effect is about to end
	var tween = create_tween()
	tween.tween_property(burn_area_circle, "modulate:a", 0.7, 0.3)
	tween.parallel().tween_property(burn_particles, "modulate:a", 0.7, 0.3)
	tween.tween_property(burn_area_circle, "modulate:a", 1.0, 0.3)
	tween.parallel().tween_property(burn_particles, "modulate:a", 1.0, 0.3)

# Start the fade out animation when the effect is completely over
func _start_fade_out() -> void:
	# Disable the burn collision to stop dealing damage
	burn_area_collision.set_deferred("disabled", true)
	
	# Base scale with size factor
	var base_scale = Vector2(1.0, 1.0) * _area_size_ratio
	
	# Create a tween for smooth fade out
	var tween = create_tween()
	tween.tween_property(burn_area_circle, "modulate:a", 0, 0.8)
	tween.parallel().tween_property(burn_particles, "modulate:a", 0, 0.8)
	
	# Slightly reduce size during fade out
	var scale_tween = create_tween()
	scale_tween.tween_property(burn_area_circle, "scale", base_scale * 0.9, 0.8)
	
	# Once the tween completes, free the object
	await tween.finished
	queue_free()

# Adjusts all properties related to fire area size
func _adjust_burn_area_size() -> void:
	# Calculate scale ratio for Polygon2D
	# We adapt the Polygon2D scale because its geometry is defined for a size of 80
	var visual_scale = _area_size_ratio
	burn_area_circle.scale = Vector2(visual_scale, visual_scale)
	
	# Adjust particle system
	burn_particles.process_material.emission_sphere_radius = 50 * _area_size_ratio
	
	# Adjust particle amount based on area (which increases with square)
	var particle_amount = round(30 * _area_size_ratio * _area_size_ratio)
	burn_particles.amount = int(clamp(particle_amount, 10, 100))
	
	# Adjust damage strength proportionally to size
	burn_damage_base = int(BASE_BURN_DAMAGE * _area_size_ratio)
#endregion
