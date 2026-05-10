# Autoload singletons as platform services

## Status

Inferred

## Context

The project is a Godot prototype with multiple top-level scenes (`Tutorial`, `Game`, UI screens). Some concerns must persist across scene changes (transitions, pause, lanes, sounds, score persistence).

Godot’s autoloads provide globally accessible singletons whose lifetime spans scene changes. This project favors pragmatic Godot-native workflows over strict dependency isolation. Autoloads are intentionally used to reduce wiring complexity and improve iteration speed during gameplay prototyping.

## Decision

Use **autoload singletons** (registered in `project.godot`) as the stable “platform layer” for cross-scene concerns:

- `SceneManager`: scene transitions, run persistence, cross-scene handoff state
- `PauseManager`: global pause toggle and signal
- `LaneManager`: lane generation + lane queries (world modeling primitive)
- `Crossings` (`CrossingManager`): crossing NPC spawning orchestration
- `Globals`: shared helpers (randomization, timers, geometry helpers)
- `SoundController`: centralized SFX playback

## Consequences

- **Pros**
  - Simple access from any script without dependency injection.
  - Stable lifetime across scene changes.
  - Clear “where does this belong?” answer for cross-scene functionality.
- **Cons**
  - Risk of “global sprawl” if every feature becomes an autoload.
  - Harder to unit test than pure modules.
  - Name changes are expensive; many scripts refer to autoload names directly.

## Rules

- Autoloads are **allowed only** for concerns that must outlive a scene or be truly global.
- Avoid storing arbitrary gameplay state globally; if state must cross scenes, store it explicitly in `SceneManager`.
- Treat autoload names as API; changing them requires a repo-wide coordinated update.
The following should generally NOT become autoloads:
- feature-specific gameplay logic
- temporary runtime entity state
- UI-specific state
- one-off orchestration helpers
- scene-local coordination
Prefer scene-owned systems or node composition when functionality:
- belongs to a single gameplay flow
- does not need cross-scene lifetime
- can be cleanly instantiated per run/session
