## © [2026] A7 Studio. All rights reserved. Trademark.
##
## Project theme ([code]generic.tres[/code]): every variation the scenes and scripts pick exists with the right base, every size is a [code]TypeScale[/code]
## value, and no scene or script overrides fonts, sizes, colors or styles.
extends GdUnitTestSuite

const BUTTON_SCENE: PackedScene = preload("res://ui/components/game_button/game_button.tscn")
const BUTTON_TEXT_ROLES: Dictionary[StringName, StringName] = {
	&"ButtonTextHero": &"hero",
	&"ButtonTextLarge": &"title",
	&"ButtonTextMedium": &"body_large",
	&"ButtonTextSmall": &"small",
	&"ButtonTextWave": &"wave",
}
const FONT_COLOR_NAMES: Array[StringName] = [
	&"font_color", &"font_disabled_color", &"font_focus_color", &"font_hover_color", &"font_hover_pressed_color", &"font_pressed_color",
]
## Scripts allowed to set font overrides: [GameButton] copies the size and font of its [code]ButtonText*[/code] type.
const OVERRIDE_SCRIPTS: Array[String] = ["res://ui/components/game_button/game_button.gd"]
## Scene lines that must come from a theme variation instead.
const SCENE_FORBIDDEN_PREFIXES: Array[String] = [
	"theme = ",
	"theme_override_colors/",
	"theme_override_constants/line_spacing",
	"theme_override_constants/outline_size",
	"theme_override_constants/shadow_",
	"theme_override_font_sizes/",
	"theme_override_fonts/",
	"theme_override_styles/",
]
const SCANNED_DIRS: Array[String] = ["res://game", "res://ui"]
## Script calls and property names that override the theme: fonts, sizes, colors and styles, and the outline, line spacing and shadow constants.
const SCRIPT_FORBIDDEN_PATTERN: String = r'add_theme_(font|font_size|color|stylebox)_override|add_theme_constant_override\(\s*&?"(outline_size|line_spacing|shadow_\w+)"|theme_override_(colors|fonts|font_sizes|styles)/|theme_override_constants/(outline_size|line_spacing|shadow_)'
const STYLES_DIR: String = "res://ui/theme/styles"

var _theme: Theme = ThemeDB.get_project_theme()


func test_every_variation_picked_by_a_scene_or_a_script_exists() -> void:
	var used: Dictionary[String, String] = {}
	for extension: String in [".tscn", ".tres", ".gd"]:
		for path: String in _files(extension):
			for variation: String in _variations_in(FileAccess.get_file_as_string(path), extension == ".gd"):
				used[variation] = path

	assert_int(used.size()).is_greater(30)
	for name: StringName in GameButton.VARIATIONS + GameButton.INVERSE_VARIATIONS + ChallengeCard.DIFFICULTY_VARIATIONS.values():
		assert_bool(used.has(name)).override_failure_message("%s is not found by the variation scan" % name).is_true()
	for variation: String in used:
		assert_bool(_theme.get_type_variation_base(variation) != &"").override_failure_message("%s (%s) is not a variation of the project theme" % [variation, used[variation]]).is_true()
	for style: StringName in GameButton.TEXT_STYLES.slice(1):
		assert_bool(style in _theme.get_font_size_type_list()).override_failure_message("%s is not a type of the project theme" % style).is_true()


func test_every_variation_ends_on_the_expected_native_type() -> void:
	var variations: int = 0
	for type: String in _theme.get_type_list():
		if _theme.get_type_variation_base(type) == &"":
			continue
		variations += 1
		var native: StringName = _theme.get_type_variation_base(type)
		while _theme.get_type_variation_base(native) != &"":
			native = _theme.get_type_variation_base(native)
		assert_str(native).override_failure_message("%s ends on %s" % [type, native]).is_equal(_expected_native(type))
	assert_int(variations).is_greater(60)


