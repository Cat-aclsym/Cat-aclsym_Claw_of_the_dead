extends Line2D

@onready var path = get_parent()

func _ready():
	if path:
		var p = path.curve.get_baked_points()
		self.set_points(p)
