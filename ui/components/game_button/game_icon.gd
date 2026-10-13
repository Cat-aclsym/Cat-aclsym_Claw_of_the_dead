## © [2026] A7 Studio. All rights reserved. Trademark.
##
## Glyph atlas of the [GameButton]s: one [AtlasTexture] per [enum Id], cut from [code]icons.png[/code] (8 columns of [constant CELL_SIZE] px cells).
## [br]The cells are drawn centered on the button. Single-color glyphs are stored white (shaded ones white and light grey) and tinted by the button,
## the [constant MULTICOLOR] ones keep their own colors.
## [codeblock]
## var home: AtlasTexture = GameIcon.texture(GameIcon.Id.HOME)
## [/codeblock]
@tool
class_name GameIcon
extends RefCounted

## Order = cell order in [code]icons.png[/code] (cell [code]id - 1[/code], row by row).
enum Id {
	NONE,
	HOME,
	PLAY,
	RETRY,
	PAUSE,
	FAST_FORWARD,
	MUSIC,
	MUSIC_OFF,
	SOUND,
	SOUND_OFF,
	ENCYCLOPEDIA,
	BUILD,
	CLOSE,
	TROPHY,
	SHIELD,
	REPORT,
	MAIL,
	INSTAGRAM,
	X_SOCIAL,
	DISCORD,
	FLAG_EN,
	FLAG_FR,
	BACK,
	INFO,
	UPGRADE,
	SELL,
	ARROW_LEFT,
	ARROW_RIGHT,
}

const ATLAS: Texture2D = preload("res://assets/ui/buttons/icons.png")
const CELL_SIZE: int = 64
const COLUMNS: int = 8
## Glyphs that keep their own colors: the button never tints them.
const MULTICOLOR: Array[Id] = [Id.FLAG_EN, Id.FLAG_FR, Id.ARROW_LEFT, Id.ARROW_RIGHT]
## Single-color glyphs drawn with a light grey (191) second tone besides the white: the tint multiplies both.
const SHADED: Array[Id] = [Id.PLAY, Id.PAUSE, Id.FAST_FORWARD, Id.CLOSE, Id.BACK]

static var _cache: Dictionary[int, AtlasTexture] = {}


## Returns [code]true[/code] if the glyph keeps its own colors.
static func is_multicolor(id: Id) -> bool:
	return id in MULTICOLOR


## Returns the name of [param id], the suffix of its [code]BUTTON.<ID>[/code] translation key.
static func key(id: Id) -> String:
	return Id.keys()[id] as String


## Returns the cell of [param id] in [constant ATLAS], in pixels.
@warning_ignore("integer_division")
static func region(id: Id) -> Rect2:
	var cell: int = id - 1
	return Rect2(cell % COLUMNS * CELL_SIZE, cell / COLUMNS * CELL_SIZE, CELL_SIZE, CELL_SIZE)


## Returns the shared glyph texture of [param id], [code]null[/code] for [constant Id.NONE].
static func texture(id: Id) -> AtlasTexture:
	if id == Id.NONE:
		return null
	if not _cache.has(id):
		var glyph: AtlasTexture = AtlasTexture.new()
		glyph.atlas = ATLAS
		glyph.region = region(id)
		_cache[id] = glyph
	return _cache[id]
