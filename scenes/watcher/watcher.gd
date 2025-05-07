## © [2024] A7 Studio. All rights reserved. Trademark.
## Debug node to display in realtime value of a node property.
## @experimental
class_name Watcher extends PanelContainer


@export var node: Node
@export var property: StringName
@export var physics: bool = false

@onready var label: Label = $Label

# core
func _ready() -> void:
	if not Global.debug:
		# Since we (obviously) we gonna forget to 
		#  remove all watchers when we'll build release
		#  i set this just in case
		queue_free()

	assert(node, "Missing node")
	assert(property, "Missing property")


func _process(_delta: float) -> void:
	if not physics:
		_update()


func _physics_process(_delta: float) -> void:
	if physics:
		_update()


# public


# private
func _update() -> void:
	label.text = "{property}: {value}".format({
		"property": property,
		"value": str(node.get(property))
	})
