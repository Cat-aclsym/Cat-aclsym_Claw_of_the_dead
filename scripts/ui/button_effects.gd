## © [2026] A7 Studio. All rights reserved. Trademark.
##
## A utility script to add interactive visual effects to buttons.
## Handles click feedback for mobile interfaces.
class_name ButtonEffects
extends Node

# Constants
const CLICK_SCALE: Vector2 = Vector2(0.95, 0.95)
const NORMAL_SCALE: Vector2 = Vector2(1.0, 1.0)
const TWEEN_DURATION: float = 0.1
const TWEEN_META_KEY: String = "active_button_tween"

# Static Methods
## Applies button effects to a given button.
## [param button] The button to apply effects to.
static func apply(button: Control) -> void:
	if button == null:
		return
	
	# Force the button to ALWAYS process, even when the tree is paused
	button.process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Ensure pivot is centered for scaling effects
	button.pivot_offset = button.size / 2
	
	button.gui_input.connect(_on_gui_input.bind(button))
	button.resized.connect(_on_resized.bind(button))

# Private Static Methods
static func _on_gui_input(event: InputEvent, button: Control) -> void:
	if event is InputEventMouseButton or event is InputEventScreenTouch:
		var is_pressed: bool = false
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			is_pressed = event.pressed
		elif event is InputEventScreenTouch:
			is_pressed = event.pressed
		else:
			return

		if is_pressed:
			_tween_scale(button, CLICK_SCALE)
		else:
			_tween_scale(button, NORMAL_SCALE)

static func _on_resized(button: Control) -> void:
	button.pivot_offset = button.size / 2

static func _tween_scale(button: Control, target_scale: Vector2) -> void:
	# Kill previous tween if it exists to avoid stacking
	if button.has_meta(TWEEN_META_KEY):
		var old_tween = button.get_meta(TWEEN_META_KEY)
		if is_instance_valid(old_tween):
			old_tween.kill()
	
	var tween: Tween = button.create_tween()
	button.set_meta(TWEEN_META_KEY, tween)
	
	# TWEEN_PAUSE_PROCESS makes the tween run even when the scene tree is paused
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", target_scale, TWEEN_DURATION)
