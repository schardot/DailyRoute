# Systems as runtime-composed services (factory + signals)

Systems may begin as scene-local logic during prototyping and migrate into reusable systems once patterns stabilize or complexity increases.

Systems are generally expected to:

- be scoped to the current gameplay session
- initialize during scene setup
- clean up naturally when the owning scene exits

## Status

Inferred

## Context

Scene scripts (`Game`, tutorial controller) need reusable gameplay rules (scoring, assignments) without embedding all logic into the scene or the entities.

Godot nodes are convenient as lightweight “services” because they can:

- live under a `Systems` node (lifetime scoped to a scene)
- expose signals for eventing
- reference other nodes safely once configured

## Decision

Represent reusable gameplay “systems” as Nodes instantiated at runtime, usually via:

- `static func create(parent: Node, ...) -> System`
- `configure(...)` methods for dependency injection
- signals for events (`assignment_started`, `assignment_completed`)
- optional UI binding (`ScoreSystem.bind_ui(...)`)

Orchestrator scenes are responsible for:

- creating systems
- wiring dependencies (player, stores, UI)
- connecting signals to game actions

## When to create a system

A gameplay behavior should become a system when it:

- coordinates multiple entities
- manages gameplay rules or progression
- needs reusable orchestration
- emits events consumed by multiple listeners
- becomes too complex for a single scene script

Keep behavior local to entities/scenes when:

- logic is highly localized
- behavior is purely visual
- no reuse or coordination exists yet

## Anti-patterns

Avoid systems that:

- directly manipulate unrelated scene hierarchies
- own both gameplay and UI logic
- become generic “god managers”
- hide important gameplay flow implicitly
- tightly couple multiple unrelated mechanics

## Consequences

- **Pros**
  - Keeps scenes as composition roots while extracting reusable logic.
  - Signals are preferred for cross-system coordination because they preserve loose coupling and make gameplay event flow explicit.
  - Easy to disable/replace a system per scene (tutorial vs game).
- **Cons**
  - More nodes in the scene tree (debugging requires knowing where systems are attached).
  - If systems start reaching into `$...` node paths, boundaries get muddy.

## Rules

- Systems should **not** depend on specific scene-tree paths; they should accept references.
- Systems may call autoloads (e.g. `SceneManager`) only when truly cross-cutting.
- Prefer signals for outward communication rather than calling back into orchestrators directly.