func test_every_font_size_of_the_theme_is_a_type_scale_value() -> void:
	var scale: Dictionary[String, int] = {}
	for role: String in _theme.get_font_size_list(&"TypeScale"):
		scale[role] = _theme.get_font_size(role, &"TypeScale")
	assert_int(scale.size()).is_equal(12)
	assert_int(_theme.default_font_size).is_equal(scale["title"])

	for type: String in _theme.get_font_size_type_list():
		if type == "TypeScale":
			continue
		for font_size_name: String in _theme.get_font_size_list(type):
			var value: int = _theme.get_font_size(font_size_name, type)
			assert_bool(value in scale.values()).override_failure_message("%s/%s = %d is not a TypeScale value" % [type, font_size_name, value]).is_true()
	for type: StringName in BUTTON_TEXT_ROLES:
		assert_int(_theme.get_font_size(&"font_size", type)).is_equal(scale[BUTTON_TEXT_ROLES[type]])


func test_every_inverse_variation_is_white_through_the_nested_chain_on_a_live_button() -> void:
	for shape: GameButton.Shape in GameButton.Shape.values():
		assert_str(_theme.get_type_variation_base(GameButton.INVERSE_VARIATIONS[shape])).is_equal(GameButton.VARIATIONS[shape])
		for color_name: StringName in FONT_COLOR_NAMES:
			assert_that(_theme.get_color(color_name, GameButton.INVERSE_VARIATIONS[shape])).is_equal(Color.WHITE)

		var button: GameButton = auto_free(BUTTON_SCENE.instantiate())
		button.shape = shape
		button.palette = GameButton.Palette.RED
		add_child(button)
		await await_idle_frame()
		await await_idle_frame()
		assert_str(button.theme_type_variation).is_equal(GameButton.INVERSE_VARIATIONS[shape])
		for color_name: StringName in FONT_COLOR_NAMES:
			assert_that(button.get_theme_color(color_name)).is_equal(Color.WHITE)


func test_the_glyph_ink_is_the_font_color_of_the_rect_variation() -> void:
	assert_str(_theme.get_color(&"font_color", &"GameButtonRect").to_html()).is_equal(GameButton.INK.to_html())


func test_no_scene_overrides_fonts_sizes_colors_or_styles() -> void:
	for path: String in _files(".tscn"):
		for line: String in FileAccess.get_file_as_string(path).split("\n"):
			for prefix: String in SCENE_FORBIDDEN_PREFIXES:
				assert_bool(line.begins_with(prefix)).override_failure_message("%s: %s" % [path, line]).is_false()


func test_no_script_overrides_fonts_sizes_colors_or_styles_but_the_game_button() -> void:
	for path: String in _files(".gd"):
		if path in OVERRIDE_SCRIPTS:
			continue
		assert_bool(_overrides_theme(FileAccess.get_file_as_string(path))).override_failure_message("%s overrides the theme" % path).is_false()


func test_the_script_guard_catches_every_override_form() -> void:
	var forbidden: Array[String] = [
		'label.add_theme_font_override(&"font", font)',
		'label.add_theme_font_size_override(&"font_size", 12)',
		'label.add_theme_color_override(&"font_color", Color.RED)',
		'panel.add_theme_stylebox_override(&"panel", style)',
		'label.add_theme_constant_override(&"outline_size", 4)',
		'label.add_theme_constant_override("line_spacing", 4)',
		'label.add_theme_constant_override(&"shadow_offset_x", 2)',
		'label.set("theme_override_colors/font_color", Color.RED)',
		'label.set("theme_override_fonts/font", font)',
		'label.set("theme_override_font_sizes/font_size", 12)',
		'panel.set("theme_override_styles/panel", style)',
		'label.set("theme_override_constants/outline_size", 4)',
	]
	for source: String in forbidden:
		assert_bool(_overrides_theme(source)).override_failure_message(source).is_true()
	assert_bool(_overrides_theme('box.add_theme_constant_override(&"separation", 4)\nlabel.theme_type_variation = &"BodyText"')).is_false()


