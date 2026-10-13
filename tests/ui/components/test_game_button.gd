## © [2026] A7 Studio. All rights reserved. Trademark.
##
## [GameButton]: base, margins, theme variation and palette row of every shape x palette, state looks and toggle swaps.
extends GdUnitTestSuite

const BUTTON_SCENE: PackedScene = preload("res://ui/components/game_button/game_button.tscn")
const PALETTE_TEXTURE: Texture2D = preload("res://assets/ui/buttons/palette.png")


func test_every_shape_and_palette_builds() -> void:
	var buttons: Array[GameButton] = []
	for shape: GameButton.Shape in GameButton.Shape.values():
		for palette: GameButton.Palette in GameButton.Palette.values():
			buttons.append(_add(_button(shape, palette)))

	await await_idle_frame()

	for button: GameButton in buttons:
		_assert_built(button, button.shape, button.palette)


func test_changing_the_shape_after_ready_rebuilds_the_background() -> void:
	var button: GameButton = _add(_button(GameButton.Shape.RECT, GameButton.Palette.BLUE))

	button.shape = GameButton.Shape.HEXA
	await await_idle_frame()
	_assert_built(button, GameButton.Shape.HEXA, GameButton.Palette.BLUE)

	button.shape = GameButton.Shape.NONE
	await await_idle_frame()
	_assert_built(button, GameButton.Shape.NONE, GameButton.Palette.BLUE)

	button.shape = GameButton.Shape.BANNER
	button.palette = GameButton.Palette.SAND
	await await_idle_frame()
	_assert_built(button, GameButton.Shape.BANNER, GameButton.Palette.SAND)


func test_none_shape_hides_the_background() -> void:
	var button: GameButton = _add(_button(GameButton.Shape.NONE, GameButton.Palette.BLUE))

	assert_bool(_background(button).visible).is_false()
	assert_bool(_background(_add(_button(GameButton.Shape.RECT, GameButton.Palette.BLUE))).visible).is_true()


func test_palette_png_has_one_row_per_palette() -> void:
	assert_int(PALETTE_TEXTURE.get_height()).is_equal(GameButton.Palette.size())
	assert_int(PALETTE_TEXTURE.get_width()).is_equal(13)


func test_every_button_has_its_own_material() -> void:
	var first: GameButton = _add(_button(GameButton.Shape.RECT, GameButton.Palette.BLUE))
	var second: GameButton = _add(_button(GameButton.Shape.RECT, GameButton.Palette.BLUE))
	second.palette = GameButton.Palette.RED

	await await_idle_frame()

	assert_object(_background(first).material).is_not_same(_background(second).material)
	assert_int(_row(first)).is_equal(GameButton.Palette.BLUE)
	assert_int(_row(second)).is_equal(GameButton.Palette.RED)


func test_toggle_swaps_icon_and_palette_with_button_pressed() -> void:
	var button: GameButton = _toggle()

	await await_idle_frame()
	assert_int(button.get_effective_icon()).is_equal(GameIcon.Id.BUILD)
	assert_int(_row(button)).is_equal(GameButton.Palette.GREEN)

	button.button_pressed = true
	await await_idle_frame()
	assert_int(button.get_effective_icon()).is_equal(GameIcon.Id.CLOSE)
	assert_int(button.get_effective_palette()).is_equal(GameButton.Palette.RED)
	assert_int(_row(button)).is_equal(GameButton.Palette.RED)

	button.button_pressed = false
	await await_idle_frame()
	assert_int(button.get_effective_icon()).is_equal(GameIcon.Id.BUILD)
	assert_int(_row(button)).is_equal(GameButton.Palette.GREEN)


func test_toggle_swaps_with_set_pressed_no_signal() -> void:
	var button: GameButton = _toggle()
	var toggled_count: Array[int] = [0]
	SignalUtil.connects([{SignalUtil.WHO: button, SignalUtil.WHAT: "toggled", SignalUtil.TO: func(_pressed: bool) -> void: toggled_count[0] += 1}])

	button.set_pressed_no_signal(true)
	await await_idle_frame()
	assert_int(button.get_effective_icon()).is_equal(GameIcon.Id.CLOSE)
	assert_int(_row(button)).is_equal(GameButton.Palette.RED)

	button.set_pressed_no_signal(false)
	await await_idle_frame()
	assert_int(button.get_effective_icon()).is_equal(GameIcon.Id.BUILD)
	assert_int(_row(button)).is_equal(GameButton.Palette.GREEN)
	assert_int(toggled_count[0]).is_equal(0)


