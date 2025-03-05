extends Node

func _ready():
	print("Starting dialogue")
	Dialogic.start("example")

func _on_timeline_ended():
	print("Timeline ended")
