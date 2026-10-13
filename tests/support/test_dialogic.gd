## © [2026] A7 Studio. All rights reserved. Trademark.
##
## Brings the Dialogic autoload back to idle between two tests.
class_name TestDialogic
extends RefCounted


## Ends the timeline a test left running, frees its layout and releases every pause: [code]await[/code] it in [code]after_test[/code].
## [br]Ending the timeline lets [Narrative] restore the process mode of [code]Dialogic[/code] and release its pause source.
static func reset() -> void:
	if Dialogic.current_timeline != null:
		await Dialogic.end_timeline(true)
	if Dialogic.Styles.has_active_layout_node():
		await Dialogic.clear(Dialogic.ClearFlags.FULL_CLEAR)
	Dialogic.paused = false
	Global.clear_pauses()
