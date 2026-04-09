## © [2026] A7 Studio. All rights reserved. Trademark.

class_name InfernoBeam
extends IBullet
## Projectile de type rayon pour l'Inferno Tower.
## Gère les dégâts instantanés et l'effet visuel de rayon.

## Couleur de base du rayon (orange/rouge)
const BEAM_COLOR_BASE: Color = Color(1.0, 0.4, 0.1, 1.0)
## Couleur intense du rayon (jaune/blanc)
const BEAM_COLOR_INTENSE: Color = Color(1.0, 0.9, 0.5, 1.0)
## Largeur de base du rayon
const BEAM_WIDTH_BASE: float = 2.0
## Largeur maximale du rayon en charge
const BEAM_WIDTH_MAX: float = 6.0
## Durée de fondu quand le rayon s'arrête
const FADE_DURATION: float = 0.2

## Si vrai, les dégâts augmentent avec le temps
@export var is_charging: bool = false
## Vitesse d'augmentation des dégâts (multiplicateur par seconde)
@export var charge_speed: float = 0.5
## Multiplicateur maximum de dégâts
@export var max_damage_multiplier: float = 4.0

## Cible actuelle résolue par la tour
var enemy_target: IEnemy = null

@onready var line_core: Line2D = $LineCore
@onready var line_glow: Line2D = $LineGlow

func _ready() -> void:
	if not is_instance_valid(enemy_target) or not is_instance_valid(tower_owner):
		queue_free()
		return
	
	# Premier tir immédiat
	fire_tick()

func _process(_delta: float) -> void:
	if not is_instance_valid(enemy_target) or not is_instance_valid(tower_owner):
		_start_fade_out()
		return
	
	# Mise à jour visuelle continue de la position
	var current_multiplier: float = 1.0
	if is_charging:
		var seconds_locked = tower_owner.target_lock_time
		current_multiplier = pow(2.0, floor(minf(max_damage_multiplier, seconds_locked)))
	
	_update_beam_visuals(current_multiplier)

## Appelé par la tour à chaque cycle de fire_rate
func fire_tick() -> void:
	if not is_instance_valid(enemy_target) or not is_instance_valid(tower_owner):
		return

	var current_multiplier: float = 1.0
	# Utiliser directement la valeur de la tour pour être sûr
	var charging = tower_owner.bullet_stats.get("is_charging", false)
	if charging:
		var seconds_locked = tower_owner.target_lock_time
		current_multiplier = pow(2.0, floor(minf(max_damage_multiplier, seconds_locked)))

	var raw_damage: float = float(damage) * current_multiplier
	enemy_target.take_damage(raw_damage, IEnemy.DamageType.DEFAULT, tower_owner)

func _update_beam_visuals(multiplier: float) -> void:
	var from_pos: Vector2 = Vector2.ZERO # Local à l'objet
	var to_pos: Vector2 = to_local(enemy_target.global_position)
	
	var points: PackedVector2Array = PackedVector2Array([from_pos, to_pos])
	line_core.points = points
	line_glow.points = points
	
	# Intensité visuelle basée sur la charge
	var intensity = (multiplier - 1.0) / (max_damage_multiplier - 1.0) if max_damage_multiplier > 1.0 else 0.0
	line_core.width = lerp(BEAM_WIDTH_BASE, BEAM_WIDTH_MAX, intensity)
	line_glow.width = line_core.width * 2.5
	
	var current_color = BEAM_COLOR_BASE.lerp(BEAM_COLOR_INTENSE, intensity)
	line_core.default_color = current_color
	line_glow.default_color = current_color

func _start_fade_out() -> void:
	set_process(false) # Arrête la mise à jour de position
	var fade: Tween = create_tween().set_parallel(true)
	fade.tween_property(line_core, "modulate:a", 0.0, FADE_DURATION)
	fade.tween_property(line_glow, "modulate:a", 0.0, FADE_DURATION)
	fade.finished.connect(queue_free)
