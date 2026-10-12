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
	assert(node, "Missing node")
	assert(property, "Missing property")

	# Watchers are debug-only, release builds free them
	if not Global.debug:
		queue_free()


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
