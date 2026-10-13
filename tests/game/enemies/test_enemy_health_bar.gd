## © [2026] A7 Studio. All rights reserved. Trademark.
##
## The health bar shows up on a hit, stays visible for a while and fades to a half visible bar.
## [br]The fade tween is stepped by hand, so that the test does not wait for the real delays.
extends GdUnitTestSuite

const BAR_SCENE: PackedScene = preload("res://game/enemies/health_bar.tscn")


func test_a_hit_fades_the_bar_in_then_out_after_the_delay() -> void:
	var bar: EnemyHealthBar = _add_bar()
	assert_float(bar.modulate.a).is_equal(0.0)

	bar.update_health(50.0, 100.0)
	var fade: Tween = _hold(bar)
	fade.custom_step(EnemyHealthBar.FADE_IN_DURATION)
	assert_float(bar.modulate.a).is_equal_approx(1.0, 0.001)

	# The bar stays fully visible until FADE_DELAY after the hit
	fade.custom_step(EnemyHealthBar.FADE_DELAY - EnemyHealthBar.FADE_IN_DURATION - 0.5)
	assert_float(bar.modulate.a).is_equal_approx(1.0, 0.001)

	fade.custom_step(0.5 + EnemyHealthBar.FADE_DURATION)
	assert_float(bar.modulate.a).is_equal_approx(EnemyHealthBar.FADE_ALPHA, 0.001)
	assert_bool(fade.is_running()).is_false()


func test_a_new_hit_restarts_the_sequence() -> void:
	var bar: EnemyHealthBar = _add_bar()
	bar.update_health(50.0, 100.0)
	var first_fade: Tween = _hold(bar)
	first_fade.custom_step(EnemyHealthBar.FADE_DELAY + EnemyHealthBar.FADE_DURATION)
	assert_float(bar.modulate.a).is_equal_approx(EnemyHealthBar.FADE_ALPHA, 0.001)

	bar.update_health(40.0, 100.0)
	var second_fade: Tween = _hold(bar)
	assert_bool(second_fade == first_fade).is_false()
	second_fade.custom_step(EnemyHealthBar.FADE_IN_DURATION)
	assert_float(bar.modulate.a).is_equal_approx(1.0, 0.001)


func test_the_panels_take_their_style_from_the_theme_variations() -> void:
	var bar: EnemyHealthBar = _add_bar()

	assert_str(bar.background.theme_type_variation).is_equal(&"HealthBarBackground")
	assert_str(bar.fill.theme_type_variation).is_equal(&"HealthBarFill")
	assert_str(bar.border.theme_type_variation).is_equal(&"HealthBarBorder")
	assert_bool(bar.fill.has_theme_stylebox_override(&"panel")).is_false()
	assert_that(bar.fill.self_modulate).is_equal(EnemyHealthBar.COLOR_FULL)


func test_the_fill_is_tinted_by_the_health_without_a_style_per_bar() -> void:
	var bar: EnemyHealthBar = _add_bar()
	var other: EnemyHealthBar = _add_bar()

	bar.update_health(10.0, 100.0)
	other.update_health(100.0, 100.0)

	assert_that(bar.fill.self_modulate).is_equal(bar._get_health_color(0.1))
	assert_that(other.fill.self_modulate).is_equal(EnemyHealthBar.COLOR_FULL)
	assert_float(bar.fill.size.x).is_equal_approx(EnemyHealthBar.MAX_WIDTH * 0.1, 0.001)
	assert_bool(bar.fill.has_theme_stylebox_override(&"panel")).is_false()


func _add_bar() -> EnemyHealthBar:
	var bar: EnemyHealthBar = auto_free(BAR_SCENE.instantiate())
	add_child(bar)
	return bar


## Returns the fade tween of [param bar], paused so that only [method Tween.custom_step] moves it.
func _hold(bar: EnemyHealthBar) -> Tween:
	var fade: Tween = bar._fade_tween
	fade.pause()
	return fade
