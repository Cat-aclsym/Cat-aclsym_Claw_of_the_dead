## © [2026] A7 Studio. All rights reserved. Trademark.
##
## Isometric depth sorting helper: the lower an entity is on screen, the higher it is drawn.
class_name DepthSort
extends RefCounted


## Returns the [member CanvasItem.z_index] for an entity at world height [param y], clamped to the renderer limits.
static func z_from_y(y: float) -> int:
	return clampi(int(y), RenderingServer.CANVAS_ITEM_Z_MIN, RenderingServer.CANVAS_ITEM_Z_MAX)
