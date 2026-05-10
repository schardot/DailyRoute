# Architecture (AI memory)

This repository is a **Godot 4** 2D prototype. The architecture is intentionally lightweight: **Scenes own orchestration**, “systems” encapsulate reusable gameplay rules, and **autoload singletons** provide cross-scene services and state.

The goal of this document is to capture what must remain true for the project to stay coherent.

## Architectural priorities

When making changes, preserve these priorities in order:

1. Stable gameplay behavior
2. Clear scene ownership
3. Loose coupling through signals
4. Reusable gameplay systems
5. Minimal global state
6. Editor friendliness over abstraction purity

Avoid introducing abstractions that make iteration harder for designers/content work.

## Prototype philosophy

This project prioritizes:

- fast iteration
- readable gameplay code
- editor-driven workflows
- low ceremony

Avoid introducing:

- heavy abstraction layers
- excessive indirection
- generic frameworks
- dependency injection containers
- enterprise-style architecture patterns

Prefer pragmatic solutions that fit Godot workflows.

## Architectural style

- **Scene-driven gameplay**: `scenes/app/*.tscn` are the primary entrypoints; their scripts (`Game.gd`, `Tutorial.gd`, `World.gd`, UI screens) wire up entities + systems.
- **Service-ish systems**: `systems/*.gd` contains modules that act like small services/managers (e.g. assignments, scoring, lanes, crossings, pause).
- **Global services via autoload**: core cross-scene concerns are autoloaded singletons (see `project.godot` `[autoload]`).
- **Signals over tight coupling**: key events are exposed as signals (e.g. `AssignmentSystem.assignment_completed`, `PauseManager.pause_toggled`, `Player.boost_used`) and connected by orchestrators.

## Folder/module responsibilities (inferred)

- `scenes/`: Godot scenes and their scripts.
  - `scenes/app/`: top-level flows (`Game`, `Tutorial`, `World`, `BaseGameplay`).
  - `scenes/entities/`: entity scripts (`Player`, `Car`, `CrowdMember`, `CrossingNpc`, etc.).
  - `scenes/ui/`: UI scenes and scripts (score, pause, end/lose screens, HUD icons).
  - `scenes/world/`: world objects (`Store`, fences, street, etc.).
- `systems/`: global managers + reusable gameplay systems. Some are autoloaded (global singletons), others are instantiated per scene via a `create(parent, ...)` factory.
- `assets/`: audio, art, etc. (not documented here).

## Data flow and state flow

### Runtime wiring

- Orchestrator scenes (notably `scenes/app/Game.gd` and `scenes/app/Tutorial.gd`, both inheriting from `scenes/app/BaseGameplay.gd`) perform the “composition root” role:
  - read nodes via `$...` paths / `@onready`
  - fetch world sub-roots via helper accessors (`World.get_player()`, `World.get_entities_root()`, etc.)
  - construct per-run systems (`ScoreSystem.create(...)`, `AssignmentSystem.create(...)`)
  - connect signals and kick off initial actions (e.g. `start_random_assignment()`).

### Global state between scenes

- `SceneManager` (autoload) is the **single source of truth** for:
  - **scene transitions** (`go_to_tutorial/game/end/lose`) via `change_scene_to_file` deferred calls
  - **run persistence** (highscore saved in `user://save.cfg`)
  - **handoff state** when switching tutorial → game (`player_position`, `crowd_positions`, `pending_score`).

### World modeling

- Lanes are a core abstraction (`LaneStruct`, `LaneManager`):
  - `World._ready()` calls `LaneManager.set_tilemap(tilemap)` then `LaneManager.generate_lanes()`.
  - Cars, crowd members, and crossing logic rely on lanes being generated early and being stable during play.

## State management patterns

- **Local state** lives on nodes/scripts (player movement flags, car speed, store completion flags).
- **Per-run systems** hold small pieces of domain state and synchronize outward:
  - Example: `ScoreSystem` tracks score and pushes to `SceneManager` + UI.
  - Example: `AssignmentSystem` tracks `current_store` and emits signals.
- **Global state** lives in autoloads only when it must cross scene boundaries.

