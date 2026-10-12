## © [2026] A7 Studio. All rights reserved. Trademark.
##
## Piercing arrow bullet that can pass through multiple enemies.
class_name PiercingArrow
extends IBullet

# constants
const SPARK_TEXTURE_SIZE: int = 6
const SPARK_Z_INDEX: int = 500 # Lower than blood effect but above enemies

# exports
@export var pierce_count: int = 3  ## Number of enemies the bullet can pierce
@export_range(0, 100) var pierce_reduction: int = 10  ## Percentage of damage reduction per enemy pierced

@export_group("Pierce Effects")
@export var spark_effect_enabled: bool = true ## Enable spark effect for pierced enemies
@export var spark_particles_color: Color = Color(1.0, 1.0, 0.7, 0.9) ## Color of sparks (yellow-white)
@export var spark_particles_count: int = 8 ## Number of spark particles
@export var spark_particles_lifetime: float = 0.3 ## Lifetime of sparks
@export var spark_particles_size: float = 1.5 ## Size of sparks
@export var spark_particles_speed: float = 80.0 ## Speed of sparks

# public
var pierced_enemies: Array[IEnemy] = []  # Enemies already pierced

# private
## Spark materials shared by every effect, one per speed, size and color combination of the scene exports.
static var _spark_materials: Dictionary[String, ParticleProcessMaterial] = {}
## Spark texture shared by every effect.
static var _spark_texture: Texture2D = null

# private
func _create_spark_effect(hit_position: Vector2) -> void:
	VfxUtil.burst(
		get_tree().root,
		hit_position,
		_get_spark_material(),
		_get_spark_texture(),
		spark_particles_count,
		spark_particles_lifetime,
		0.9, # Fast emission
		0.4,
		SPARK_Z_INDEX
	)


static func _draw_spark_line(image: Image, from: Vector2, to: Vector2, color: Color) -> void:
	# Simple line algorithm for sparks
	var dx: int = roundi(absf(to.x - from.x))
	var dy: int = -roundi(absf(to.y - from.y))
	var sx: int = 1 if from.x < to.x else -1
	var sy: int = 1 if from.y < to.y else -1
	var err: int = dx + dy

	var x: int = int(from.x)
	var y: int = int(from.y)

	while true:
		if x >= 0 and y >= 0 and x < image.get_width() and y < image.get_height():
			image.set_pixel(x, y, color)

		if x == to.x and y == to.y:
			break

		var e2: int = 2 * err
		if e2 >= dy:
			if x == to.x:
				break
			err += dy
			x += sx

		if e2 <= dx:
			if y == to.y:
				break
			err += dx
			y += sy


## Light-gravity material that fades the sparks out, shared by every effect with the same exports.
func _get_spark_material() -> ParticleProcessMaterial:
	var key: String = "%s|%s|%s" % [spark_particles_speed, spark_particles_size, spark_particles_color]
	if _spark_materials.has(key):
		return _spark_materials[key]

	var particle_material: ParticleProcessMaterial = ParticleProcessMaterial.new()
	particle_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_POINT
	particle_material.direction = Vector3(0, 0, 1)
	particle_material.spread = 120.0 # Narrower than blood effect
	particle_material.gravity = Vector3(0, 50.0, 0) # Light gravity
	particle_material.initial_velocity_min = spark_particles_speed * 0.7
	particle_material.initial_velocity_max = spark_particles_speed
	particle_material.scale_min = spark_particles_size * 0.8
	particle_material.scale_max = spark_particles_size
	particle_material.color = spark_particles_color
	particle_material.damping_min = 30.0
	particle_material.damping_max = 60.0

	var mid_color: Color = spark_particles_color
	mid_color.a *= 0.6
	var fade_color: Color = spark_particles_color
	fade_color.a = 0.0
	particle_material.color_ramp = VfxUtil.make_ramp({0.0: spark_particles_color, 0.4: mid_color, 1.0: fade_color})

	_spark_materials[key] = particle_material
	return particle_material


## Small 4-pointed star, built once and shared by every effect.
static func _get_spark_texture() -> Texture2D:
	if _spark_texture == null:
		var image: Image = Image.create(SPARK_TEXTURE_SIZE, SPARK_TEXTURE_SIZE, false, Image.FORMAT_RGBA8)

		# Fill with transparency
		image.fill(Color(0, 0, 0, 0))

		# Center of the image
		var center: Vector2 = Vector2(SPARK_TEXTURE_SIZE / 2., SPARK_TEXTURE_SIZE / 2.)

		# Draw a small 4-pointed star
		var points: PackedVector2Array = PackedVector2Array([
			Vector2(0, center.y),           # Left
			Vector2(SPARK_TEXTURE_SIZE - 1, center.y), # Right
			Vector2(center.x, 0),           # Top
			Vector2(center.x, SPARK_TEXTURE_SIZE - 1)   # Bottom
		])

		# Draw the star lines
		for point in points:
			_draw_spark_line(image, center, point, Color(1, 1, 1, 1))

		# Add a brighter central point
		image.set_pixel(int(center.x), int(center.y), Color(1, 1, 1, 1))

		_spark_texture = ImageTexture.create_from_image(image)
	return _spark_texture


func _on_body_entered(body: Node2D) -> void:
	if not body is IEnemy:
		return

	if pierced_enemies.has(body):
		return  # Avoid hitting the same enemy twice

	var enemy := body as IEnemy
	pierced_enemies.append(enemy)

	# Apply damage
	enemy.take_damage(damage, IEnemy.DamageType.DEFAULT, self)

	# Calculate damage reduction, it never goes below zero
	var remaining_damage_percent: float = maxf(0.0, 100.0 - pierce_reduction * pierced_enemies.size())
	damage = roundi(initial_damage * (remaining_damage_percent / 100.0))

	# Create appropriate effect depending on whether it's the last enemy or not
	if pierced_enemies.size() >= pierce_count:
		# Destroy the arrow
		queue_free()
	else:
		# Pierced enemy: spark effect
		if spark_effect_enabled:
			_create_spark_effect(global_position)
