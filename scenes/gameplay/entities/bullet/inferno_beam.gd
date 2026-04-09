## © [2026] A7 Studio. All rights reserved. Trademark.

class_name InfernoBeam
extends IBullet
## Projectile de type rayon pour l'Inferno Tower.
## Gère les dégâts instantanés et l'effet visuel de rayon amélioré.

## Couleurs pour le gradient (jaune -> orange -> rouge)
const COLOR_YELLOW: Color = Color(1.0, 0.9, 0.3, 1.0)
const COLOR_ORANGE: Color = Color(1.0, 0.5, 0.1, 1.0)
const COLOR_RED: Color = Color(0.9, 0.1, 0.1, 1.0)

## Largeurs de base
const BEAM_WIDTH_BASE: float = 1.5
const BEAM_WIDTH_MAX: float = 4.0
const FADE_DURATION: float = 0.5

## Paramètres de l'effet de vague
const NOISE_SPEED: float = 10.0
const NOISE_AMPLITUDE: float = 1.8
const SEGMENTS_COUNT: int = 16

## Si vrai, les dégâts augmentent avec le temps
@export var is_charging: bool = false
## Vitesse d'augmentation des dégâts (multiplicateur par seconde)
@export var charge_speed: float = 0.5
## Multiplicateur maximum de dégâts
@export var max_damage_multiplier: float = 4.0

## Cible actuelle résolue par la tour
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
	if not is_instance_valid(enemy_target) or not is_instance_valid(tower_owner):
		queue_free()
		return
	
	# Configurer les gradients
	var gradient_glow = Gradient.new()
	gradient_glow.set_color(0, Color(1.0, 0.3, 0.0, 0.0)) # Départ transparent
	gradient_glow.add_point(0.2, Color(1.0, 0.4, 0.1, 0.4))
	gradient_glow.add_point(0.8, Color(1.0, 0.5, 0.2, 0.4))
	gradient_glow.set_color(1, Color(1.0, 0.6, 0.3, 0.0)) # Fin transparente
	line_glow.gradient = gradient_glow
	
	var gradient_core = Gradient.new()
	gradient_core.set_color(0, COLOR_RED)
	gradient_core.add_point(0.5, COLOR_ORANGE)
	gradient_core.set_color(1, COLOR_YELLOW)
	line_core.gradient = gradient_core
	
	var gradient_inner = Gradient.new()
	gradient_inner.set_color(0, Color(1.0, 1.0, 0.8, 1.0)) # Blanc cassé
	gradient_inner.add_point(0.5, Color.WHITE)
	gradient_inner.set_color(1, Color(1.0, 1.0, 0.8, 1.0))
	line_inner.gradient = gradient_inner
	
	# Configurer les étincelles
	if is_instance_valid(spark_particles):
		spark_particles.emitting = true
	
	# Initialiser l'opacité à 0 pour le fade in
	modulate.a = 0.0
	var fade_in = create_tween()
	fade_in.tween_property(self, "modulate:a", 1.0, FADE_DURATION)
	
	# Premier tir immédiat
	fire_tick()

func _process(delta: float) -> void:
	if not is_instance_valid(enemy_target) or not is_instance_valid(tower_owner):
		_start_fade_out()
		return
	
	_time += delta
	
	# Mise à jour visuelle continue
	var current_multiplier: float = 1.0
	var charging = tower_owner.bullet_stats.get("is_charging", false)
	if charging:
		var seconds_locked = tower_owner.target_lock_time
		current_multiplier = pow(2.0, floor(minf(max_damage_multiplier, seconds_locked)))
	
	# Accumulation des dégâts pour optimiser les popups
	_damage_accumulator += float(damage) * current_multiplier * delta * (1.0 / tower_owner.fire_rate_timer.wait_time)
	if _damage_accumulator >= 0.1: # Seuil réduit pour plus de réactivité avec le nouveau système de popup
		enemy_target.take_damage(_damage_accumulator, IEnemy.DamageType.DEFAULT, tower_owner)
		_damage_accumulator = 0.0
	
	_update_beam_visuals(current_multiplier)

## Appelé par la tour à chaque cycle de fire_rate
func fire_tick() -> void:
	# On ne fait plus rien ici pour l'InfernoBeam car on gère les dégâts dans _process
	# pour une accumulation fluide et moins de popups.
	pass

