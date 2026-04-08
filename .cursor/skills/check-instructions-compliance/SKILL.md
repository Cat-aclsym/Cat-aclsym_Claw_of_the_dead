---
name: check-instructions-compliance
description: Validates changed files against Cat'aclsym coding rules in .cursor/rules/instructions.mdc, fixes GDScript violations, and reports readiness to commit. Use when the user asks to check changes before commit, verify rules compliance, pre-commit review against project instructions, or run an instructions audit on git diffs.
---

# Check instructions compliance (git + instructions.mdc)

## When to use

Apply this skill when the user wants changed files checked against `.cursor/rules/instructions.mdc`, wants fixes applied, or wants a clear “safe to commit” / “not yet” outcome.

## Workflow

1. **Load the source of truth**
   Read `.cursor/rules/instructions.mdc` (rules may change; do not rely only on this skill’s summary).

2. **Collect changed paths**
   From the repo root, gather paths the user cares about (default: working tree + staged):
   - `git diff --name-only HEAD`
   - `git diff --cached --name-only`
   Merge, dedupe, ignore deleted-only paths for content checks. If the user only wants staged files, use `--cached` only.

3. **Scope checks by file type**
   - **`.gd` files**: Full checklist below + contextual sections from `instructions.mdc` (entities, logging, console commands, UI, state machine) when the file clearly falls in that area.
   - **Other files** (`.tscn`, `.json`, `.csv`, etc.)**: Do not invent GDScript rules. Only verify what `instructions.mdc` explicitly implies (e.g. user-facing strings and translation workflow if the project uses `tr()` and `translations.csv`; project layout under `assets/`, `scenes/`, `scripts/`, `resources/`). If nothing applies, state that and skip deep review.

4. **Fix violations**
   For each issue in scope, edit the codebase to comply. Prefer minimal diffs. Match existing file style and project patterns.

5. **Report outcome**
   - If all in-scope checks pass after fixes: tell the user clearly they **can commit** (optional: suggest `git status` / `git diff` review).
   - If something cannot be fixed without product decisions or ambiguous rules: list blockers; do not claim “ready to commit.”

## GDScript checklist (from instructions.mdc)

Use this on every changed `.gd` file unless the rule clearly does not apply (e.g. generated or third-party scripts—if any exist, exclude them).

| Area | Requirement |
|------|-------------|
| Header | First lines must include: `## © [2026] A7 Studio. All rights reserved. Trademark.` |
| Docs | `##` for class/member docs; `## [param name]` for parameters; `[codeblock]...[/codeblock]` for examples where used |
| Naming | Classes `PascalCase`; functions/properties `snake_case`; constants `SCREAMING_SNAKE_CASE`; private `_` prefix; interfaces `I` prefix |
| Language | Code, comments, and literal strings must be written in English |
| Translation | Use `tr()` for every player-facing or otherwise user-visible string |
| Typing | Explicit types where required by project style; use `Callable` / `Signal` appropriately |
| Structure | Prefer `class_name` for types; `@onready` or `%UniqueName`; `assert()` for mandatory nodes in `_ready` where applicable |
| Scenes | Prefer authored scenes and nodes over generating unnecessary dynamic nodes in GDScript; only create nodes at runtime when required |
| Order | Member order: header → class_name/extends → signals/enums → constants → exports → public vars → onready → built-ins → public funcs → private funcs (alphabetical within sections as per project convention) |
| Architecture | Signals up, methods down; prefer `await get_tree().process_frame` or `create_timer` patterns as in rules |
| Visuals | Use nearest texture filtering for pixel art assets when relevant |
| Logging | `Log.trace(Log.Level.…, message)` — see `scripts/log/log.gd` if unsure |
| Contextual | If file is a console command: `ICommand`, `description()`, `get_args()`, `_execute`. If entity/enemy: bases, states, signals per rules. If UI: `CanvasLayer`/`Control`, `tr()` for user-facing text, `Global.ui` where persistent UI applies |

## Commands reference

```bash
git diff --name-only HEAD
git diff --cached --name-only
git status --short
```

## Notes

- Do not treat this skill as a substitute for reading `instructions.mdc`; the skill is a procedure, not the full rule set.
- If no `.gd` files changed, complete steps 1–2 and report applicability; still give a commit readiness answer for what was checked.
