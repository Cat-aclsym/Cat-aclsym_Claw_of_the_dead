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

# Private variables
@onready var _label: Label = $Label

# Built-in functions
func _ready() -> void:
	# Ensure it's on top of everything
	z_index = 4096
	z_as_relative = false
	
	_label.text = str(round(amount))
	_label.modulate = color
	
	# Scale and position setup
	if is_critical:
		_label.modulate = Color.YELLOW
	
	# Initial position and setup
	position += Vector2(randf_range(-10, 10), randf_range(-10, 10))
	_label.scale = Vector2.ZERO
	
	# Reduced scale by 20% (0.8x and 1.2x instead of 1.0x and 1.5x)
	var base_scale = Vector2.ONE * (1.2 if is_critical else 0.8)
	var bounce_scale = base_scale * 1.5
	
	# Modern Animation Sequence (~1s total)
	var tween = create_tween()
	
	# 1. Zoom in with Bounce (0.2s)
	tween.tween_property(_label, "scale", bounce_scale, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	# 2. Zoom out to normal size (0.15s)
	tween.parallel().tween_property(_label, "scale", base_scale, 0.15).set_delay(0.2)
	
	# 3. Slight upward movement (parallel to the whole sequence)
	tween.parallel().tween_property(self, "position:y", position.y - 20, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	# 4. Fade out starting at 0.4s and ending at 0.7s (duration 0.3s)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.3).set_delay(0.4)
	
	# 5. Cleanup
	tween.tween_callback(queue_free)
