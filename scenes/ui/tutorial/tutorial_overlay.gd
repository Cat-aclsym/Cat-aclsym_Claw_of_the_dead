## © [2026] A7 Studio. All rights reserved. Trademark.
##
## Animated arrow pointer for tutorial guidance.
## Points at a screen-space Control or any world-space CanvasItem (Node2D or world-parented Control)
## with a directional bounce animation.
class_name TutorialOverlay
extends Control

# Enums
enum Direction { RIGHT, DOWN, LEFT, UP }

# Constants
const ARROW_BOB_DISTANCE: float = 6.0
const ARROW_BOB_SPEED: float = 4.0
const ARROW_OFFSET: float = 14.0

# Private variables
var _direction: Direction = Direction.DOWN
var _target_control: Control = null
var _target_world_item: CanvasItem = null
var _target_world_size: Vector2 = Vector2(64.0, 64.0)

# Onready variables
@onready var _arrow: TextureRect = $Arrow

# Core
func _ready() -> void:
	assert(_arrow != null, "arrow node not found")
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	if _arrow.texture != null:
		# Store natural texture size; scale property is applied on top.
		_arrow.size = Vector2(_arrow.texture.get_width(), _arrow.texture.get_height())
		_arrow.pivot_offset = _arrow.size * 0.5
	visible = false


func _process(_delta: float) -> void:
	if not visible:
		return
	if not is_instance_valid(_target_control) and not is_instance_valid(_target_world_item):
		hide_overlay()
		return
	_update_layout(_get_target_rect())


# Public
## Points at a screen-space UI Control (in the viewport/HUD layer, not under a world Node2D).
func show_for_target(target: Control) -> void:
	if not is_instance_valid(target):
		hide_overlay()
		return
	if _target_control == target:
		return
	Log.trace(Log.Level.DEBUG, "TutorialOverlay show_for_target: %s @ %s" % [target.name, target.get_global_rect()])
	_target_world_item = null
	_target_control = target
	_init_arrow(_get_target_rect())


## Points at any world-space CanvasItem: Node2D, CharacterBody2D, or a Control parented under
## a world Node2D (e.g. RadialTowerUpgradeMenu child of ITower). Uses canvas→screen conversion
## so the arrow follows camera pan and zoom.
## [param world_size] Bounding box in world units (NOT screen pixels). For a Control child of
## a Node2D whose visual is drawn via _draw() / radius, pass the known diameter, e.g.
## Vector2(radius * 2, radius * 2). Defaults to Vector2(64, 64).
func show_for_world_item(item: CanvasItem, world_size: Vector2 = Vector2(64.0, 64.0)) -> void:
	if not is_instance_valid(item):
		hide_overlay()
		return
	# Avoid reinitialising (and losing the bob phase) when called every frame for the same target.
	if _target_world_item == item and _target_world_size.is_equal_approx(world_size):
		return
	Log.trace(Log.Level.DEBUG, "TutorialOverlay show_for_world_item: %s @ %s" % [item.name, item.get_global_transform().get_origin()])
	_target_control = null
	_target_world_item = item
	_target_world_size = world_size
	_init_arrow(_get_target_rect())


## Hides the arrow and clears any active target.
func hide_overlay() -> void:
	_target_control = null
	_target_world_item = null
	visible = false


## No-op — kept for API compatibility with TutorialManager.
func set_blocking_mode(_enabled: bool) -> void:
	pass


# Private
func _init_arrow(rect: Rect2) -> void:
	_direction = _auto_direction(rect)
	_arrow.rotation = _rotation_for_direction(_direction)
	visible = true
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_update_layout(rect)


func _get_target_rect() -> Rect2:
	if is_instance_valid(_target_control):
		return _target_control.get_global_rect()
	if is_instance_valid(_target_world_item):
		var canvas_xform: Transform2D = get_viewport().get_canvas_transform()
		var screen_center: Vector2 = canvas_xform * _target_world_item.get_global_transform().get_origin()
		var screen_size: Vector2 = _target_world_size * canvas_xform.get_scale()
		return Rect2(screen_center - screen_size * 0.5, screen_size)
	return Rect2()


func _auto_direction(rect: Rect2) -> Direction:
	var center: Vector2 = rect.get_center()
	var vp: Vector2 = get_viewport_rect().size
	var spaces: Array[float] = [center.y, vp.y - center.y, center.x, vp.x - center.x]
	var directions: Array[Direction] = [Direction.DOWN, Direction.UP, Direction.RIGHT, Direction.LEFT]
	var best: int = 0
	for i: int in range(1, spaces.size()):
		if spaces[i] > spaces[best]:
			best = i
	return directions[best]


func _rotation_for_direction(dir: Direction) -> float:
	match dir:
		Direction.DOWN: return PI / 2.0
		Direction.LEFT: return PI
		Direction.UP: return -PI / 2.0
		_: return 0.0


func _update_layout(target_rect: Rect2) -> void:
	var center: Vector2 = target_rect.get_center()
	var half: Vector2 = _arrow.size * 0.5
	var tip_reach: float = _arrow.size.x * _arrow.scale.x * 0.5
	var bob: float = sin(Time.get_ticks_msec() / 1000.0 * ARROW_BOB_SPEED) * ARROW_BOB_DISTANCE
	var arrow_center: Vector2

	match _direction:
		Direction.RIGHT:
			arrow_center = Vector2(target_rect.position.x - ARROW_OFFSET - tip_reach + bob, center.y)
		Direction.LEFT:
			arrow_center = Vector2(target_rect.end.x + ARROW_OFFSET + tip_reach - bob, center.y)
		Direction.DOWN:
			arrow_center = Vector2(center.x, target_rect.position.y - ARROW_OFFSET - tip_reach + bob)
		Direction.UP:
			arrow_center = Vector2(center.x, target_rect.end.y + ARROW_OFFSET + tip_reach - bob)
		_:
			arrow_center = center

	_arrow.position = arrow_center - half
