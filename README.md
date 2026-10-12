# Cat'aclsym: Claw of the Dead

2D tower defense built in **Godot 4.7** (Forward Plus). You defend a cat city from a zombie horde using cat-themed **towers** and **traps**, wave-based levels, optional **per-level challenges**, and an **armory** meta-progression tree unlocked with stars.

**Application name in the editor:** `Cat'aclsym`
**Main scene:** `res://scenes/main.tscn` (bootstraps `scenes/ui/ui.tscn`)

---

## Requirements

- [Godot 4.7.2](https://godotengine.org/download) (matches `config/features` in `project.godot`)
- This repository (clone or download)

---

## Run the game

1. Open the project in Godot 4.7.2.
2. Press **F5** (or **Project → Run Project**).

The editor is configured with run arguments `--verbose` (see `[editor]` in `project.godot`).

## Checks and exports

The same commands run in CI (`.github/workflows/build.yml`):

```powershell
godot --headless --path . --import
# Compiles every project script outside addons/, the exit code is the failure count
godot --headless --path . --quit-after 3000 res://tools/check_scripts.tscn
# Loads the main scene then every level, fails on any engine error
godot --headless --path . --quit-after 6000 res://tools/smoke_test.tscn
```

Exports use the presets in `export_presets.cfg` (`Windows Desktop`, `Android` arm64 APK) and write to `exports/`. CI signs the release APK with the `KEYSTORE_BASE64` and `KEYSTORE_PASSWORD` secrets, passed to Godot through the `GODOT_ANDROID_KEYSTORE_RELEASE_*` environment variables, and falls back to the debug keystore when they are missing.

---

## What is implemented today

### Core loop

- **Levels** are data-driven: `resources/levels/lev.01.json` … `lev.08.json` define the starting coins, the base health, the active challenges and the **waves** (enemy spawns by `stats.json` enemy id, waits, spawner indices).
- **Towers** are placed on valid build tiles; **traps** use their own trap placement rules.
- In-run economy and building stats come from **`assets/resources/configs/stats.json`** (loaded by the `StatsDB` autoload).
- **Victory / progression**: completing a level unlocks the next (`ProgressionManager`). Challenges can be completed per level and persisted.

### Story arcs and levels

Arcs are laid out in `scenes/ui/menus/level_selection/level_selection_menu.tscn`, their titles are the `ARC.0X.TITLE` translation keys:

- **Arc 1**: *Chat'lanques de Nyarseille*, levels `lev.01` to `lev.05`.
- **Arc 2**: *La mer Nyaditerranée*, levels `lev.06` to `lev.08`.

Level names and descriptions are the `LEVEL.LEV_0X.NAME` / `LEVEL.LEV_0X.DESC` keys.

### Challenges

- **17** challenge definitions under `resources/challenges/` (IDs like `cha.000` … `cha.205`), each pointing at a small GDScript under `scripts/challenges/logics/`.
- Levels reference which challenges are active via their JSON `challenges` array (see e.g. `resources/levels/lev.01.json`).

### Armory (meta)

- Unlock graph and costs: `resources/armory/armory.json` (star costs, tower/trap unlocks, upgrade branch gates).
- **Starter tower** always available without the armory: **`bat_01`** (`ProgressionManager.ARMORY_STARTER_TOWER_IDS`).

### Towers and traps (from `stats.json`)

| Kind | IDs | Notes |
|------|-----|--------|
| **Towers** | `bat_01`, `bat_02`, `bat_08`, `bat_09` | Examples: scratch post archer line, AoE *Cataboom*, lightning *Tesla*, channeled *Inferno* beam. |
| **Traps** | `bat_03`–`bat_07` | Blades, slow, bomb, poison, stun variants. |

### Enemies

- Waves and `stats.json` share the same enemy ids: `default_zombie`, `damage_zombie`, `rat`, `small_zombie`, `splitter_zombie`, `minesweeper`, `big_daddy`. `StatsDB.get_enemy_scene(id)` returns the matching scene under `scenes/gameplay/entities/enemy/enemies/`.
- Stats also carry each enemy's kill reward and escape damage. A `big_daddy` reaching the base ends the level in defeat.

### Narrative and text

- **Dialogic 2.0 Alpha 20** (`addons/dialogic`, autoload `Dialogic`). Timelines live in `assets/narrative/`, one file per locale: `<name>.en.dtl` and `<name>.fr.dtl`. `Narrative.timeline_path(name)` picks the file of the current locale, and `Narrative.play_once(flag, name)` plays a one-time dialogue whose flag is saved in the progression. `play_once` does nothing (and leaves the flag unset) while another timeline, such as the tutorial, is running.
- **Localization:** English and French, all player-visible text comes from `assets/translations/translations.csv`. Entity names follow `TOWER.<ID>.NAME`, `TRAP.<ID>.NAME` and `ENEMY.<ID>.NAME` (`StatsDB.name_key`).

### UI and menus (scenes)

Home, level selection, pause, options, HUD (waves, score popups, challenge UI), tower upgrade radial menu, building cards, encyclopedia, end-game screen, armory menu, damage popups.

### Audio

- `SoundManager` autoload with the `Music`, `SFX` and `UI` buses from `default_bus_layout.tres` (toggles follow the progression settings).

### Debug and tooling

- **In-game debug console** (when enabled for the build): bound to **`** (grave / backtick)** to toggle (`toggle_console` input map), **Enter** to submit a line (`console_push`).
- Console commands live in `scripts/commands/` (e.g. `help`, `load_level`, `set_money`, `set_time_scale`, `progression`, `unlock_armory`, …).
- `Global.debug` follows the `debug` export feature: true in the editor and debug exports, false in release exports.

### Persistence

- Primary save: **`user://progression.dat`** (`ProgressionManager`).
- Stores settings (language, music/sfx toggles), level unlock state, challenge completion, per-entity progression, and armory purchases (`ProgressionData`).

### Rendering

- **2D pixel workflow:** `textures/canvas_textures/default_texture_filter=0` (nearest) in `project.godot`.
- **Display:** stretch mode `canvas_items`, aspect `expand`.
- **Input:** `pointing/emulate_touch_from_mouse=true` for mouse-as-touch testing.

---

## Autoloads (`project.godot`)

| Singleton | Role |
|-----------|------|
| `Global` | Camera, HUD, UI, console and cursor refs, pause requests by source (`request_pause` / `release_pause`) |
| `SoundManager` | Audio |
| `ScenesLoader` | Scene transitions (`go_home`, `start_level`) |
| `Dialogic` | Narrative |
| `StatsDB` | Tower / trap / enemy / bullet / upgrade stats from JSON |
| `ProgressionManager` | Save / load, settings, unlocks, one-time flags |
| `ArmoryManager` | Armory meta layer |
| `ChallengeManager` | Active challenges for the current level |

---

## Default input map (high level)

| Action | Default bindings (see `[input]` in `project.godot`) |
|--------|------------------------------------------------------|
| `place_tower` | Left mouse button |
| `rmb` | Right mouse button |
| `dialogic_default_action` | Space, Enter, left click |
| `scroll_up` / `scroll_down` | Mouse wheel; Meta + Up/Down |
| `toggle_console` | Grave / backtick |
| `console_push` | Enter / keypad Enter |

---

## Repository layout

| Path | Contents |
|------|----------|
| `addons/` | Third-party plugins (Dialogic; ignored for gameplay unless you work on plugins) |
| `assets/` | Art, audio, themes, translation CSVs, `assets/resources/configs/stats.json` |
| `resources/` | Level, challenge, and armory JSON |
| `scenes/` | `.tscn` scenes (gameplay, UI, maps, entities) |
| `scripts/` | GDScript (`autoloads`, commands, challenges, narrative, progression, ...) |
| `tools/` | Headless checks (`check_scripts`, `smoke_test`), excluded from exports |
| `log/` | Runtime log output directory (when used) |

---

## License

The game's source and resources in this repository are licensed under the **GNU General Public License v3.0**. The full text is in [`LICENSE`](LICENSE).

Third-party code (for example under `addons/`, including Dialogic) stays under its authors' licenses; check each addon's own `LICENSE` or `LICENSE.txt` where present.

---

## Credits

© 2026 A7 Studio. Trademark. For redistribution and modification of this repository's contents, see [License](#license) above.
