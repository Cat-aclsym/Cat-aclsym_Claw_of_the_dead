extends Line2D

@onready var path = get_parent()


# core
func _ready():
	if path:
		var p = path.curve.get_baked_points()
		self.set_points(p)


# public


# private


# signal


# event


# setget