## “API access” patterns (gameplay APIs)

There is no HTTP/network API in this repo. “API access” here means *how scripts call into other modules*:

- **Prefer** stable method calls on known abstractions (`World.get_player`, `SceneManager.go_to_game`, `LaneManager.get_nearest_lane_by_type`).
- **Allow** dynamic calls only at edges where scripts must tolerate varying node implementations:
  - `has_method(...)` + `call(...)` is used for soft-contract integration (e.g. store animations, optional `set_enabled` on car, delivery truck intro hooks).

## Boundaries between layers (keep these clear)

- Scene scripts may orchestrate gameplay flow, but reusable gameplay rules should migrate into systems once reused or complex.
- **Systems** implement reusable rules and coordination (assignment selection, scoring, lane generation, crossing spawn).
- **Entities** implement moment-to-moment behavior (movement, collision reactions, braking, animation).
- **UI** reads from `SceneManager` for summary screens and is updated via bindings (e.g. `ScoreSystem.bind_ui`).

## Important abstractions (stable)

- **Autoload singletons**: `SceneManager`, `PauseManager`, `LaneManager`, `Crossings` (`CrossingManager`), `Globals`, `SoundController`.
  - These are referenced widely by name; renaming or changing their responsibilities is high-risk.
- **Groups**: `"stores"`, `"player"`, `"crossing_npcs"` are used as dynamic discovery mechanisms.
  - Group names are effectively API. Changing them silently breaks wiring.
- **LaneStruct / LaneManager**: underpin crowd, cars, and crossings alignment/braking behavior.

## Systems that should not be casually refactored

- **`SceneManager`**: scene transitions + persistence + cross-scene handoff. Treat as a “platform” module.
- **`LaneManager` lane generation**: many behaviors assume lanes exist and are sensible; changes cascade widely.
- **Group- and path-based wiring** in top-level scenes/controllers: `$World`, `$Systems`, `$HudTopRight/...` etc.
  - These depend on scene tree structure; refactors must update both scene and script in lockstep.

## Forbidden / discouraged patterns (project-level)

- **Don’t introduce new global state** outside autoloads. If state must cross scene boundaries, put it in `SceneManager` explicitly.
- **Don’t hardcode node paths across unrelated scenes**. Keep `$...` usage within the scene that owns that structure.
- **Don’t rely on implicit timing** without awaiting. If you call `Globals.wait(...)`, it returns an awaitable; use `await` to actually delay.
- **Don’t replace signals with direct cross-node calls** unless you are removing indirection for a proven performance reason.

## Testing philosophy (current state)

- **Inferred**: This is a prototype with little/no automated test harness. Correctness is primarily validated in-editor via playtesting.
- Defensive checks are used sparingly:
  - `assert(...)` for invariants that should never be violated (e.g. stores exist, lane queries succeed).
  - `push_warning(...)` for recoverable content/config problems (e.g. missing store animations).

If/when tests are added, prefer tests for **systems** (pure-ish logic: assignment selection, lane grouping, crossing row memory) rather than scene graphs.

## Error handling philosophy

- **Fail fast** for broken invariants (assertions).
- **Graceful degrade** for optional content hooks (null checks + `has_method` + warnings).
- **Avoid noisy logs**: there are no `print(...)` calls in the repo; warnings are used when content is misconfigured.

## Preferred extension patterns

### Adding new gameplay mechanics

- Prefer adding/modifying systems rather than bloating scene scripts.
- Use signals for cross-entity coordination.
- Keep entity scripts focused on local behavior.

### Adding new UI

- UI should observe state, not own gameplay logic.
- Reuse existing HUD/update patterns where possible.

### Adding persistent state

- Persist through SceneManager only.
- Avoid creating additional persistence singletons.

### Adding world interactions

- Prefer groups and stable interfaces over deep node traversal.

## Coupling hazards

The following areas are highly coupled and changes can cascade widely:

- lane generation and lane typing
- scene tree node paths
- autoload singleton names
- group names
- tutorial-to-game handoff state

Before modifying these:

- search for all usages
- preserve external contracts
- avoid silent renames
