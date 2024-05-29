extends Line2D

## Reference to the parent node, which should be a Path2D.
@onready var path = get_parent()

## Called when the node is added to the scene.
func _ready():
	## Check if the parent node exists.
	if path:
		## Get the baked points from the path's curve.
		var p = path.curve.get_baked_points()
		## Set the points of the Line2D to match the baked points of the path.
		self.set_points(p)
