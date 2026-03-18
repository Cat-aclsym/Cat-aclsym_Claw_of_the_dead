## © [2026] A7 Studio. All rights reserved. Trademark.

class_name ChallengesMenu
extends Control
## Ingame side panel that displays active challenge details. Slides in from the right.

signal menu_close

const CHALLENGE_CARD: PackedScene = preload("res://scenes/ui/menus/hud/challenge_card.tscn")
const PANEL_WIDTH: float = 430.0
const SLIDE_DURATION: float = 0.22

@onready var challenges_container: VBoxContainer = %ChallengesContainer
@onready var close_button: TextureButton = %CloseButton
@onready var dimmer: ColorRect = %Dimmer
@onready var panel: Control = %Panel
@onready var title_label: Label = %TitleLabel

@onready var signals: Array[Dictionary] = [
	{SignalUtil.WHO: ChallengeManager, SignalUtil.WHAT: "challenges_loaded", SignalUtil.TO: _populate},
	{SignalUtil.WHO: close_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_close_pressed},
	{SignalUtil.WHO: dimmer, SignalUtil.WHAT: "gui_input", SignalUtil.TO: _on_dimmer_input},
]

var _is_closing: bool = false
var _tween: Tween


func _ready() -> void:
	assert(challenges_container != null, "ChallengesContainer not found")
	assert(close_button != null, "CloseButton not found")
	assert(dimmer != null, "Dimmer not found")
	assert(panel != null, "Panel not found")

	title_label.text = tr("CHALLENGES.PANEL.TITLE")
	SignalUtil.connects(signals)
	_populate()
	_slide_in()


## Closes the menu with slide-out animation.
func close() -> void:
	_slide_out()


func _on_close_pressed() -> void:
	_slide_out()


func _on_dimmer_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		_slide_out()


func _populate() -> void:
	for child in challenges_container.get_children():
		child.queue_free()

	var level_id := ChallengeManager.active_level_id
	var completed_in_save: Array[String] = []
	if ProgressionManager.data.levels.has(level_id):
		completed_in_save = ProgressionManager.data.levels[level_id].challenges_completed

	for c in ChallengeManager.get_active_challenges():
		var card := CHALLENGE_CARD.instantiate() as ChallengeCard
		challenges_container.add_child(card)
		card.setup(c, (c.id in completed_in_save) or c.is_completed)


func _slide_in() -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	_tween.tween_method(
		func(v: float) -> void:
			panel.offset_left = v
			panel.offset_right = v + PANEL_WIDTH,
		0.0, -PANEL_WIDTH, SLIDE_DURATION
	)


func _slide_out() -> void:
	if _is_closing:
		return
	_is_closing = true
	if _tween:
		_tween.kill()
	_tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	_tween.tween_method(
		func(v: float) -> void:
			panel.offset_left = v
			panel.offset_right = v + PANEL_WIDTH,
		-PANEL_WIDTH, 0.0, SLIDE_DURATION
	)
	await _tween.finished
	menu_close.emit()
	queue_free()
