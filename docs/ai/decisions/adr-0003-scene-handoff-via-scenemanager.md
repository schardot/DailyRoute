# Scene transitions and handoff via SceneManager

## Status

Inferred

## Context

The tutorial and game scenes share gameplay elements (player, crowd, stores, score), and the project needs:

- predictable scene transitions (menu/tutorial/game/end/lose)
- persistence of highscore
- a small amount of state transfer when switching tutorial → game

Godot scene changes destroy the current scene tree; passing references is not viable.

## Decision

Centralize scene transitions and cross-scene state transfer in the autoload `SceneManager`:

- Transition methods call `change_scene_to_file` via `call_deferred` to avoid mutation during the current frame.
- Highscore persistence is stored in `user://save.cfg` (ConfigFile).
- Tutorial → game handoff uses explicit fields:
  - `player_position`
  - `crowd_positions`
  - `pending_score` (consumed by `ScoreSystem.init_from_pending_score`)

The following should generally NOT live in SceneManager:

- entity runtime behavior
- temporary gameplay effects
- scene-local orchestration
- UI widget state
- per-frame gameplay coordination

Before adding new scene transitions:

- verify handoff state is initialized explicitly
- avoid relying on node references surviving transitions
- ensure consumers clear temporary handoff data after use
- preserve deferred transition behavior

## Consequences

- **Pros**
  - One authoritative place to reason about transitions and persistence.
  - Handoff state is explicit and easy to audit.
  - UI end/lose screens can read final run summary from one place.
- **Cons**
  - `SceneManager` can accumulate unrelated responsibilities if not kept disciplined.
  - Persistence format changes require migration to avoid wiping player data.

## Rules

- All scene transitions should go through `SceneManager` (no scattered scene changes).
- Only store cross-scene handoff state that is necessary; clear it after consumption where appropriate.
- If persistence keys/sections change, implement a migration path rather than silently resetting highscore.
- Cross-scene handoff state should remain minimal and explicit. Prefer reconstructing runtime state from scene initialization whenever practical instead of persisting transient gameplay state globally.
