## © [2026] A7 Studio. All rights reserved. Trademark.

class_name NewEnemyChallenger
extends Control
## Fullscreen reveal shown when a new enemy type is discovered.

signal reveal_finished

# Constants
const BAR_ANIM_DURATION: float = 0.42
const BACKGROUND_TARGET_ALPHA: float = 0.4
const FLASH_DURATION: float = 0.1
const FLAT_ALPHA_TINT_SHADER: Shader = preload("res://assets/resources/shaders/flat_alpha_tint.gdshader")
const REVEAL_ACCEL_DURATION: float = 1.35
const REVEAL_DECEL_DURATION: float = 1.8
const REVEAL_BOOST_DURATION: float = REVEAL_ACCEL_DURATION + REVEAL_DECEL_DURATION
const PRE_REVEAL_DELAY: float = 1.1
const REVEAL_WOW_ROTATION_SPEED: float = 2.2
const SLIDE_DISTANCE_MULTIPLIER: float = 1.2
const OUTRO_DURATION: float = 0.3
const AURA_POST_DISCOVER_SCALE: float = 1.0
const AURA_PRE_DISCOVER_SCALE: float = 1.0
const PANEL_START_OFFSET_Y: float = 110.0
const TEXT_SLIDE_DISTANCE: float = 300.0
const TITLE_ANIM_DURATION: float = 0.5
const TEXT_OUTRO_DURATION: float = 0.42

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
var _is_waiting_for_reveal_click: bool = false
var _is_waiting_for_continue: bool = false
var _cached_subtitle_final_pos: Vector2 = Vector2.ZERO
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
func apply_silhouette(texture: Texture2D, _enemy_scale: Vector2 = Vector2.ONE) -> void:
	silhouette_rect.texture = texture
	silhouette_rect.modulate = Color.WHITE
	silhouette_rect.material = _get_silhouette_material()
	_silhouette_material.set_shader_parameter("tint_color", Color(0.0, 0.0, 0.0, 1.0))


# Private functions
func _apply_texts(enemy_id: String) -> void:
	title_label.text = tr("INGAMEHUD.NEW_ENEMY.TITLE")
	var translated_enemy_name: String = tr("ENEMY.%s.NAME" % enemy_id.to_upper())
	if translated_enemy_name == "ENEMY.%s.NAME" % enemy_id.to_upper():
		translated_enemy_name = enemy_id.replace("_", " ").capitalize()
	subtitle_label.text = tr("INGAMEHUD.NEW_ENEMY.SUBTITLE") % translated_enemy_name


