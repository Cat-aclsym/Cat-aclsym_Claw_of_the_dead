## © [2026] A7 Studio. All rights reserved. Trademark.
##
## Plays the Dialogic timelines of [code]res://assets/narrative[/code], one file per locale ([code]<base>.<locale>.dtl[/code]).
class_name Narrative
extends RefCounted

const DEFAULT_LOCALE: String = "en"
## Pause source held while a one-time dialogue is on screen.
const PAUSE_SOURCE: StringName = &"dialogue"
const TIMELINE_PATH_FORMAT: String = "res://assets/narrative/%s.%s.dtl"


## Plays the timeline [param base] once per save: returns false when [param flag] is already set or when another
## timeline is running (the tutorial, another dialogue), the flag stays unset in that case.
## [br]Otherwise sets the flag, pauses the game until the timeline ends and returns true.
static func play_once(flag: StringName, base: String) -> bool:
	# Dialogic.start would replace the running timeline, its owner would then never see it end
	if Dialogic.current_timeline != null or ProgressionManager.is_flag_set(flag):
		return false

	var process_mode_before: Node.ProcessMode = Dialogic.process_mode
	# Dialogic only advances under a paused tree when its autoload and its layout keep processing
	Dialogic.process_mode = Node.PROCESS_MODE_ALWAYS
	Dialogic.paused = false
	var layout: Node = Dialogic.start(timeline_path(base))
	if layout == null:
		Dialogic.process_mode = process_mode_before
		return false

	layout.process_mode = Node.PROCESS_MODE_ALWAYS
	ProgressionManager.set_flag(flag)
	Global.request_pause(PAUSE_SOURCE)
	_release_when_ended(process_mode_before)
	return true


## Returns the timeline of [param base] in the current locale, or in English when that locale has none.
## [br]Example: [code]timeline_path("armory_intro")[/code] is [code]res://assets/narrative/armory_intro.fr.dtl[/code] in French.
static func timeline_path(base: String) -> String:
	var path: String = TIMELINE_PATH_FORMAT % [base, TranslationServer.get_locale().substr(0, 2)]
	return path if ResourceLoader.exists(path) else TIMELINE_PATH_FORMAT % [base, DEFAULT_LOCALE]


static func _release_when_ended(process_mode_before: Node.ProcessMode) -> void:
	await Dialogic.timeline_ended
	Dialogic.process_mode = process_mode_before
	Global.release_pause(PAUSE_SOURCE)
