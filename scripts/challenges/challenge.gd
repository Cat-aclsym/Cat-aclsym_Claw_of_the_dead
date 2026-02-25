## © [2024] A7 Studio. All rights reserved. Trademark.

class_name Challenge
extends Node
## Base class for all level challenges.
##
## Challenges monitor specific conditions during gameplay and can be completed or failed.

# Signals
signal completed(challenge_id: String)
signal failed(challenge_id: String)

# Public variables
var id: String
var description: String
var title: String
var difficulty: String
var is_completed: bool = false
var is_failed: bool = false


# Built-in functions
func _init(p_id: String, p_title: String, p_desc: String, p_diff: String) -> void:
	id = p_id
	title = p_title
	description = p_desc
	difficulty = p_diff


# Public functions
## Called when the level starts to reset state.
func start_monitoring() -> void:
	is_completed = false
	is_failed = false


## Evaluates if the challenge conditions are met at the end of the level.
func check_completion() -> bool:
	return not is_failed


## Marks the challenge as completed and saves progression.
func complete() -> void:
	if is_completed or is_failed:
		return
	is_completed = true
	completed.emit(id)
	if ILevel.current_level:
		ProgressionManager.complete_challenge(ILevel.current_level.level_id, id)


## Marks the challenge as failed.
func fail() -> void:
	if is_completed or is_failed:
		return
	is_failed = true
	failed.emit(id)
