# Conventions (AI memory)

This is a **Godot 4 / GDScript** codebase. The conventions below are inferred from existing patterns; treat them as the default unless there’s a strong reason to deviate.

## General philosophy

This project prioritizes:

- gameplay iteration speed
- readable gameplay code
- editor-friendly workflows
- explicit orchestration
- low ceremony

Prefer:

- straightforward scene wiring
- small reusable systems
- explicit signals
- practical solutions

Avoid:

- abstraction for abstraction’s sake
- generic framework layers
- deep inheritance hierarchies
- enterprise-style architecture patterns

## Refactoring safety

Before refactoring:

- search for signal connections
- search for group usages
- search for autoload references
- verify node path dependencies
- preserve scene tree assumptions

High-risk changes include:

- renaming autoloads
- renaming groups
- changing scene hierarchy
- modifying lane generation behavior
- changing tutorial/game handoff flow

## Code style

- Prefer early returns over deep nesting.
- Prefer descriptive variable names over abbreviations.
- Keep gameplay logic explicit and readable.
- Avoid clever one-liners.
- Small duplication is acceptable if it improves clarity.

## Naming

- **Files**: `PascalCase.gd` for systems and many scripts (`ScoreSystem.gd`, `LaneManager.gd`), matching Godot class naming.
- **Scenes**: `PascalCase.tscn` in parallel with scripts (`Game.tscn`/`Game.gd`).
- **Classes**: `class_name PascalCase` is used for key types (`World`, `CrowdManager`, `AssignmentSystem`, `ScoreSystem`, `CrossingManager`). Prefer adding `class_name` for reusable systems/entities.
- **Signals**: `snake_case` (`assignment_completed`, `pause_toggled`, `boost_used`).
- **Constants**: `UPPER_SNAKE_CASE` (`SAVE_PATH`, `CAR_SCENE`, `SPAWN_MARGIN_Y`).
- **Variables/functions**: `snake_case` (`start_random_assignment`, `init_stores_and_assignments`).

### Do / Don’t

- **Do**: `class_name ScoreSystem`, file `ScoreSystem.gd`
- **Don’t**: `score_system.gd` (would be inconsistent with existing core modules)

## File organization

- **`systems/`**: global managers and reusable gameplay systems.
  - Autoload singletons live here and are registered in `project.godot`.
  - Non-autoload “systems” are typically created at runtime and added as children under a `Systems` node (or the current scene).
- **`scenes/app/`**: top-level composition roots (tutorial/game/world).
- **`scenes/entities/`**: entity behavior (player, crowd, car, crossings).
- **`scenes/ui/`**: UI widgets and screens.
- **`scenes/world/`**: world objects (stores, fences, street).

## “Systems” pattern (factory + bind)

Several systems use a consistent factory style:

- `static func create(parent: Node, ...) -> SystemType`
  - constructs `SystemType.new()`
  - `parent.add_child(sys)` when parent exists
  - configures dependencies via `configure(...)` and/or `bind_ui(...)`

### Do / Don’t

- **Do**: keep systems **parameterized** (`create(parent, player, stores)`).
- **Don’t**: have systems reach into scene trees with `$...` paths (that belongs in the orchestrator scene).

## Autoload usage

Autoload singletons (see `project.godot`) are treated as stable “platform services”:

- `SceneManager`: scene transitions + cross-scene state + save/highscore
- `LaneManager`: lane generation and queries
- `PauseManager`: global pause state
- `Crossings`: crossing spawner/manager
- `Globals`: small shared helpers (random, timers, geometry helpers, mapping)
- `SoundController`: centralized SFX playback
- `GameTypes`: enums/constants

### Do / Don’t

- **Do**: call `SceneManager.go_to_game()` for transitions.
- **Don’t**: introduce new ad-hoc `get_tree().change_scene...` scattered across scripts.

## Groups as “soft contracts”

The code relies on Godot groups for discovery:

- `"stores"`: store areas (`Store.gd` adds itself in `_ready`)
- `"player"`: expected on player node (used by store collision + car collision checks)
- `"crossing_npcs"`: crossing NPC discovery for car braking

