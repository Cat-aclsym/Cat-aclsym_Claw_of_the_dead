extends Line2D

@onready var path = get_parent()

func _ready():
	if path:
		var points = path.curve.get_baked_points()
		print(points)
		self.set_points(points)
