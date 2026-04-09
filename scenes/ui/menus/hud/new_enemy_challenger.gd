## © [2026] A7 Studio. All rights reserved. Trademark.

class_name NewEnemyChallenger
extends Control
## Fullscreen reveal shown when a new enemy type is discovered.

signal reveal_finished

# Constants
const BAR_ANIM_DURATION: float = 0.2
const BACKGROUND_TARGET_ALPHA: float = 0.4
const FLASH_DURATION: float = 0.1
const FLAT_ALPHA_TINT_SHADER: Shader = preload("res://assets/resources/shaders/flat_alpha_tint.gdshader")
const HOLD_DURATION: float = 1.8
const OUTRO_DURATION: float = 0.3
const PANEL_START_OFFSET_Y: float = 110.0
const SILHOUETTE_SCALE_MULTIPLIER: float = 1.16
const SLASH_DURATION: float = 0.18
const TITLE_ANIM_DURATION: float = 0.35

# Onready variables
@onready var background_rect: ColorRect = $Background
@onready var aura_rect: ColorRect = %AuraRect
@onready var bottom_bar: ColorRect = $BottomBar
@onready var flash_rect: ColorRect = $FlashRect
@onready var middle_band: ColorRect = $MiddleBand
@onready var silhouette_container: Control = %SilhouetteContainer
@onready var silhouette_rect: TextureRect = %SilhouetteRect
@onready var subtitle_label: Label = %SubtitleLabel
@onready var top_bar: ColorRect = $TopBar
@onready var title_label: Label = %TitleLabel

# Private variables
var _is_waiting_for_continue: bool = false
var _silhouette_material: ShaderMaterial = null

# Public functions
## Plays the reveal animation for an enemy silhouette.
func play_reveal(enemy_id: String, texture: Texture2D, enemy_scale: Vector2 = Vector2.ONE) -> void:
	if texture == null:
		return

	_apply_texts(enemy_id)
	apply_silhouette(texture, enemy_scale)
	await _play_animation()
	reveal_finished.emit()


## Applies a silhouette texture to the reveal panel.
func apply_silhouette(texture: Texture2D, enemy_scale: Vector2 = Vector2.ONE) -> void:
	silhouette_rect.texture = texture
	silhouette_rect.scale = enemy_scale * SILHOUETTE_SCALE_MULTIPLIER
	silhouette_rect.modulate = Color.WHITE
	silhouette_rect.material = _get_silhouette_material()


# Private functions
func _apply_texts(enemy_id: String) -> void:
	title_label.text = tr("INGAMEHUD.NEW_ENEMY.TITLE")
	var translated_enemy_name: String = tr("ENEMY.%s.NAME" % enemy_id.to_upper())
	if translated_enemy_name == "ENEMY.%s.NAME" % enemy_id.to_upper():
		translated_enemy_name = enemy_id.replace("_", " ").capitalize()
	subtitle_label.text = tr("INGAMEHUD.NEW_ENEMY.SUBTITLE") % translated_enemy_name


func _play_animation() -> void:
	bottom_bar.color.a = 0.0
	middle_band.color.a = 0.0
	top_bar.color.a = 0.0

	flash_rect.color.a = 0.0

	var initial_panel_position: Vector2 = silhouette_container.position + Vector2(0.0, PANEL_START_OFFSET_Y)
	silhouette_container.position = initial_panel_position
	silhouette_rect.scale = Vector2.ZERO

	modulate = Color(1.0, 1.0, 1.0, 0.0)
	background_rect.color = Color(0.0, 0.0, 0.0, 0.0)
	visible = true

	var bars_in_tween: Tween = create_tween().set_parallel(true)
	bars_in_tween.tween_property(top_bar, "color:a", 0.95, BAR_ANIM_DURATION)
	bars_in_tween.tween_property(bottom_bar, "color:a", 0.95, BAR_ANIM_DURATION)
	bars_in_tween.tween_property(middle_band, "color:a", 0.95, BAR_ANIM_DURATION)

	var flash_tween: Tween = create_tween().set_parallel(true)
	flash_tween.tween_property(flash_rect, "color:a", 0.95, FLASH_DURATION * 0.5)
	flash_tween.tween_property(flash_rect, "color:a", 0.0, FLASH_DURATION).set_delay(FLASH_DURATION * 0.5)

	var intro_tween: Tween = create_tween().set_parallel(true)
	intro_tween.tween_property(self, "modulate:a", 1.0, TITLE_ANIM_DURATION)
	intro_tween.tween_property(background_rect, "color:a", BACKGROUND_TARGET_ALPHA, TITLE_ANIM_DURATION)
	intro_tween.tween_property(silhouette_container, "position", initial_panel_position - Vector2(0.0, PANEL_START_OFFSET_Y), 0.55).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	intro_tween.tween_property(silhouette_rect, "scale", Vector2.ONE * SILHOUETTE_SCALE_MULTIPLIER, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await intro_tween.finished

	await get_tree().create_timer(HOLD_DURATION).timeout
	_is_waiting_for_continue = true
	await _wait_for_continue_input()
	_is_waiting_for_continue = false

	var outro_tween: Tween = create_tween().set_parallel(true)
	outro_tween.tween_property(self, "modulate:a", 0.0, OUTRO_DURATION)
	outro_tween.tween_property(background_rect, "color:a", 0.0, OUTRO_DURATION)
	outro_tween.tween_property(top_bar, "color:a", 0.0, OUTRO_DURATION)
	outro_tween.tween_property(bottom_bar, "color:a", 0.0, OUTRO_DURATION)
	outro_tween.tween_property(middle_band, "color:a", 0.0, OUTRO_DURATION)
	await outro_tween.finished
	visible = false


func _input(event: InputEvent) -> void:
	if not visible or not _is_waiting_for_continue:
		return
	if event is InputEventMouseButton and event.pressed:
		_is_waiting_for_continue = false
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_accept"):
		_is_waiting_for_continue = false
		get_viewport().set_input_as_handled()


func _wait_for_continue_input() -> void:
	while _is_waiting_for_continue:
		await get_tree().process_frame


func _get_silhouette_material() -> ShaderMaterial:
	if _silhouette_material != null:
		return _silhouette_material
	_silhouette_material = ShaderMaterial.new()
	_silhouette_material.shader = FLAT_ALPHA_TINT_SHADER
	_silhouette_material.set_shader_parameter("tint_color", Color(0.0, 0.0, 0.0, 1.0))
	return _silhouette_material
