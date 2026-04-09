## © [2026] A7 Studio. All rights reserved. Trademark.

class_name NewEnemyChallenger
extends Control
## Fullscreen reveal shown when a new enemy type is discovered.

signal reveal_finished

# Constants
const BAR_ANIM_DURATION: float = 0.2
const FLASH_DURATION: float = 0.1
const FLAT_ALPHA_TINT_SHADER: Shader = preload("res://assets/resources/shaders/flat_alpha_tint.gdshader")
const HOLD_DURATION: float = 1.8
const AURA_ALPHA: float = 0.9
const AURA_SCALE_MULTIPLIER: float = 1.18
const MAX_AURA_CENTER_OFFSET_UV: float = 0.04
const OUTRO_DURATION: float = 0.3
const PANEL_START_OFFSET_Y: float = 110.0
const SILHOUETTE_SCALE_MULTIPLIER: float = 1.16
const SLASH_DURATION: float = 0.18
const TITLE_ANIM_DURATION: float = 0.35

# Onready variables
@onready var background_rect: ColorRect = $Background
@onready var aura_rect: ColorRect = %AuraRect
@onready var bottom_bar: ColorRect = $BottomBar
@onready var center_slash: ColorRect = $CenterSlash
@onready var flash_rect: ColorRect = $FlashRect
@onready var reveal_vbox: VBoxContainer = $CenterContainer/RevealVBox
@onready var silhouette_container: Control = %SilhouetteContainer
@onready var silhouette_rect: TextureRect = %SilhouetteRect
@onready var subtitle_label: Label = %SubtitleLabel
@onready var top_bar: ColorRect = $TopBar
@onready var title_label: Label = %TitleLabel
@onready var continue_label: Label = %ContinueLabel

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
	aura_rect.scale = enemy_scale * AURA_SCALE_MULTIPLIER
	aura_rect.modulate = Color(1.0, 1.0, 1.0, AURA_ALPHA)
	_apply_aura_center_offset(texture)

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
	continue_label.text = tr("INGAMEHUD.NEW_ENEMY.CONTINUE")