func _update_beam_visuals(multiplier: float) -> void:
	var from_pos: Vector2 = Vector2.ZERO
	var to_pos: Vector2 = to_local(enemy_target.global_position)
	var distance = from_pos.distance_to(to_pos)
	var direction = from_pos.direction_to(to_pos)
	var normal = Vector2(-direction.y, direction.x)
	
	# Créer l'effet de vague en segmentant la ligne
	var points: PackedVector2Array = PackedVector2Array()
	for i in range(SEGMENTS_COUNT + 1):
		var t = float(i) / SEGMENTS_COUNT
		var pos = from_pos.lerp(to_pos, t)
		
		# Ajouter du bruit sinusoïdal (vague)
		if i > 0 and i < SEGMENTS_COUNT:
			var wave = sin(_time * NOISE_SPEED + t * 10.0) * NOISE_AMPLITUDE
			pos += normal * wave
		
		points.append(pos)
	
	line_core.points = points
	line_glow.points = points
	line_inner.points = points
	
	# Intensité visuelle basée sur la charge
	var intensity = (multiplier - 1.0) / (max_damage_multiplier - 1.0) if max_damage_multiplier > 1.0 else 0.0
	
	# Taille de base réduite, et on ajoute environ 20% de la taille par palier de charge
	# multiplier est 1.0, 2.0, 4.0, 8.0...
	var step = log(multiplier) / log(2.0)
	var size_boost = 1.0 + step * 0.2
	line_core.width = BEAM_WIDTH_BASE * size_boost
	line_glow.width = line_core.width * 6.0
	line_inner.width = line_core.width * 0.3
	
	# Flash visuel lors du scale up (quand le multiplicateur change)
	var charging = tower_owner.bullet_stats.get("is_charging", false)
	if charging and multiplier > 1.0:
		var last_multiplier = get_meta("_last_multiplier", 1.0)
		if multiplier > last_multiplier:
			_trigger_scale_flash()
		set_meta("_last_multiplier", multiplier)
	
	# Mettre à jour les particules
	if is_instance_valid(fire_particles):
		fire_particles.global_position = enemy_target.global_position
		fire_particles.emitting = true
		fire_particles.amount = int(lerp(10, 30, intensity))
		fire_particles.scale_amount_min = lerp(1.0, 2.0, intensity)
		fire_particles.scale_amount_max = lerp(2.0, 4.0, intensity)
	
	# Mettre à jour les étincelles le long du rayon
	if is_instance_valid(spark_particles):
		spark_particles.emission_rect_extents = Vector2(distance / 2.0, 5.0)
		spark_particles.position = from_pos.lerp(to_pos, 0.5)
		spark_particles.rotation = direction.angle()
		spark_particles.amount = int(lerp(20, 60, intensity))
		spark_particles.emitting = true
	
	# Mettre à jour les étincelles d'impact sur le zombie
	if is_instance_valid(impact_sparks):
		impact_sparks.global_position = enemy_target.global_position
		impact_sparks.emitting = true
		impact_sparks.amount = int(lerp(15, 40, intensity))

func _trigger_scale_flash() -> void:
	var flash_tween = create_tween()
	# On utilise modulate pour le flash car default_color est géré par le gradient
	flash_tween.tween_property(line_core, "modulate", Color(2.0, 2.0, 2.0, 1.0), 0.05)
	flash_tween.tween_property(line_core, "modulate", Color.WHITE, 0.15)
	
	var original_glow = line_glow.width
	flash_tween.parallel().tween_property(line_glow, "width", original_glow * 3.0, 0.05)
	flash_tween.tween_property(line_glow, "width", original_glow, 0.15)

func _start_fade_out() -> void:
	set_process(false)
	if is_instance_valid(fire_particles):
		fire_particles.emitting = false
	if is_instance_valid(spark_particles):
		spark_particles.emitting = false
	if is_instance_valid(impact_sparks):
		impact_sparks.emitting = false
		
	var fade: Tween = create_tween()
	fade.tween_property(self, "modulate:a", 0.0, FADE_DURATION)
	fade.finished.connect(queue_free)