func _play_animation() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	var slide_distance: float = viewport_size.x * SLIDE_DISTANCE_MULTIPLIER

	var top_bar_final_pos: Vector2 = top_bar.position
	var bottom_bar_final_pos: Vector2 = bottom_bar.position
	var title_final_pos: Vector2 = title_label.position
	var subtitle_final_pos: Vector2 = subtitle_label.position
	_cached_subtitle_final_pos = subtitle_final_pos
	var silhouette_final_pos: Vector2 = silhouette_container.position
	var aura_target_alpha: float = aura_rect.modulate.a if aura_rect.modulate.a > 0.0 else 1.0

	# Step 1: full black screen.
	modulate = Color.WHITE
	background_rect.color = Color(0.0, 0.0, 0.0, 1.0)
	flash_rect.color.a = 0.0
	visible = true

	# Prepare start states.
	top_bar.position = top_bar_final_pos + Vector2(slide_distance, 0.0)
	bottom_bar.position = bottom_bar_final_pos - Vector2(slide_distance, 0.0)
	top_bar.color.a = 0.95
	bottom_bar.color.a = 0.95
	middle_band.color.a = 0.0

	title_label.position = title_final_pos + Vector2(TEXT_SLIDE_DISTANCE, 0.0)
	title_label.modulate.a = 0.0
	subtitle_label.position = subtitle_final_pos - Vector2(TEXT_SLIDE_DISTANCE, 0.0)
	subtitle_label.modulate.a = 0.0

	silhouette_container.position = silhouette_final_pos + Vector2(0.0, PANEL_START_OFFSET_Y)
	aura_rect.scale = Vector2.ONE * AURA_PRE_DISCOVER_SCALE
	aura_rect.modulate.a = 0.0

	# Step 2: red bars slide in (top from right, bottom from left).
	var bars_slide_tween: Tween = create_tween().set_parallel(true)
	bars_slide_tween.tween_property(top_bar, "position", top_bar_final_pos, BAR_ANIM_DURATION + 0.18).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	bars_slide_tween.tween_property(bottom_bar, "position", bottom_bar_final_pos, BAR_ANIM_DURATION + 0.18).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	bars_slide_tween.tween_property(middle_band, "color:a", 0.95, BAR_ANIM_DURATION + 0.1)
	bars_slide_tween.tween_property(background_rect, "color:a", BACKGROUND_TARGET_ALPHA, BAR_ANIM_DURATION + 0.18)
	await bars_slide_tween.finished

	# Step 3: top text from right.
	var top_text_tween: Tween = create_tween().set_parallel(true)
	top_text_tween.tween_property(title_label, "position", title_final_pos, TITLE_ANIM_DURATION).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	top_text_tween.tween_property(title_label, "modulate:a", 1.0, TITLE_ANIM_DURATION)
	await top_text_tween.finished

	# Step 4: bottom text from left + silhouette/aura appear.
	var bottom_and_reveal_tween: Tween = create_tween().set_parallel(true)
	bottom_and_reveal_tween.tween_property(silhouette_container, "position", silhouette_final_pos, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	bottom_and_reveal_tween.tween_property(aura_rect, "modulate:a", aura_target_alpha, 0.35)
	await bottom_and_reveal_tween.finished

	# After a short hold, shake the silhouette then reveal the real sprite colors.
	await get_tree().create_timer(PRE_REVEAL_DELAY).timeout
	_is_waiting_for_reveal_click = true
	await _wait_for_reveal_click()
	_is_waiting_for_reveal_click = false
	await _reveal_enemy_sprite()
	_is_waiting_for_continue = true
	await _wait_for_continue_input()
	_is_waiting_for_continue = false

	# Reverse order of arrival:
	# 1) bottom text + silhouette/aura leave
	var step4_out_tween: Tween = create_tween().set_parallel(true)
	step4_out_tween.tween_property(subtitle_label, "position", subtitle_final_pos - Vector2(TEXT_SLIDE_DISTANCE, 0.0), TEXT_OUTRO_DURATION).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	step4_out_tween.tween_property(subtitle_label, "modulate:a", 0.0, TEXT_OUTRO_DURATION)
	step4_out_tween.tween_property(silhouette_container, "position", silhouette_final_pos + Vector2(0.0, PANEL_START_OFFSET_Y), 0.32).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	step4_out_tween.tween_property(aura_rect, "modulate:a", 0.0, 0.22)
	await step4_out_tween.finished

	# 2) top text leaves
	var step3_out_tween: Tween = create_tween().set_parallel(true)
	step3_out_tween.tween_property(title_label, "position", title_final_pos + Vector2(TEXT_SLIDE_DISTANCE, 0.0), TEXT_OUTRO_DURATION).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	step3_out_tween.tween_property(title_label, "modulate:a", 0.0, TEXT_OUTRO_DURATION)
	await step3_out_tween.finished

	# 3) bars slide out opposite to their entry + black fade out
	var step2_out_tween: Tween = create_tween().set_parallel(true)
	step2_out_tween.tween_property(top_bar, "position", top_bar_final_pos + Vector2(slide_distance, 0.0), BAR_ANIM_DURATION + 0.18).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	step2_out_tween.tween_property(bottom_bar, "position", bottom_bar_final_pos - Vector2(slide_distance, 0.0), BAR_ANIM_DURATION + 0.18).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	step2_out_tween.tween_property(middle_band, "color:a", 0.0, BAR_ANIM_DURATION + 0.1)
	step2_out_tween.tween_property(top_bar, "color:a", 0.0, BAR_ANIM_DURATION + 0.1)
	step2_out_tween.tween_property(bottom_bar, "color:a", 0.0, BAR_ANIM_DURATION + 0.1)
	step2_out_tween.tween_property(background_rect, "color:a", 0.0, OUTRO_DURATION)
	await step2_out_tween.finished

	var final_fade: Tween = create_tween()
	final_fade.tween_property(self, "modulate:a", 0.0, 0.08)
	await final_fade.finished
	visible = false


func _input(event: InputEvent) -> void:
	if not visible:
		return
	var is_press_event: bool = false
	if event is InputEventMouseButton and event.pressed:
		is_press_event = true
	elif event.is_action_pressed("ui_accept"):
		is_press_event = true

	if not is_press_event:
		return

	if _is_waiting_for_reveal_click:
		_is_waiting_for_reveal_click = false
		get_viewport().set_input_as_handled()
		return

	if _is_waiting_for_continue:
		_is_waiting_for_continue = false
		get_viewport().set_input_as_handled()


func _wait_for_continue_input() -> void:
	while _is_waiting_for_continue:
		await get_tree().process_frame


func _wait_for_reveal_click() -> void:
	while _is_waiting_for_reveal_click:
		await get_tree().process_frame


func _reveal_enemy_sprite() -> void:
	await _play_discovery_boost()
	silhouette_rect.material = null
	var aura_scale_tween: Tween = create_tween()
	aura_scale_tween.tween_property(aura_rect, "scale", Vector2.ONE * AURA_POST_DISCOVER_SCALE, 0.24).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	var subtitle_in_tween: Tween = create_tween().set_parallel(true)
	subtitle_in_tween.tween_property(subtitle_label, "position", _cached_subtitle_final_pos, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	subtitle_in_tween.tween_property(subtitle_label, "modulate:a", 1.0, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await subtitle_in_tween.finished


func _get_silhouette_material() -> ShaderMaterial:
	if _silhouette_material != null:
		return _silhouette_material
	_silhouette_material = ShaderMaterial.new()
	_silhouette_material.shader = FLAT_ALPHA_TINT_SHADER
	_silhouette_material.set_shader_parameter("tint_color", Color(0.0, 0.0, 0.0, 1.0))
	return _silhouette_material


func _play_discovery_boost() -> void:
	if not (aura_rect.material is ShaderMaterial):
		return
	var shader_mat: ShaderMaterial = aura_rect.material as ShaderMaterial
	var base_speed: float = float(shader_mat.get_shader_parameter("ray_rotation_speed"))
	var base_intensity: float = float(shader_mat.get_shader_parameter("intensity"))
	var base_color: Color = shader_mat.get_shader_parameter("aura_color") as Color
	var target_color: Color = Color(1.0, 1.0, 1.0, 0.92)
	var direction: float = 1.0 if base_speed >= 0.0 else -1.0
	var target_peak_speed: float = direction * absf(REVEAL_WOW_ROTATION_SPEED)
	var silhouette_mat: ShaderMaterial = _get_silhouette_material()
	var boost_tween: Tween = create_tween()
	boost_tween.tween_method(
		func(progress: float) -> void:
			# Single smooth hump: base -> peak -> base.
			var hump: float = sin(progress * PI)
			shader_mat.set_shader_parameter("ray_rotation_speed", lerpf(base_speed, target_peak_speed, hump))
			var color_t: float = min(progress / 0.55, 1.0)
			shader_mat.set_shader_parameter("aura_color", base_color.lerp(target_color, color_t))
			shader_mat.set_shader_parameter("intensity", lerpf(base_intensity, 1.18, color_t))
			silhouette_mat.set_shader_parameter("tint_color", Color(color_t, color_t, color_t, 1.0)),
		0.0,
		1.0,
		REVEAL_BOOST_DURATION
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await boost_tween.finished

	shader_mat.set_shader_parameter("aura_color", target_color)
	shader_mat.set_shader_parameter("intensity", 1.18)
	silhouette_mat.set_shader_parameter("tint_color", Color(1.0, 1.0, 1.0, 1.0))