func _play_animation() -> void:
	var original_bottom_top: float = bottom_bar.offset_top
	var original_top_bottom: float = top_bar.offset_bottom

	bottom_bar.offset_top = 0.0
	top_bar.offset_bottom = 0.0
	bottom_bar.color.a = 0.0
	top_bar.color.a = 0.0

	center_slash.scale = Vector2(0.0, 1.0)
	center_slash.color.a = 0.0

	flash_rect.color.a = 0.0
	continue_label.modulate.a = 0.0

	var initial_panel_position: Vector2 = silhouette_container.position + Vector2(0.0, PANEL_START_OFFSET_Y)
	silhouette_container.position = initial_panel_position
	aura_rect.scale = Vector2.ZERO
	aura_rect.modulate.a = 0.0
	silhouette_rect.scale = Vector2.ZERO

	modulate = Color(1.0, 1.0, 1.0, 0.0)
	background_rect.color = Color(0.0, 0.0, 0.0, 0.0)
	reveal_vbox.modulate.a = 0.0
	visible = true

	var bars_in_tween: Tween = create_tween().set_parallel(true)
	bars_in_tween.tween_property(top_bar, "offset_bottom", original_top_bottom, BAR_ANIM_DURATION).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	bars_in_tween.tween_property(bottom_bar, "offset_top", original_bottom_top, BAR_ANIM_DURATION).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	bars_in_tween.tween_property(top_bar, "color:a", 0.95, BAR_ANIM_DURATION)
	bars_in_tween.tween_property(bottom_bar, "color:a", 0.95, BAR_ANIM_DURATION)

	var flash_tween: Tween = create_tween().set_parallel(true)
	flash_tween.tween_property(flash_rect, "color:a", 0.95, FLASH_DURATION * 0.5)
	flash_tween.tween_property(flash_rect, "color:a", 0.0, FLASH_DURATION).set_delay(FLASH_DURATION * 0.5)

	var slash_tween: Tween = create_tween().set_parallel(true)
	slash_tween.tween_property(center_slash, "color:a", 1.0, SLASH_DURATION * 0.5)
	slash_tween.tween_property(center_slash, "scale:x", 1.0, SLASH_DURATION).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	slash_tween.tween_property(center_slash, "color:a", 0.0, SLASH_DURATION).set_delay(SLASH_DURATION * 0.5)

	var intro_tween: Tween = create_tween().set_parallel(true)
	intro_tween.tween_property(self, "modulate:a", 1.0, TITLE_ANIM_DURATION)
	intro_tween.tween_property(background_rect, "color:a", 0.88, TITLE_ANIM_DURATION)
	intro_tween.tween_property(reveal_vbox, "modulate:a", 1.0, TITLE_ANIM_DURATION).set_delay(0.05)
	intro_tween.tween_property(silhouette_container, "position", initial_panel_position - Vector2(0.0, PANEL_START_OFFSET_Y), 0.55).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	intro_tween.tween_property(aura_rect, "modulate:a", AURA_ALPHA, 0.3)
	intro_tween.tween_property(aura_rect, "scale", Vector2.ONE * AURA_SCALE_MULTIPLIER, 0.52).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	intro_tween.tween_property(silhouette_rect, "scale", Vector2.ONE * SILHOUETTE_SCALE_MULTIPLIER, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await intro_tween.finished

	await get_tree().create_timer(HOLD_DURATION).timeout
	_is_waiting_for_continue = true

	var continue_tween: Tween = create_tween().set_loops()
	continue_tween.tween_property(continue_label, "modulate:a", 1.0, 0.45)
	continue_tween.tween_property(continue_label, "modulate:a", 0.3, 0.45)
	await _wait_for_continue_input()
	_is_waiting_for_continue = false
	if is_instance_valid(continue_tween):
		continue_tween.kill()

	var outro_tween: Tween = create_tween().set_parallel(true)
	outro_tween.tween_property(self, "modulate:a", 0.0, OUTRO_DURATION)
	outro_tween.tween_property(background_rect, "color:a", 0.0, OUTRO_DURATION)
	outro_tween.tween_property(top_bar, "color:a", 0.0, OUTRO_DURATION)
	outro_tween.tween_property(bottom_bar, "color:a", 0.0, OUTRO_DURATION)
	outro_tween.tween_property(aura_rect, "modulate:a", 0.0, OUTRO_DURATION)
	outro_tween.tween_property(reveal_vbox, "modulate:a", 0.0, OUTRO_DURATION)
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


func _apply_aura_center_offset(texture: Texture2D) -> void:
	if texture == null:
		return
	if not (aura_rect.material is ShaderMaterial):
		return

	var image: Image = texture.get_image()
	if image == null or image.is_empty():
		return

	var width: int = image.get_width()
	var height: int = image.get_height()
	if width <= 0 or height <= 0:
		return

	var sum_x: float = 0.0
	var sum_y: float = 0.0
	var count: float = 0.0

	for y in range(height):
		for x in range(width):
			var alpha: float = image.get_pixel(x, y).a
			if alpha <= 0.02:
				continue
			sum_x += float(x) * alpha
			sum_y += float(y) * alpha
			count += alpha

	if count <= 0.0:
		return

	var center_x: float = sum_x / count
	var center_y: float = sum_y / count

	var offset_x_uv: float = clamp((center_x / float(width)) - 0.5, -MAX_AURA_CENTER_OFFSET_UV, MAX_AURA_CENTER_OFFSET_UV)
	var offset_y_uv: float = clamp((center_y / float(height)) - 0.5, -MAX_AURA_CENTER_OFFSET_UV, MAX_AURA_CENTER_OFFSET_UV)

	var shader_mat: ShaderMaterial = aura_rect.material as ShaderMaterial
	shader_mat.set_shader_parameter("center_offset", Vector2(offset_x_uv, offset_y_uv))