func test_the_variation_scan_reads_inline_and_multiline_names() -> void:
	var script: String = 'const A_VARIATIONS: Array[StringName] = [\n\t&"First",\n\t&"Second",\n]\nconst B_VARIATION: Dictionary[int, StringName] = {\n\t0: &"Third",\n}\nlabel.theme_type_variation = &"Fourth" if x else &"Fifth"\nvar other: Array[StringName] = [&"Ignored"]'

	assert_array(_variations_in(script, true)).contains_exactly_in_any_order(["First", "Second", "Third", "Fourth", "Fifth"])
	assert_array(_variations_in('theme_type_variation = &"Sixth"', false)).contains_exactly(["Sixth"])


func test_the_style_resources_load_with_their_textures() -> void:
	var count: int = 0
	for file: String in DirAccess.get_files_at(STYLES_DIR):
		if file.get_extension() != "tres":
			continue
		count += 1
		var style: StyleBox = load(STYLES_DIR.path_join(file)) as StyleBox
		assert_object(style).override_failure_message("%s does not load" % file).is_not_null()
		if style is StyleBoxTexture:
			assert_object((style as StyleBoxTexture).texture).override_failure_message("%s has no texture" % file).is_not_null()
	assert_int(count).is_equal(9)


## Returns the native type a variation of the theme must end on.
func _expected_native(variation: String) -> String:
	if variation.begins_with("GameButton") or variation == "DebugButton":
		return "Button"
	if variation.begins_with("HealthBar"):
		return "Panel"
	if variation.begins_with("BookStatsGrid"):
		return "GridContainer"
	if variation in ["BookStatRow", "ChallengeLine"]:
		return "HBoxContainer"
	if variation in ["CardTitleTag", "LevelPanel", "MenuPanel", "MenuPanelDark", "MenuPanelSliced"]:
		return "PanelContainer"
	return "Label"


## Returns true when [param source] overrides a font, size, color, style, outline, line spacing or shadow of the theme, with a call or a [code]theme_override_*[/code] property name.
func _overrides_theme(source: String) -> bool:
	return RegEx.create_from_string(SCRIPT_FORBIDDEN_PATTERN).search(source) != null


## Returns the variation names set in [param source]: [code]theme_type_variation = &"Name"[/code] in scenes and resources, and in scripts the names of
## every line mentioning a variation plus the whole body of every [code]const[/code] whose name contains [code]VARIATION[/code] (multiline arrays and dictionaries).
func _variations_in(source: String, is_script: bool) -> Array[String]:
	var found: Array[String] = []
	var token_regex: RegEx = RegEx.create_from_string(r'&"(\w+)"')
	if not is_script:
		for match: RegExMatch in RegEx.create_from_string(r'theme_type_variation = &"(\w+)"').search_all(source):
			found.append(match.get_string(1))
		return found
	var blocks: Array[String] = []
	for match: RegExMatch in RegEx.create_from_string(r"const\s+\w*VARIATION\w*[^=\n]*=\s*(\[[^\]]*\]|\{[^}]*\})").search_all(source):
		blocks.append(match.get_string(1))
	for line: String in source.split("\n"):
		if line.to_lower().contains("variation") and not line.contains("get_theme") and not line.begins_with("const"):
			blocks.append(line)
	for block: String in blocks:
		for match: RegExMatch in token_regex.search_all(block):
			if match.get_string(1) not in found:
				found.append(match.get_string(1))
	return found


## Returns every file with the extension [param extension] under [constant SCANNED_DIRS].
func _files(extension: String) -> Array[String]:
	var found: Array[String] = []
	for dir: String in SCANNED_DIRS:
		_collect(dir, extension, found)
	return found


func _collect(dir: String, extension: String, found: Array[String]) -> void:
	for file: String in DirAccess.get_files_at(dir):
		if file.get_extension() == extension.trim_prefix("."):
			found.append(dir.path_join(file))
	for sub_dir: String in DirAccess.get_directories_at(dir):
		_collect(dir.path_join(sub_dir), extension, found)