func test_pressed_values_left_unset_keep_the_normal_ones() -> void:
	var button: GameButton = _add(_button(GameButton.Shape.RECT, GameButton.Palette.ORANGE))
	button.game_icon = GameIcon.Id.HOME
	button.toggle_mode = true

	button.set_pressed_no_signal(true)
	await await_idle_frame()

	assert_int(button.get_effective_icon()).is_equal(GameIcon.Id.HOME)
	assert_int(_row(button)).is_equal(GameButton.Palette.ORANGE)


func test_disabled_removes_the_saturation() -> void:
	var button: GameButton = _add(_button(GameButton.Shape.PANEL, GameButton.Palette.GREEN))

	await await_idle_frame()
	assert_float(_parameter(button, &"saturation")).is_equal(1.0)

	button.disabled = true
	await await_idle_frame()
	assert_float(_parameter(button, &"saturation")).is_equal(0.0)
	assert_int(_row(button)).is_equal(GameButton.Palette.GREEN)

	button.disabled = false
	await await_idle_frame()
	assert_float(_parameter(button, &"saturation")).is_equal(1.0)


func test_hover_brightens_and_pressed_darkens() -> void:
	var button: GameButton = _add(_button(GameButton.Shape.RECT, GameButton.Palette.BLUE))
	button.toggle_mode = true

	await await_idle_frame()
	assert_float(_parameter(button, &"brightness")).is_equal(1.0)

	button.notification(Control.NOTIFICATION_MOUSE_ENTER)
	await await_idle_frame()
	assert_float(_parameter(button, &"brightness")).is_equal(GameButton.BRIGHTNESS_HOVER)

	button.notification(Control.NOTIFICATION_MOUSE_EXIT)
	button.set_pressed_no_signal(true)
	await await_idle_frame()
	assert_float(_parameter(button, &"brightness")).is_equal(GameButton.BRIGHTNESS_PRESSED)


func test_latched_toggle_with_a_swap_is_not_dimmed() -> void:
	var button: GameButton = _toggle()

	button.set_pressed_no_signal(true)
	await await_idle_frame()
	assert_float(_parameter(button, &"brightness")).is_equal(1.0)

	button.notification(Control.NOTIFICATION_MOUSE_ENTER)
	await await_idle_frame()
	assert_float(_parameter(button, &"brightness")).is_equal(GameButton.BRIGHTNESS_HOVER)


func test_icon_only_button_larger_than_its_base_scales_the_art_and_keeps_its_proportions() -> void:
	var button: GameButton = _add(_button(GameButton.Shape.RECT, GameButton.Palette.GREEN))
	button.game_icon = GameIcon.Id.HOME
	button.custom_minimum_size = Vector2(138, 117)
	button.size = Vector2(138, 117)

	await await_idle_frame()

	assert_float(button.art_scale).is_equal(3.0)
	assert_that(_background(button).scale).is_equal(Vector2(3, 3))
	assert_that(_background(button).size).is_equal(Vector2(46, 39))
	assert_that(_background(button).position).is_equal(Vector2.ZERO)

	button.size = Vector2(200, 117)
	await await_idle_frame()
	assert_float(button.art_scale).is_equal(3.0)
	assert_that(_background(button).position).is_equal(Vector2(31, 0))


func test_native_size_text_and_unscaled_shapes_stretch_their_base() -> void:
	var button: GameButton = _add(_button(GameButton.Shape.RECT, GameButton.Palette.GREEN))
	await await_idle_frame()
	assert_float(button.art_scale).is_equal(1.0)

	button.custom_minimum_size = Vector2(138, 117)
	button.size = Vector2(138, 117)
	button.text = "OK"
	await await_idle_frame()
	assert_float(button.art_scale).is_equal(1.0)
	assert_that(_background(button).size).is_equal(Vector2(138, 117))

	button.text = ""
	button.shape = GameButton.Shape.PANEL
	await await_idle_frame()
	assert_float(button.art_scale).is_equal(1.0)
	assert_that(_background(button).scale).is_equal(Vector2.ONE)


