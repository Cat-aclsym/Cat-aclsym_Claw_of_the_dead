## © [2026] A7 Studio. All rights reserved. Trademark.

class_name LowHealthIndicator
extends ColorRect
## Handles the visual feedback when player health is critically low.
##
## Displays a pulsing, pixelated red vignette around the screen edges.

# Constants
const CRITICAL_HEALTH_THRESHOLD: float = 0.25
const FADE_DURATION: float = 0.5

# Variables
@onready var _is_active: bool = false
var _intensity_tween: Tween

# Built-in functions
func _ready() -> void:
	assert(material != null, "LowHealthIndicator: material is missing")
	# Ensure it covers the whole screen
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Initial state: hidden/transparent
	material.set_shader_parameter("intensity", 0.0)
	hide()


# Public functions
## Updates the indicator based on current health ratio.
## [param health_ratio] The current health as a value between 0.0 and 1.0.
func update_health(health_ratio: float) -> void:
	var should_be_active: bool = health_ratio <= CRITICAL_HEALTH_THRESHOLD
	
	if should_be_active != _is_active:
		_toggle_effect(should_be_active)


# Private functions
func _toggle_effect(active: bool) -> void:
	_is_active = active
	
	if _intensity_tween:
		_intensity_tween.kill()
	
	_intensity_tween = create_tween()
	
	if active:
		show()
		_intensity_tween.tween_property(material, "shader_parameter/intensity", 1.0, FADE_DURATION)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	else:
		_intensity_tween.tween_property(material, "shader_parameter/intensity", 0.0, FADE_DURATION)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		_intensity_tween.finished.connect(hide)
