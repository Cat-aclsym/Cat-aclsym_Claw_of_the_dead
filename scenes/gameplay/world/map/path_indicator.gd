## © [2026] A7 Studio. All rights reserved. Trademark.

class_name PathIndicator
extends Node2D

## Type of point (start or end)
enum PointType { START, END }

@export var type: PointType = PointType.START
@export var base_color: Color = Color.GREEN

var _glow_poly: Polygon2D

func _ready() -> void:
	_setup_visuals()
	_animate_glow()

func _setup_visuals() -> void:
	_glow_poly = Polygon2D.new()
	
	# Create an isometric ellipse shape
	var points = PackedVector2Array()
	var segments = 32
	var radius_x = 32.0 # Slightly larger
	var radius_y = 16.0 # Isometric ratio 2:1
	
	for i in range(segments):
		var angle = i * TAU / segments
		points.append(Vector2(cos(angle) * radius_x, sin(angle) * radius_y))
	
	_glow_poly.polygon = points
	_glow_poly.color = base_color
	_glow_poly.color.a = 0.2
	# No z_index here, we'll set it on the parent if needed
	add_child(_glow_poly)
	
	# Middle glow
	var mid = Polygon2D.new()
	var mid_points = PackedVector2Array()
	for i in range(segments):
		var angle = i * TAU / segments
		mid_points.append(Vector2(cos(angle) * 16.0, sin(angle) * 8.0))
	mid.polygon = mid_points
	mid.color = base_color
	mid.color.a = 0.4
	add_child(mid)
	
	# Add a core light point
	var core = Polygon2D.new()
	var core_points = PackedVector2Array()
	for i in range(segments):
		var angle = i * TAU / segments
		core_points.append(Vector2(cos(angle) * 6.0, sin(angle) * 3.0))
	core.polygon = core_points
	core.color = Color.WHITE
	core.color.a = 0.9
	add_child(core)

	# Label to clarify
	var label = Label.new()
	label.text = tr("SPAWN") if type == PointType.START else tr("BASE")
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 2)
	label.position = Vector2(-20, -25)
	add_child(label)

func _animate_glow() -> void:
	var tween = create_tween().set_loops()
	
	# Pulsing effect
	tween.tween_property(_glow_poly, "scale", Vector2(1.2, 1.2), 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(_glow_poly, "color:a", 0.6, 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	tween.tween_property(_glow_poly, "scale", Vector2(0.8, 0.8), 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(_glow_poly, "color:a", 0.3, 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
