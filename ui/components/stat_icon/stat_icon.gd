## © [2026] A7 Studio. All rights reserved. Trademark.
##
## Atlas of the stat icons: one [AtlasTexture] per [enum Id], cut from [code]stat_icons.png[/code] (one row of [constant COLUMNS] cells of [constant CELL_SIZE] px).
## [br]Stat bars and the encyclopedia look the icons up by [enum Id], or by the stat key of [code]stats.json[/code] with [method for_stat].
## [codeblock]
## var attack: AtlasTexture = StatIcon.texture(StatIcon.Id.ATTACK)
## var burn: AtlasTexture = StatIcon.for_stat("burn_damage_base")
## [/codeblock]
@tool
class_name StatIcon
extends RefCounted

## Order = cell order in [code]stat_icons.png[/code] (cell [code]id - 1[/code]).
enum Id {
	NONE,
	AOE_RANGE,
	ATTACK,
	ATTACK_MULTIPLIER,
	BULLETS,
	BURN_DAMAGE,
	BURN_DURATION,
	ELECTRICITY_BASE,
	ELECTRICITY_CHAIN_BOUNCES,
	ELECTRICITY_CHAIN_FALLOFF,
	ELECTRICITY_CHAIN_RANGE,
	ELECTRICITY_DURATION,
	ELECTRICITY_INTERVAL,
	ELECTRICITY_SLOW,
	FIRE_RATE,
	PIERCE_COUNT,
	PIERCE_REDUCTION,
	RANGE,
	SPEED,
	SPREAD,
	ZOMBIE_SPEED,
}

const ATLAS: Texture2D = preload("res://assets/ui/stats/stat_icons.png")
const CELL_SIZE: int = 16
const COLUMNS: int = 20
## Icon of each stat key of [code]stats.json[/code] (towers, bullets and upgrades). [constant Id.ZOMBIE_SPEED] belongs to the enemies and has no key.
const BY_STAT: Dictionary[String, Id] = {
	"aoe_duration": Id.BURN_DURATION,
	"aoe_range": Id.AOE_RANGE,
	"aoe_tick": Id.BURN_DAMAGE,
	"burn_damage_base": Id.BURN_DAMAGE,
	"burn_duration": Id.BURN_DURATION,
	"chain_bounces": Id.ELECTRICITY_CHAIN_BOUNCES,
	"chain_damage_falloff": Id.ELECTRICITY_CHAIN_FALLOFF,
	"chain_range": Id.ELECTRICITY_CHAIN_RANGE,
	"damage": Id.ATTACK,
	"damage_multiplier": Id.ATTACK_MULTIPLIER,
	"electrify_duration": Id.ELECTRICITY_DURATION,
	"electrify_slow_amount": Id.ELECTRICITY_SLOW,
	"electrify_tick_damage": Id.ELECTRICITY_BASE,
	"electrify_tick_interval": Id.ELECTRICITY_INTERVAL,
	"fire_rate": Id.FIRE_RATE,
	"pierce_count": Id.PIERCE_COUNT,
	"pierce_reduction": Id.PIERCE_REDUCTION,
	"projectile_count": Id.BULLETS,
	"shoot_range": Id.RANGE,
	"speed": Id.SPEED,
	"spread_angle": Id.SPREAD,
}

static var _cache: Dictionary[int, AtlasTexture] = {}


## Returns the icon of the stat [param stat_name] (a key of [constant BY_STAT]), [code]null[/code] when the stat has none.
static func for_stat(stat_name: String) -> AtlasTexture:
	return texture(BY_STAT.get(stat_name, Id.NONE))


## Returns the name of [param id], e.g. [code]ELECTRICITY_SLOW[/code].
static func key(id: Id) -> String:
	return Id.keys()[id] as String


## Returns the cell of [param id] in [constant ATLAS], in pixels.
@warning_ignore("integer_division")
static func region(id: Id) -> Rect2:
	var cell: int = id - 1
	return Rect2(cell % COLUMNS * CELL_SIZE, cell / COLUMNS * CELL_SIZE, CELL_SIZE, CELL_SIZE)


## Returns the shared icon texture of [param id], [code]null[/code] for [constant Id.NONE].
static func texture(id: Id) -> AtlasTexture:
	if id == Id.NONE:
		return null
	if not _cache.has(id):
		var icon: AtlasTexture = AtlasTexture.new()
		icon.atlas = ATLAS
		icon.region = region(id)
		_cache[id] = icon
	return _cache[id]
