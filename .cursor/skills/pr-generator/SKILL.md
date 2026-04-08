---
name: pr-generator
description: Generate standardized pull request titles and descriptions following the project's preferred format. Use when the user asks to draft a PR, create a PR summary, or when preparing changes for a commit/merge.
---

# PR Generator

## Instructions
When the user asks to generate a Pull Request (PR) title and description, follow this standardized structure. Analyze the git diff and recent commits to fill in the sections accurately.

### Title Format
Use a concise, descriptive title, preferably starting with a conventional commit type (e.g., `feat:`, `fix:`, `refactor:`, `docs:`).

### Description Structure
The description MUST include the following three sections:

1. **## Summary**
   - A high-level overview of what the PR achieves and why it was implemented.
   - Focus on the user-facing benefit or the core technical change.

2. **## Key Changes**
   - A bulleted list of specific technical or visual changes.
   - Use bold text for categories (e.g., **Visual Polish**, **Logic Update**).
   - Explain the "how" and "why" for complex changes.

3. **## Test Plan**
   - A checklist of scenarios that have been or should be tested.
   - Use `[x]` for completed tests and `[ ]` for pending ones.

## Example

**Title:** `Implement ghost health bar effect for damage feedback`

**Description:**
```markdown
## Summary
Implemented a "Ghost Health Bar" system to provide better visual feedback when the player takes damage. 
The main health bar now decreases instantly, while a secondary translucent bar remains at the previous value for a short duration before smoothly interpolating down.

## Key Changes
- **Dynamic Feedback**: Added a ghost bar that lags behind the main health bar to emphasize the amount of damage taken.
- **Combo Support**: The ghost bar logic now handles rapid successive hits by maintaining the highest health value and resetting the delay timer on each new hit.
- **Visual Polish**: 
  - Added a 0.4s delay before the ghost bar starts shrinking.
  - Slowed down the interpolation (1.2s) for better readability.
  - Synchronized the UI shake effect across both bars.
- **Healing Logic**: The ghost bar updates instantly when healing to prevent visual artifacts.

## Test Plan
- [x] Take single damage: Ghost bar should appear and fade slowly after a short delay.
- [x] Take rapid successive damage: Ghost bar should stay at the initial high value and only start fading after the last hit.
- [x] Heal: Both bars should update instantly.
```
