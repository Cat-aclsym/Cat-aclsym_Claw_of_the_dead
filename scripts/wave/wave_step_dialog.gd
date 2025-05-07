## © [2024] A7 Studio. All rights reserved. Trademark.

class_name WaveStepDialog extends WaveStep

var _dialog_started: bool = false

# core
func _init(in_data: Dictionary) -> void:
	super._init(WaveStep.Order.DIALOG, in_data)

# public
func exec() -> void:
	if not _dialog_started:
		var dialog_id: String = _data[WaveStep.DIALOG_ID]
		Dialogic.start(dialog_id)
		Dialogic.timeline_ended.connect(_on_dialog_finished)
		_dialog_started = true

func is_over() -> bool:
	return _data.has("finished") and _data["finished"]

# private
func _on_dialog_finished() -> void:
	_data["finished"] = true
	Dialogic.timeline_ended.disconnect(_on_dialog_finished)

# signal

# event

# setget 
