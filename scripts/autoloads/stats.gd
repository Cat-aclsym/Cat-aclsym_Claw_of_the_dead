extends Node

enum LevelState {
	NONE,
	RUNNING,
	LOOSING,
	WINNING
}


var current_level: ILevel = null
var current_level_state: LevelState = LevelState.NONE
var kill_count: int = 0
var start_time: float = -1.
var money: int = 0
var score: int = 0


func reset() -> void:
	current_level = null
	current_level_state = LevelState.NONE
	kill_count = 0
	start_time = -1.
	money = 0
	score = 0


