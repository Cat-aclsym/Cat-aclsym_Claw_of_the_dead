## © [2026] A7 Studio. All rights reserved. Trademark.

class_name HudChallenges
extends HBoxContainer
## HUD component displaying current level challenge status icons.

# Constants
const ICON_DONE: Texture2D = preload("res://assets/ui/icons/Star.png")
const ICON_TODO: Texture2D = preload("res://assets/ui/icons/Star_Empty.png")


# Variables
@onready var signals: Array[Dictionary] = [
	{SignalUtil.WHO: ChallengeManager, SignalUtil.WHAT: "challenges_loaded", SignalUtil.TO: setup_challenges}
]


# Built-in functions
func _ready() -> void:
	if not ChallengeManager.is_node_ready():
		await ChallengeManager.ready

	SignalUtil.connects(signals)

	# Initial setup if challenges are already loaded
	if not ChallengeManager.get_active_challenges().is_empty():
		setup_challenges()


# Public functions
## (Re)creates icon nodes for active challenges.
func setup_challenges() -> void:
	# Clear existing children
	for child in get_children():
		child.queue_free()

	var level_id := ChallengeManager.active_level_id
	var completed_in_save: Array = []
	if ProgressionManager.data.levels.has(level_id):
		completed_in_save = ProgressionManager.data.levels[level_id].challenges_completed

	var challenges: Array[Challenge] = ChallengeManager.get_active_challenges()
	for c in challenges:
		_add_challenge_icon(c, completed_in_save)


# Private functions
func _add_challenge_icon(c: Challenge, completed_in_save: Array) -> void:
	var icon := TextureRect.new()
	# Shown as DONE if already earned in save OR completed in current run
	var is_done: bool = (c.id in completed_in_save) or c.is_completed
	icon.texture = ICON_DONE if is_done else ICON_TODO
	icon.name = c.id
	icon.custom_minimum_size = Vector2(32, 32)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	add_child(icon)

	# Connect directly to challenge signals
	SignalUtil.connects([
		{SignalUtil.WHO: c, SignalUtil.WHAT: "completed", SignalUtil.TO: func(_id): icon.texture = ICON_DONE},
		{SignalUtil.WHO: c, SignalUtil.WHAT: "failed", SignalUtil.TO: func(_id): icon.texture = ICON_TODO}
	])
