## © [2026] A7 Studio. All rights reserved. Trademark.
##
## Visual indicator shown during the tutorial PLACE_CONFIRM step.
## Place this node in the level scene at the desired tile world position.
## If snap_tilemap is set, the node snaps itself to the nearest tile center.
class_name TutorialPlacementHint
extends Node2D

const PULSE_SPEED: float = 3.0
const PULSE_MIN_ALPHA: float = 0.4
const PULSE_MAX_ALPHA: float = 1.0
const BORDER_WIDTH: float = 3.0
const FILL_ALPHA_RATIO: float = 0.25
const COLOR: Color = Color(0.25, 1.0, 0.45)

@export var snap_tilemap: TileMap = null

var _time: float = 0.0
var _half_w: float = 32.0
var _half_h: float = 16.0

func _ready() -> void:
	z_as_relative = false
	z_index = 10
	visible = false
	_snap_to_tile()

func _snap_to_tile() -> void:
	if not is_instance_valid(snap_tilemap):
		return
	var tile_size: Vector2i = snap_tilemap.tile_set.tile_size
	_half_w = tile_size.x / 2.0
	_half_h = tile_size.y / 2.0
	var local_in_tm: Vector2 = snap_tilemap.to_local(global_position)
	var cell: Vector2i = snap_tilemap.local_to_map(local_in_tm)
	global_position = snap_tilemap.to_global(snap_tilemap.map_to_local(cell))

func _process(delta: float) -> void:
	if not visible:
		return
	_time += delta
	queue_redraw()

func _draw() -> void:
	var alpha: float = lerpf(PULSE_MIN_ALPHA, PULSE_MAX_ALPHA, (sin(_time * PULSE_SPEED) + 1.0) * 0.5)
	var diamond := PackedVector2Array([
		Vector2(0.0, -_half_h),
		Vector2(_half_w, 0.0),
		Vector2(0.0, _half_h),
		Vector2(-_half_w, 0.0),
	])
	draw_colored_polygon(diamond, Color(COLOR.r, COLOR.g, COLOR.b, alpha * FILL_ALPHA_RATIO))
	draw_polyline(
		PackedVector2Array([diamond[0], diamond[1], diamond[2], diamond[3], diamond[0]]),
		Color(COLOR.r, COLOR.g, COLOR.b, alpha),
		BORDER_WIDTH
	)

func show_hint() -> void:
	visible = true

func hide_hint() -> void:
	visible = false