### Do / Don’t

- **Do**: treat group names as API; change them only with a repo-wide update.
- **Don’t**: depend on `get_nodes_in_group(...)` in low-level entity logic unless necessary.

## Imports / dependencies

- GDScript tends to reference types via `class_name` (preferred) and node paths (`$...`) within a scene.
- Preloads are used for instantiation of scenes/resources:
  - `const X: PackedScene = preload("res://.../Thing.tscn")`

## Error handling and logging

- **No `print(...)` logging** is used.
- Use:
  - `assert(...)` for invariants (e.g. “stores must exist”).
  - `push_warning(...)` for recoverable misconfiguration (e.g. missing animations).
- Null checks (`if not x: return`) are acceptable at module boundaries and for optional content hooks, but avoid excessive defensive branching in core gameplay flow.

### Do / Don’t

- **Do**: `push_warning("...")` for missing optional content.
- **Don’t**: spam console logs during gameplay loops.

## Timing and async

- `Globals.wait(seconds)` returns an awaitable; callers should `await` it when intending to delay.
- For scene changes and some sequencing, `call_deferred(...)` is used to avoid tree mutation during the current frame.

### Do / Don’t

- **Do**: `await get_tree().process_frame` when you need nodes ready before wiring (tutorial controller does this).
- **Don’t**: call `Globals.wait(...)` without `await` if you expect it to actually pause execution.

## UI composition: owner vs internal wiring

Prefer splitting HUD/UI scenes into two layers when it improves clarity and pause/input behavior:

- **Owner node script (external API + configuration)**:
  - attach a lightweight script to the root of the UI scene to expose configuration to the rest of the game (exported flags, stable node paths, small public methods).
  - keep this layer free of per-frame logic and input where possible.

- **Canvas/input layer script (internal wiring + behavior)**:
  - put runtime UI behavior and input handling on the `CanvasLayer` (or the specific `Control`) that owns the widgets.
  - set `process_mode = PROCESS_MODE_ALWAYS` when the UI must remain responsive while the game is paused (e.g. pause toggles).

Example: `scenes/ui/HudTopRight.tscn` uses a root owner script (`HudTopRight.gd`) for configuration (e.g. `show_skip_tutorial`) and a `CanvasLayer` child (`HudCanvas` with `PauseUI.gd`) for pause button wiring and `"pause"` input handling.

## Commit message conventions

Rules:

- use lowercase
- use imperative mood
- keep summary concise
- one logical change per commit
- prefer explicit scopes

History follows a **Conventional Commits**-like style with scope:

- `feat(systems): add score and assignment systems`
- `fix(world): adjust fence collision and store palette`
- `chore(globals): remove unused signals`

### Do / Don’t

- **Do**: `feat(area): ...`, `fix(area): ...`, `chore(area): ...`
- **Don’t**: vague messages like “updates” or “wip” for merged changes

## Git workflow conventions

### Branch safety

- Never push directly to `main`.
- All non-trivial work should happen on a feature/fix branch.
- Prefer small focused branches over long-lived branches.

Examples:

- `feat/crossing-improvements`
- `fix/tutorial-handoff`
- `refactor/lane-grouping`

### Commit workflow

- Make logically grouped commits.
- Avoid mixing unrelated refactors and gameplay changes.
- Prefer multiple small commits over one large ambiguous commit.

### Before merging

Before merging or opening a PR:

- verify the game still boots
- verify critical gameplay loops still function
- check scene references after refactors
- review signal connections and node-path changes

### Refactor safety

High-risk changes should not be committed blindly:

- scene tree restructuring
- autoload renames
- group renames
- lane generation changes
- SceneManager transition behavior

These changes require:

- repo-wide search
- validation of references
- explicit review

### AI-agent-specific rules

AI agents should:

- avoid direct pushes to protected branches
- avoid force-pushes unless explicitly requested
- summarize large refactors before applying them
- prefer incremental commits for risky changes

When uncertain:

- stop and ask for confirmation before destructive Git operations.
