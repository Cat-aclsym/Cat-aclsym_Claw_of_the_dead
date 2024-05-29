class_name LevelEndLabel extends Control


@onready var title_text: String = $PanelContainer/VBoxContainer/TitleLabel.text
@onready var kill_text: String = $PanelContainer/VBoxContainer/KillLabel.text
@onready var money_text: String = $PanelContainer/VBoxContainer/MoneyLabel.text
@onready var health_text: String = $PanelContainer/VBoxContainer/HealthLabel.text
@onready var time_text: String = $PanelContainer/VBoxContainer/TimeLabel.text
@onready var score_text: String = $PanelContainer/VBoxContainer/ScoreLabel.text
@onready var replay_button: Button = %ReplayButton
@onready var quit_button: Button = %QuitButton

# core


# functionnal
func update() -> void:
	if not Stats.current_level:
		return
		
	title_text = "YOU WIN" if Stats.current_level_state == Stats.LevelState.WINNING else "YOU LOOSE"
	kill_text = "Total kill : {0}".format([Stats.kill_count])
	money_text = "Total Money : {0}$".format([Stats.money])
	health_text = "Remaining health : {0} / {1}".format([Stats.current_level.health, Stats.current_level.max_health])
	
	var time_remaining: float = Time.get_unix_time_from_system() - Stats.start_time
	var sec: int = floor(time_remaining)
	var ms: int = floor((time_remaining - sec) * 10)
	time_text = "Time : {0}.{1}s".format([sec, ms])
	
	score_text = "Score : {0}".format([Stats.score])


# signals
func _on_replay_button_pressed() -> void:
	pass # Replace with function body.


func _on_quit_button_pressed() -> void:
	pass # Replace with function body.
