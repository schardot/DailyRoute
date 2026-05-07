# Current Focus

This project is currently in an active gameplay iteration phase. Prioritize fast iteration, gameplay feel, and system clarity over architectural perfection.

---

## Current priorities

1. Stabilize lane-driven gameplay behavior
2. Improve crossings and NPC flow consistency
3. Keep tutorial → gameplay transition reliable
4. Continue extracting reusable gameplay coordination into systems where appropriate

---

## Active architectural direction

Recent work is moving gameplay coordination out of large scene scripts and into focused runtime systems (`ScoreSystem`, `AssignmentSystem`, `CrossingManager`).

Preferred direction:

* small focused systems
* explicit orchestration
* signal-driven communication
* lightweight scene composition

Avoid introducing:

* generic gameplay frameworks
* deep abstraction layers
* excessive global state
* overly “engineered” patterns

---

## Fragile / high-risk areas

Changes in these areas can cascade widely:

* `LaneManager` generation and lane typing
* tutorial → game handoff state
* autoload singleton names and responsibilities
* scene tree node paths
* gameplay groups (`stores`, `player`, `crossing_npcs`)
* async ordering using `call_deferred` / `await process_frame`

Before modifying:

* search usages repo-wide
* preserve external contracts
* verify scene wiring after refactors

---

## Known temporary or transitional areas

* Tutorial compatibility hooks still exist for older references.
* Some scene-tree path coupling is still present and accepted for now.
* Lane layout tuning is still evolving (`USE_MANUAL_LANE_LAYOUT` currently enabled).
* Crossing behavior and row memory logic are still being iterated.

Avoid “cleaning up” these systems aggressively unless the change is intentional and tested.

---

## Current engineering philosophy

Prioritize:

* readable gameplay logic
* explicit behavior
* fast iteration
* Godot-native workflows

Small duplication is acceptable if it keeps gameplay code understandable.

Avoid premature abstraction.

---

## Possible bug candidates

* `Globals.wait(0.2)` appears to be called without `await` in `Player.gd`.
* If boost timing or cooldown behavior feels inconsistent, inspect this first.
