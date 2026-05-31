# Cat'aclsym: Claw of the Dead

2D tower defense built in **Godot 4.4** (Forward Plus). You defend a cat city from a zombie horde using cat-themed **towers** and **traps**, wave-based levels, optional **per-level challenges**, and an **armory** meta-progression tree unlocked with stars.

**Application name in the editor:** `Cat'aclsym`
**Main scene:** `res://scenes/main.tscn` (bootstraps `scenes/ui/ui.tscn`)

---

## Requirements

- [Godot 4.4](https://godotengine.org/download) (matches `config/features` in `project.godot`)
- This repository (clone or download)

There is no separate CLI build script in the repo; open the project folder in Godot and run from the editor or export as usual.

---

## Run the game

1. Open the project in Godot 4.4.
2. Press **F5** (or **Project → Run Project**).

The editor is configured with run arguments `--verbose` (see `[editor]` in `project.godot`).

---

## What is implemented today

### Core loop

- **Levels** are data-driven: `resources/levels/lev.01.json` … `lev.08.json` define **waves** (enemy spawns, waits, spawner indices).
- **Towers** are placed on valid build tiles; **traps** use their own trap placement rules.
- In-run economy and building stats come from **`assets/resources/configs/stats.json`** (loaded by the `StatsDB` autoload).
- **Victory / progression**: completing a level unlocks the next (`ProgressionManager`). Challenges can be completed per level and persisted.

### Story arcs and levels

- **Arc 1** (`resources/arcs/arc.01.json`): *Chat'lanques de Nyarseille* — levels `lev.01`–`lev.05`.
- **Arc 2** (`resources/arcs/arc.02.json`): *La mer Nyaditerranée* — levels `lev.06`–`lev.08`.

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

- **Waves** reference enemy **scene IDs** (file names under `scenes/gameplay/entities/enemy/enemies/`), for example `ene.01`, `ene.02`, `ene.03`, `big_daddy`, `small_zombie`, `splitter_zombie`.
- **Balance and encyclopedia** data for enemies live in `stats.json` under its own enemy keys (for example `default_zombie`, `damage_zombie`, `rat`, plus the special types above).

### Narrative and text

- **Dialogic** is integrated (`addons/dialogic`, autoload `Dialogic`). Example timeline: `assets/narrative/example.dtl`; sample scene: `scenes/narrative/example/dialogic_example.tscn`.
- **Localization:** English and French (`assets/translations`, Dialogic translation files, `translation/locales` in `project.godot`). Default test locale in project settings is **French** (`locale/test`).

### UI and menus (scenes)

Home, level selection, pause, options, HUD (waves, score popups, challenge UI), tower upgrade radial menu, building cards, encyclopedia, end-game screen, armory menu, damage popups.

### Audio

- `SoundManager` autoload; buses used in code include **music** and **sfx** (volumes follow progression settings).

### Debug and tooling

- **In-game debug console** (when enabled for the build): bound to **`** (grave / backtick)** to toggle (`toggle_console` input map), **Enter** to submit a line (`console_push`).
- Console commands live in `scripts/commands/` (e.g. `help`, `load_level`, `set_money`, `set_time_scale`, `progression`, `unlock_armory`, …).
- `Global.debug` defaults to **true** in `scripts/autoloads/global.gd` (release behavior can be adjusted there).
- **Pseudolocalization** is enabled in `project.godot` for UI stress-testing.

### Persistence

- Primary save: **`user://progression.dat`** (`ProgressionManager`).
- Stores settings (language, music/sfx toggles), level unlock state, challenge completion, per-entity progression, and armory purchases (`ProgressionData`).

### Rendering

- **2D pixel workflow:** `textures/canvas_textures/default_texture_filter=0` (nearest) in `project.godot`.
- **Display:** stretch mode `canvas_items`, aspect `keep_height`.
- **Input:** `pointing/emulate_touch_from_mouse=true` for mouse-as-touch testing.

---

## Autoloads (`project.godot`)

| Singleton | Role |
|-----------|------|
| `Global` | Camera, HUD, UI, console, cursor, pause flag |
| `SoundManager` | Audio |
| `ScenesLoader` | Scene transitions |
| `Dialogic` | Narrative |
| `ProgressionManager` | Save / load, settings, unlocks |
| `StatsDB` | Tower / trap / enemy / upgrade stats from JSON |
| `ChallengeManager` | Active challenges for the current level |
| `ArmoryManager` | Armory meta layer |

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
| `resources/` | Level, arc, challenge, and armory JSON |
| `scenes/` | `.tscn` scenes (gameplay, UI, maps, entities) |
| `scripts/` | GDScript (`autoloads`, commands, challenges, entities, progression, ...) |
| `log/` | Runtime log output directory (when used) |

---

## License

The game's source and resources in this repository are licensed under the **GNU General Public License v3.0**. The full text is in [`LICENSE`](LICENSE).

Third-party code (for example under `addons/`, including Dialogic) stays under its authors' licenses; check each addon's own `LICENSE` or `LICENSE.txt` where present.

---

## Credits

© 2026 A7 Studio. Trademark. For redistribution and modification of this repository's contents, see [License](#license) above.
