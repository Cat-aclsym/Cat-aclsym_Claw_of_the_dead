## © [2026] A7 Studio. All rights reserved. Trademark.

class_name PathIndicator
extends Node2D

## Type of point (start or end)
enum PointType { START, END }

const GLOW_SEGMENTS: int = 32

@export var type: PointType = PointType.START
@export var base_color: Color = Color.GREEN

var _glow_poly: Polygon2D

func _ready() -> void:
	_setup_visuals()
	_animate_glow()

func _setup_visuals() -> void:
	# Outer glow: isometric ellipse (ratio 2:1), slightly larger than a tile
	_glow_poly = _create_ellipse(32.0, 16.0, base_color, 0.2)
	add_child(_glow_poly)

	# Middle glow
	add_child(_create_ellipse(16.0, 8.0, base_color, 0.4))

	# Core light point
	add_child(_create_ellipse(6.0, 3.0, Color.WHITE, 0.9))

	# Label to clarify
	var label: Label = Label.new()
	label.text = tr("MAP.PATH.SPAWN") if type == PointType.START else tr("MAP.PATH.BASE")
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 2)
	label.position = Vector2(-20, -25)
	add_child(label)

func _create_ellipse(radius_x: float, radius_y: float, color: Color, alpha: float) -> Polygon2D:
	var points: PackedVector2Array = PackedVector2Array()
	for i: int in range(GLOW_SEGMENTS):
		var angle: float = i * TAU / GLOW_SEGMENTS
		points.append(Vector2(cos(angle) * radius_x, sin(angle) * radius_y))

	var poly: Polygon2D = Polygon2D.new()
	poly.polygon = points
	poly.color = color
	poly.color.a = alpha
	return poly

func _animate_glow() -> void:
	var tween: Tween = create_tween().set_loops()

	# Pulsing effect
	tween.tween_property(_glow_poly, "scale", Vector2(1.2, 1.2), 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(_glow_poly, "color:a", 0.6, 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	tween.tween_property(_glow_poly, "scale", Vector2(0.8, 0.8), 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(_glow_poly, "color:a", 0.3, 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
