## © [2026] A7 Studio. All rights reserved. Trademark.
##
## Manages the visual behavior of a damage number popup.
## Handles animation through code for a "modern" and physics-like feel.
class_name DamagePopup
extends Node2D

# Public variables
var amount: float = 0.0
var color: Color = Color.WHITE
var is_critical: bool = false
var target_node: Node2D = null # Le nœud à suivre (uniquement si accumulatif)
var is_accumulative: bool = false # Si vrai, suit le zombie et permet l'accumulation

# Private variables
@onready var _label: Label = $Label
var _is_rainbow: bool = false
var _hue: float = 0.0
var _tween: Tween
var _relative_offset: Vector2 = Vector2.ZERO # L'offset d'animation local

# Built-in functions
func _ready() -> void:
	# Ensure it's on top of everything
	z_index = 4096
	z_as_relative = false
	
	_update_visuals()
	
	# Rainbow effect trigger
	if amount == 67:
		_is_rainbow = true
	
	# Initial relative offset setup
	_relative_offset = Vector2(randf_range(-10, 10), randf_range(-15, -10))
	
	# Initial position update
	if is_instance_valid(target_node) and is_accumulative:
		global_position = target_node.global_position + _relative_offset
	
	_start_animation()

func update_value(additional_amount: float) -> void:
	if not is_accumulative:
		return
	amount += additional_amount
	_update_visuals()
	_trigger_bounce()

func _update_visuals() -> void:
	var rounded_amount = amount
	if rounded_amount >= 1.0:
		_label.text = "%.1f" % rounded_amount if fmod(rounded_amount, 1.0) != 0 else str(int(rounded_amount))
	elif rounded_amount > 0.0:
		_label.text = "%.1f" % rounded_amount
	else:
		_label.text = "0"
	
	if is_critical and not _is_rainbow:
		_label.modulate = Color.YELLOW
	else:
		_label.modulate = color

func _start_animation() -> void:
	if _tween:
		_tween.kill()
	
	_label.scale = Vector2.ZERO
	_tween = create_tween()
	
	# Taille rétablie (0.8x et 1.2x)
	var base_scale = Vector2.ONE * (1.2 if is_critical else 0.8)
	var bounce_scale = base_scale * 1.5
	
	# 1. Zoom in with Bounce (0.2s)
	_tween.tween_property(_label, "scale", bounce_scale, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	# 2. Zoom out to normal size (0.15s)
	_tween.parallel().tween_property(_label, "scale", base_scale, 0.15).set_delay(0.2)
	
	# 3. Slight upward movement of the RELATIVE offset (0.7s)
	if is_accumulative:
		_tween.parallel().tween_property(self, "_relative_offset:y", _relative_offset.y - 10, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	else:
		_tween.parallel().tween_property(self, "position:y", position.y - 20, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	# 4. Fade out (0.3s)
	_tween.parallel().tween_property(self, "modulate:a", 0.0, 0.3).set_delay(0.4)
	
	# 5. Cleanup
	_tween.tween_callback(queue_free)

func _trigger_bounce() -> void:
	if not is_accumulative:
		return
		
	# Reset fade and duration
	modulate.a = 1.0
	
	if _tween:
		_tween.kill()
	
	_tween = create_tween()
	var base_scale = Vector2.ONE * (1.2 if is_critical else 0.8)
	var bounce_scale = base_scale * 1.1 # Réduit de 1.4 à 1.1 pour un effet plus discret
	
	# Effect de bounce rapide
	_tween.tween_property(_label, "scale", bounce_scale, 0.05).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tween.tween_property(_label, "scale", base_scale, 0.05).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	
	# On ne relance PAS le mouvement vers le haut (position:y) pour éviter que ça s'envole
	# On gère juste le fade out
	_tween.parallel().tween_property(self, "modulate:a", 0.0, 0.3).set_delay(0.5)
	
	_tween.tween_callback(queue_free)

func _process(delta: float) -> void:
	# Suivre le zombie en temps réel (uniquement si accumulatif)
	if is_accumulative and is_instance_valid(target_node):
		global_position = target_node.global_position + _relative_offset
	
	if _is_rainbow:
		_hue = fmod(_hue + delta * 2.0, 1.0)
		_label.modulate = Color.from_hsv(_hue, 0.8, 1.0)
