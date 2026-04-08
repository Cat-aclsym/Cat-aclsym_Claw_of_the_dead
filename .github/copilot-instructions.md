# Cat'aclsym: Claw of the Dead - Coding Instructions

You are an expert GDScript developer specialized in Godot 4.4.
Write all code, comments, and literal strings in English.
Use `tr()` for every string that is visible to the player or otherwise user-facing.
Follow Godot 4.4 recommended practices unless a project-specific rule explicitly overrides them.

## General Coding Standards

### File Header
Every GDScript file MUST start with the following copyright header:
```gdscript
## © [2026] A7 Studio. All rights reserved. Trademark.
```

### Documentation
- Use `##` for class-level and member-level documentation.
- Use `## [param name]` for parameter documentation.
- Use `## [br]` for line breaks.
- Use `[codeblock]...[/codeblock]` for code examples in documentation.

### Naming & Typing
- **Classes**: `PascalCase`.
- **Properties/Functions**: `snake_case`.
- **Constants**: `SCREAMING_SNAKE_CASE`.
- **Private**: Prefix with `_`.
- **Interfaces**: Prefix with `I` (e.g., `IEnemy`).
- **Nodes**: Logical names (`AttackTimer` vs `Timer`), Unique Names (`%HUD`) for important nodes.
- **Typing**: Explicit types `var x: int = 0`. Use `Callable` and `Signal`.

## Architecture

### Node Workflow
- **Loose Coupling**: Signals up, methods down.
- Use `@onready` or `%UniqueName`.
- `assert()` mandatory nodes in `_ready`.
- `class_name` for types.
- Prefer building scenes with authored nodes over generating unnecessary dynamic nodes in GDScript. Only create nodes at runtime when the behavior truly requires it, such as dynamic particle placement.
- Favor `await get_tree().process_frame` or `await get_tree().create_timer(s).timeout`.

### Code Order (Sort Alphabetically)
1. Header
2. `class_name`/`extends`
3. Signals/Enums
4. Constants
5. Exported vars
6. Public vars
7. Onready vars
8. Built-in funcs (`_init`, `_ready`, `_process`)
9. Public funcs
10. Private funcs

### Global Access
- `Global`: Camera, UI, HUD, Console. Check `_initialized` or use assertions.
- `SoundManager`: Audio playback.
- `ScenesLoader`: Scene transitions.
- `StatsDB`: Entity stats (`get_enemy(id)`, `get_tower(id)`).
- `ProgressionManager`: Save/Load logic.
- `ChallengeManager`: Challenges/Kill notification.
- `Log`: Logging system `Log.trace(...)`.

## Systems & Patterns

### Entity Design
- Inherit `IEnemy` or appropriate base.
- Use `EnemyState` enum + `match state`.
- Signals: `die`, `camera_effect`.
- `_apply_stats_override()` uses `StatsDB`.

### Logging System
- Open `scripts/log/log.gd` for reference.
- Use `Log.trace(level: Log.Level, message: Variant)`.
- Level references: `Log.Level.DEBUG`, `Log.Level.INFO`, `Log.Level.WARN`, `Log.Level.ERROR`, `Log.Level.FATAL`.
- Example: `Log.trace(Log.Level.WARN, "Missing file: %s" % path)`.

### Debug Console
- Commands in `scripts/commands/`.
- Extend `ICommand`.
- Implement `description() -> String`.
- Implement `get_args() -> Array[Dictionary]`. Return format: `[{"name": "arg_name", "type": ICommand.Types.ARG_STRING, "optional": false}]`.
- Implement `_execute(console: Console, args: Array) -> int`.

### State Machine
- Use `StateMachine` class.
- Define `State` and `Transition` objects.
- Use `toggle_state(state_id)` to switch states.

### UI
- Extend `CanvasLayer` or `Control`.
- Persistent UI sets `Global.ui = self`.
- Use `tr()` for user-facing text.

### Visual Assets
- Use nearest texture filtering for all pixel art sprites.
- Keep texture import and sprite settings aligned with Godot 4.4 recommended 2D/pixel-art workflow.

## Project Structure
- `assets/` - Art and Audio
- `scenes/` (.tscn) - Visuals and Composition
- `scripts/` (.gd) - Logic
- `resources/` (JSON configs)
- `log/` - Runtime logs
