## © [2026] A7 Studio. All rights reserved. Trademark.

class_name HUD
extends Control
## Manages the in-game HUD interface and its components.
##
## Handles resource displays, wave counters, and construction menu.

# Constants
const CHALLENGES_MENU: PackedScene = preload("res://scenes/ui/menus/hud/challenges_menu.tscn")
const COIN_ICON_TEXTURE: Texture2D = preload("res://assets/ui/huds/Coin.png")
const DEFAULT_TIME_SCALE: float = 1.0
const DOTGOTHIC_FONT: Font = preload("res://assets/ui/fonts/dotgothic/DotGothic16-Regular.ttf")
const PAUSE_MENU: PackedScene = preload("res://scenes/ui/menus/pause/pause.tscn")
const POPUP_SCORE_SCENE: PackedScene = preload("res://scenes/ui/popup/popup_score.tscn")
const SKIP_COLOR_INACTIVE: Color = Color(1.0, 1.0, 1.0, 1.0)
const SKIP_TIME_SCALE: float = 3.0
const TOWER_SELECTION_MENU: PackedScene = preload("res://scenes/ui/menus/tower_selection/tower_selection.tscn")

# Variables
@onready var challenges_button: TextureButton = $ChallengesMarginContainer/ChallengesButton
@onready var coins_rich_text_label: Label = %HUDVBoxContainer/CoinsWavesMarginContainer/CoinsWavesHBoxContainer/CoinsTextureRect/MarginContainer/CoinsLabel
@onready var health_rich_text_label: Label = %HUDVBoxContainer/HeartTextureRect/HealthMarginContainer/MarginContainer/HealthTextureProgressBar/HealthLabel
@onready var health_texture_progress_bar: TextureProgressBar = %HUDVBoxContainer/HeartTextureRect/HealthMarginContainer/MarginContainer/HealthTextureProgressBar
@onready var new_wave_count_label: Label = $NewWaveCountLabel
@onready var pause_button: TextureButton = $PauseMarginContainer/PauseButton
@onready var skip_animation_player: AnimationPlayer = $SkipMarginContainer/SkipAnimationPlayer
@onready var skip_time_scale_button: TextureButton = $SkipMarginContainer/SkipButton
@onready var tower_selection_button: TextureButton = $TowerSelectionMarginContainer/TowerSelectionButton
@onready var waves_rich_text_label: Label = %HUDVBoxContainer/CoinsWavesMarginContainer/CoinsWavesHBoxContainer/WavesTextureRect/MarginContainer/WavesLabel

@onready var default_coins_text: String = coins_rich_text_label.text
@onready var default_health_text: String = health_rich_text_label.text
@onready var default_waves_text: String = waves_rich_text_label.text

@onready var signals: Array[Dictionary] = [
	{SignalUtil.WHO: challenges_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_challenges_button_pressed},
	{SignalUtil.WHO: pause_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_pause_button_pressed},
	{SignalUtil.WHO: skip_time_scale_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_skip_time_scale_button_pressed},
	{SignalUtil.WHO: tower_selection_button, SignalUtil.WHAT: "pressed", SignalUtil.TO: _on_tower_selection_button_pressed}
]

var _is_ready: bool = false
var _last_coins: int = 0

# Built-in functions
func _ready() -> void:
	assert(challenges_button != null, "challenges_button node not found")
	assert(coins_rich_text_label != null, "coins_rich_text_label node not found")
	assert(health_rich_text_label != null, "health_rich_text_label node not found")
	assert(waves_rich_text_label != null, "waves_rich_text_label node not found")
	assert(health_texture_progress_bar != null, "health_texture_progress_bar node not found")
	assert(tower_selection_button != null, "tower_selection_button node not found")
	assert(skip_time_scale_button != null, "skip_time_scale_button node not found")

	Global.hud = self
	hide()

	SignalUtil.connects(signals)
	_apply_time_scale(DEFAULT_TIME_SCALE, false)


func _process(_delta: float) -> void:
	if not _is_ready:
		return
	if not visible:
		show()


# Public functions
## Initializes and displays the HUD interface.
func load_ui() -> void:
	if ILevel.current_level == null:
		Log.trace(Log.Level.ERROR, "Cannot load ingame ui, ILevel.current_level = null")
		return

	_is_ready = true
	visible = true
	_last_coins = ILevel.current_level.coins
	SignalUtil.connects([{SignalUtil.WHO: ILevel.current_level, SignalUtil.WHAT: "stats_updated", SignalUtil.TO: _update}])
	_update()


## Cleans up and hides the HUD interface.
func unload_ui() -> void:
	_is_ready = false
	visible = false
	if ILevel.current_level:
		ILevel.current_level.disconnect("stats_updated", _update)


# Private functions
func _apply_time_scale(time_scale: float, is_fast: bool) -> void:
	Engine.time_scale = time_scale
	skip_time_scale_button.button_pressed = is_fast
	if is_fast:
		skip_animation_player.play("skip_active")
	else:
		skip_animation_player.stop()
		skip_time_scale_button.modulate = SKIP_COLOR_INACTIVE