func test_glyph_is_dark_ink_except_on_red_and_for_multicolor_icons() -> void:
	var button: GameButton = _add(_button(GameButton.Shape.RECT, GameButton.Palette.BLUE))
	button.game_icon = GameIcon.Id.HOME

	await await_idle_frame()
	assert_that(button._glyph_color).is_equal(GameButton.INK)

	button.palette = GameButton.Palette.RED
	await await_idle_frame()
	assert_that(button._glyph_color).is_equal(Color.WHITE)

	button.palette = GameButton.Palette.GREEN
	button.game_icon = GameIcon.Id.FLAG_FR
	await await_idle_frame()
	assert_that(button._glyph_color).is_equal(Color.WHITE)


func test_tooltip_is_the_translated_glyph_name_unless_set() -> void:
	var button: GameButton = _add(_button(GameButton.Shape.RECT, GameButton.Palette.BLUE))

	assert_str(button.get_tooltip(Vector2.ZERO)).is_empty()

	button.game_icon = GameIcon.Id.HOME
	assert_str(button.get_tooltip(Vector2.ZERO)).is_equal(tr("BUTTON.HOME"))
	assert_str(tr("BUTTON.HOME")).is_not_equal("BUTTON.HOME")

	button.tooltip_text = "Custom"
	assert_str(button.get_tooltip(Vector2.ZERO)).is_equal("Custom")


func test_icon_only_button_is_named_for_accessibility() -> void:
	var button: GameButton = _add(_button(GameButton.Shape.RECT, GameButton.Palette.BLUE))
	button.game_icon = GameIcon.Id.SELL

	await await_idle_frame()

	assert_str(button.accessibility_name).is_equal(tr("BUTTON.SELL"))


func test_the_button_processes_while_the_tree_is_paused_unless_told_otherwise() -> void:
	var always: GameButton = _add(_button(GameButton.Shape.RECT, GameButton.Palette.BLUE))
	var stopping: GameButton = _button(GameButton.Shape.RECT, GameButton.Palette.BLUE)
	stopping.process_when_paused = false
	_add(stopping)

	assert_int(always.process_mode).is_equal(Node.PROCESS_MODE_ALWAYS)
	assert_int(stopping.process_mode).is_equal(Node.PROCESS_MODE_INHERIT)
	assert_bool(stopping.has_meta(ButtonEffects.APPLIED_META_KEY)).is_true()


func _add(button: GameButton) -> GameButton:
	add_child(auto_free(button))
	return button


func _assert_built(button: GameButton, shape: GameButton.Shape, palette: GameButton.Palette) -> void:
	var background: NinePatchRect = _background(button)
	assert_str(button.theme_type_variation).is_equal(GameButton.VARIATIONS[shape])
	assert_object(button.get_theme_stylebox(&"normal")).is_instanceof(StyleBoxEmpty)
	assert_str(ThemeDB.get_project_theme().get_type_variation_base(GameButton.VARIATIONS[shape])).is_equal("Button")
	assert_bool(background.visible).is_equal(shape != GameButton.Shape.NONE)
	assert_int(_row(button)).is_equal(palette)
	if shape == GameButton.Shape.NONE:
		return
	var margins: Vector4i = GameButton.MARGINS[shape]
	assert_object(background.texture).is_same(GameButton.BASES[shape])
	assert_array([background.patch_margin_left, background.patch_margin_top, background.patch_margin_right, background.patch_margin_bottom]).contains_exactly([margins.x, margins.y, margins.z, margins.w])
	assert_object(background.material).is_instanceof(ShaderMaterial)


func _background(button: GameButton) -> NinePatchRect:
	return button.get_node("%Background")


func _button(shape: GameButton.Shape, palette: GameButton.Palette) -> GameButton:
	var button: GameButton = BUTTON_SCENE.instantiate()
	button.shape = shape
	button.palette = palette
	return button


func _parameter(button: GameButton, parameter: StringName) -> Variant:
	return (_background(button).material as ShaderMaterial).get_shader_parameter(parameter)


func _row(button: GameButton) -> int:
	return _parameter(button, &"palette_row")


## Returns a toggle button that shows BUILD on GREEN and CLOSE on RED while pressed.
func _toggle() -> GameButton:
	var button: GameButton = _add(_button(GameButton.Shape.RECT, GameButton.Palette.GREEN))
	button.game_icon = GameIcon.Id.BUILD
	button.game_icon_pressed = GameIcon.Id.CLOSE
	button.palette_pressed = GameButton.Palette.RED
	button.toggle_mode = true
	return button
