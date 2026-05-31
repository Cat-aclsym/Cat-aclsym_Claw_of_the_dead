## © [2026] A7 Studio. All rights reserved. Trademark.
##
## Manages the game's user interface elements including HUD and pause menu.
## This class handles the initialization and management of UI components such as the pause menu, HUD, and pause button functionality.
class_name UI
extends CanvasLayer

## Flag indicating if the UI has been initialized
var _initialized: bool = false

@onready var hud: HUD = $HUD
@onready var ingame_fade_color_rect: ColorRect = $IngameFadeColorRect
@onready var tutorial_manager: TutorialManager = $TutorialManager

# core
func _ready() -> void:
	assert(hud != null, "hud node not found")
	assert(ingame_fade_color_rect != null, "ingame_fade_color_rect node not found")
	assert(tutorial_manager != null, "tutorial_manager node not found")
	Global.set("ui", self)
	_initialized = true

# public
## Initializes and displays the HUD for a new level.
## [br]This function must be called when starting a new level to set up the UI.
func start_level() -> void:
	assert(_initialized, "UI not properly initialized")
	Log.trace(Log.Level.INFO, "HUD : Loading level interface")
	hud.load_ui()
	tutorial_manager.on_level_started(ILevel.current_level)
	_play_ingame_fade_in()

## Cleans up and hides the HUD when leaving a level.
## [br]This function must be called when exiting a level to clean up the UI.
func end_level() -> void:
	assert(_initialized, "UI not properly initialized")
	Log.trace(Log.Level.INFO, "HUD : Unloading level interface")
	hud.unload_ui()
	tutorial_manager.on_level_ended()
	# Auto-save progression when exiting a level
	ProgressionManager.save_game()


## Displays the "new challenger" reveal for a newly discovered enemy.
func notify_new_enemy_reveal(enemy_id: String, texture: Texture2D, enemy_scale: Vector2 = Vector2.ONE) -> void:
	assert(_initialized, "UI not properly initialized")
	hud.queue_new_enemy_reveal(enemy_id, texture, enemy_scale)


func _play_ingame_fade_in() -> void:
	ingame_fade_color_rect.visible = true
	ingame_fade_color_rect.color = Color(0.0, 0.0, 0.0, 1.0)

	var tween: Tween = create_tween()
	tween.tween_property(ingame_fade_color_rect, "color", Color(1.0, 1.0, 1.0, 0.0), 1.0)
	tween.tween_callback(_on_ingame_fade_finished)


func _on_ingame_fade_finished() -> void:
	ingame_fade_color_rect.visible = false