func _on_challenges_button_pressed() -> void:
	var existing := Global.ui.get_node_or_null("ChallengesMenu")
	if existing != null:
		(existing as ChallengesMenu).close()
	else:
		var menu := CHALLENGES_MENU.instantiate() as ChallengesMenu
		Global.ui.add_child(menu)


func _on_pause_button_pressed() -> void:
	if not Global.paused and ILevel.current_level != null:
		Global.paused = true
		ILevel.current_level.state_machine.toggle_state(ILevel.STATE_PAUSE)
		ILevel.current_level.request_pause()
		var pause_menu_instance: Pause = PAUSE_MENU.instantiate()
		Global.ui.add_child(pause_menu_instance)


func _on_skip_time_scale_button_pressed() -> void:
	var is_fast: bool = skip_time_scale_button.button_pressed
	var target_scale: float = SKIP_TIME_SCALE if is_fast else DEFAULT_TIME_SCALE
	_apply_time_scale(target_scale, is_fast)


func _on_tower_selection_button_pressed() -> void:
	if Global.ui.get_node("TowerSelection") == null:
		var tower_selection_menu_instance: TowerSelection = TOWER_SELECTION_MENU.instantiate()
		Global.ui.add_child(tower_selection_menu_instance)
	else:
		Global.ui.get_node("TowerSelection").queue_free()


func _trigger_coin_effects(amount: int) -> void:
	# Bounce effect on the coins label
	var tween: Tween = create_tween()
	coins_rich_text_label.pivot_offset = coins_rich_text_label.size / 2
	tween.tween_property(coins_rich_text_label, "scale", Vector2(1.2, 1.2), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(coins_rich_text_label, "scale", Vector2(1.0, 1.0), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	# Floating notification (+X$)
	var popup = POPUP_SCORE_SCENE.instantiate()
	var label: Label = popup.get_node("FloatingNumbers/Label")

	# Configure label with requested style
	label.add_theme_font_override("font", DOTGOTHIC_FONT)
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 6)
	label.text = "+%d$" % amount
	label.self_modulate = Color(1, 1, 1, 1)

	# Add to HUD to keep it in screen space
	add_child(popup)

	# Initial position: centered on the coin label
	popup.global_position = coins_rich_text_label.global_position + Vector2(coins_rich_text_label.size.x / 2, -10)

	# Physics simulation (Arc movement with gravity and slight random direction)
	var random_x = randf_range(-10, 10) # Even more vertical
	var jump_height = randf_range(30, 45)
	var duration = 0.75 # Match the popup animation length

	var movement_tween = create_tween().set_parallel(true)
	# Horizontal movement
	movement_tween.tween_property(popup, "position:x", popup.position.x + random_x, duration).set_trans(Tween.TRANS_LINEAR)

	# Vertical movement (arc simulating gravity)
	var vertical_tween = create_tween()
	vertical_tween.tween_property(popup, "position:y", popup.position.y - jump_height, duration * 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	vertical_tween.tween_property(popup, "position:y", popup.position.y + 15, duration * 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	# Coins Explosion effect
	_spawn_coin_explosion(popup.global_position)


func _spawn_coin_explosion(start_pos: Vector2) -> void:
	if COIN_ICON_TEXTURE == null:
		return
	var num_coins = randi_range(5, 10)
	for i in range(num_coins):
		var coin = Sprite2D.new()
		coin.texture = COIN_ICON_TEXTURE
		coin.scale = Vector2(0.15, 0.15)
		add_child(coin)
		coin.global_position = start_pos

		var angle = randf_range(-PI * 0.8, -PI * 0.2) # Mostly upwards explosion
		var distance = randf_range(40, 80) # Increased travel distance
		var target_pos = start_pos + Vector2(cos(angle), sin(angle)) * distance

		var coin_tween = create_tween().set_parallel(true)
		coin_tween.tween_property(coin, "global_position", target_pos, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		coin_tween.tween_property(coin, "modulate:a", 0.0, 0.5).set_delay(0.2)
		coin_tween.tween_property(coin, "scale", Vector2.ZERO, 0.5).set_ease(Tween.EASE_IN)
		coin_tween.finished.connect(coin.queue_free)


func _update() -> void:
	if !_is_ready:
		return

	var current_coins = ILevel.current_level.coins
	if current_coins > _last_coins:
		_trigger_coin_effects(current_coins - _last_coins)
	_last_coins = current_coins

	coins_rich_text_label.text = tr(default_coins_text) % current_coins
	health_rich_text_label.text = tr(default_health_text) % (str(ILevel.current_level.health) + "/20")
	health_texture_progress_bar.value = ILevel.current_level.health
	var current_wave: int = ILevel.current_level.current_wave + 1
	waves_rich_text_label.text = tr(default_waves_text) % current_wave
