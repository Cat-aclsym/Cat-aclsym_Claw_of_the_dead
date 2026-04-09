## © [2026] A7 Studio. All rights reserved. Trademark.
##
## Overlay used to guide tutorial interactions.
## Displays a light backdrop, highlights one target control, and blocks clicks outside it.
class_name TutorialOverlay
extends Control

# Constants
const BACKDROP_COLOR: Color = Color(0.0, 0.0, 0.0, 0.35)
const DEFAULT_HOLE_PADDING: float = 8.0
const ARROW_BOB_DISTANCE: float = 6.0
const ARROW_BOB_SPEED: float = 4.0

# Private variables
var _arrow_base_position: Vector2 = Vector2.ZERO
var _hole_padding: float = DEFAULT_HOLE_PADDING
var _is_blocking: bool = true
var _target_control: Control = null

# Onready variables
@onready var _arrow: TextureRect = $Arrow
@onready var _backdrop_bottom: ColorRect = $BackdropBottom
@onready var _backdrop_left: ColorRect = $BackdropLeft
@onready var _backdrop_right: ColorRect = $BackdropRight
@onready var _backdrop_top: ColorRect = $BackdropTop

# Core
func _ready() -> void:
	assert(_arrow != null, "arrow node not found")
	assert(_backdrop_bottom != null, "backdrop_bottom node not found")
	assert(_backdrop_left != null, "backdrop_left node not found")
	assert(_backdrop_right != null, "backdrop_right node not found")
	assert(_backdrop_top != null, "backdrop_top node not found")

	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)

	for backdrop in [_backdrop_top, _backdrop_left, _backdrop_right, _backdrop_bottom]:
		backdrop.color = BACKDROP_COLOR
		backdrop.mouse_filter = Control.MOUSE_FILTER_STOP

	visible = false


func _process(delta: float) -> void:
	if not visible:
		return

	if not is_instance_valid(_target_control):
		hide_overlay()
		return

	_update_layout()
	_arrow.position.y = _arrow_base_position.y + sin(Time.get_ticks_msec() / 1000.0 * ARROW_BOB_SPEED) * ARROW_BOB_DISTANCE * delta * 60.0

# Public
## Highlights the target control and blocks outside clicks.
## [param target] Control to highlight
## [param hole_padding] Extra padding around the highlighted area
func show_for_target(target: Control, hole_padding: float = DEFAULT_HOLE_PADDING) -> void:
	if not is_instance_valid(target):
		hide_overlay()
		return

	_target_control = target
	_hole_padding = maxf(0.0, hole_padding)
	visible = true
	_apply_blocking_mode()
	_update_layout()


## Hides the overlay and removes active target.
func hide_overlay() -> void:
	_target_control = null
	visible = false


## Enables or disables outside-click blocking while the overlay is visible.
func set_blocking_mode(enabled: bool) -> void:
	_is_blocking = enabled
	_apply_blocking_mode()

# Private
func _get_target_rect() -> Rect2:
	if not is_instance_valid(_target_control):
		return Rect2(Vector2.ZERO, Vector2.ZERO)

	var global_rect: Rect2 = _target_control.get_global_rect()
	var local_position: Vector2 = global_rect.position - global_position
	var expanded_size: Vector2 = Vector2(
		global_rect.size.x + (_hole_padding * 2.0),
		global_rect.size.y + (_hole_padding * 2.0)
	)
	return Rect2(local_position - Vector2(_hole_padding, _hole_padding), expanded_size)


func _update_layout() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	var hole_rect: Rect2 = _get_target_rect()

	if hole_rect.size.x <= 0.0 or hole_rect.size.y <= 0.0:
		hide_overlay()
		return

	# Top blocker
	_backdrop_top.position = Vector2(0.0, 0.0)
	_backdrop_top.size = Vector2(viewport_size.x, maxf(0.0, hole_rect.position.y))

	# Bottom blocker
	var bottom_y: float = hole_rect.position.y + hole_rect.size.y
	_backdrop_bottom.position = Vector2(0.0, bottom_y)
	_backdrop_bottom.size = Vector2(viewport_size.x, maxf(0.0, viewport_size.y - bottom_y))

	# Left blocker
	_backdrop_left.position = Vector2(0.0, hole_rect.position.y)
	_backdrop_left.size = Vector2(maxf(0.0, hole_rect.position.x), hole_rect.size.y)

	# Right blocker
	var right_x: float = hole_rect.position.x + hole_rect.size.x
	_backdrop_right.position = Vector2(right_x, hole_rect.position.y)
	_backdrop_right.size = Vector2(maxf(0.0, viewport_size.x - right_x), hole_rect.size.y)

	_arrow_base_position = Vector2(
		hole_rect.position.x + (hole_rect.size.x * 0.5) - (_arrow.size.x * 0.5),
		hole_rect.position.y - _arrow.size.y - 10.0
	)
	_arrow.position = _arrow_base_position


func _apply_blocking_mode() -> void:
	var target_filter: Control.MouseFilter = Control.MOUSE_FILTER_STOP if _is_blocking else Control.MOUSE_FILTER_IGNORE
	for backdrop in [_backdrop_top, _backdrop_left, _backdrop_right, _backdrop_bottom]:
		backdrop.mouse_filter = target_filter
