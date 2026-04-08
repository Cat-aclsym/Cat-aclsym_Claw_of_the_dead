## © [2026] A7 Studio. All rights reserved. Trademark.

class_name HudChallenges
extends HBoxContainer
## HUD component displaying current level challenge status icons.

# Constants
const ICON_DONE: Texture2D = preload("res://assets/ui/icons/Star.png")
const ICON_TODO: Texture2D = preload("res://assets/ui/icons/Star_Empty.png")
const TINT_DEFAULT: Color = Color.WHITE
const TINT_FAILED: Color = Color(1.0, 0.35, 0.35, 1.0)


# Variables
@onready var signals: Array[Dictionary] = [
	{SignalUtil.WHO: ChallengeManager, SignalUtil.WHAT: "challenges_loaded", SignalUtil.TO: setup_challenges},
	{SignalUtil.WHO: ChallengeManager, SignalUtil.WHAT: "challenge_status_updated", SignalUtil.TO: _on_challenge_status_updated}
]


# Built-in functions
func _ready() -> void:
	if not ChallengeManager.is_node_ready():
		await ChallengeManager.ready

	SignalUtil.connects(signals)

	# Initial setup if challenges are already loaded
	if not ChallengeManager.get_active_challenges().is_empty():
		setup_challenges()
		ChallengeManager.emit_runtime_status()


# Public functions
## (Re)creates icon nodes for active challenges.
func setup_challenges() -> void:
	# Clear existing children
	for child in get_children():
		child.queue_free()

	var level_id := ChallengeManager.active_level_id
	var completed_in_save: Array[String] = []
	if ProgressionManager.data.levels.has(level_id):
		completed_in_save = ProgressionManager.data.levels[level_id].challenges_completed

	var challenges: Array[Challenge] = ChallengeManager.get_active_challenges()
	for c in challenges:
		_add_challenge_icon(c, completed_in_save)


# Private functions
func _add_challenge_icon(c: Challenge, completed_in_save: Array[String]) -> void:
	var icon := TextureRect.new()
	# Shown as DONE if already earned in save OR completed in current run
	var is_done: bool = (c.id in completed_in_save) or c.is_completed
	icon.texture = ICON_DONE if is_done else ICON_TODO
	icon.modulate = TINT_DEFAULT
	icon.name = c.id
	icon.custom_minimum_size = Vector2(32, 32)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	add_child(icon)



func _on_challenge_status_updated(challenge_id: String, is_completed: bool, is_failed: bool) -> void:
	var icon := get_node_or_null(challenge_id) as TextureRect
	if not icon:
		return
	if is_failed:
		icon.texture = ICON_DONE
		icon.modulate = TINT_FAILED
		return
	icon.modulate = TINT_DEFAULT
	icon.texture = ICON_DONE if is_completed else ICON_TODO
