# Game Design Document — Dash & Deliver

**Engine:** Godot 4 (2D)
**Genre:** Top-down arcade delivery
**Status:** Prototype / active development

---

## 1. Concept

Dash & Deliver is a single-player 2D top-down arcade game. The player is a delivery courier navigating a busy pedestrian street during the holiday rush. The goal is to make as many package deliveries as possible without being hit by a car.

The core tension comes from navigating a dynamic crowd and avoiding traffic while completing deliveries under no explicit time pressure — speed is rewarded by score, and death resets progress.

---

## 2. Game Flow

```
Title / Menu
    │
    ▼
Tutorial (scripted)
    │  10 deliveries, gradually unlocking movement
    │  carries over score + player position
    ▼
Main Game (endless loop)
    │  infinite deliveries, increasing chaos
    ├─ Hit by car → Lose Screen → retry or menu
    └─ (no win condition; score-driven)
```

### Scene transitions

| Trigger | Destination |
|---|---|
| Game start / menu | Tutorial |
| Tutorial complete (10 deliveries) | Main Game |
| Player hit by car | Lose Screen |
| Lose screen "Play Again" | Main Game |
| Lose screen "Menu" | Tutorial |

Score from the tutorial carries over into the first main game session.

---

## 3. Core Loop

1. **Assignment** — The system picks an available store (never the same as the last 2 assignments). The player's target store ID is set and the store opens its door.
2. **Pick-up** — The player receives a box visually matching the target store's color palette (via shader). The delivery truck is the implied source.
3. **Navigation** — The player walks the street with the box, weaving through crowd NPCs and avoiding cars. Crossing pedestrians may push the player sideways.
4. **Delivery** — The player enters the target store's Area2D collision zone. The delivery is validated by matching `goal_store_id` with `store_id`.
5. **Score** — Score increments by 1. The loop restarts from step 1.

If the player is hit by a car at any point, they die immediately and the run ends.

---

## 4. Player

### Input

| Action | Input |
|---|---|
| Move | Arrow keys (4-directional) |
| Boost / Push | Dedicated `push` action (configurable) |

### Movement

The player is a `CharacterBody2D` with a configurable `speed` (default 300 px/s). Movement is input-driven with velocity smoothing toward the desired direction (`move_toward` with rate = `speed × 6`).

Direction constraints can be set per-axis (`can_move_left`, `can_move_right`, `can_move_up`, `can_move_down`). This is used by the tutorial to gradually unlock directional freedom.

### Boost

Pressing the boost button instantly adds an impulse of 700 px/s in the current movement direction (or last known velocity direction if idle). The `is_boosting` flag is consumed the same frame. The boost has no cooldown in the current implementation.

The boost is the player's only active tool for getting through dense crowds quickly. It also triggers the `boost_used` signal, which the tutorial uses to hide the boost hint UI.

### Box carrying

When assigned a delivery, the player carries a visible box. The box is positioned in a direction-aware hand pose (up, down, left, right) and is tinted with the shader color of the target store. The box disappears on delivery.

### Death

If a car's `Hitbox` `Area2D` detects the player body, `Player.die()` is called. This plays a crash sound and immediately transitions to the lose screen. There is no health system or respawn.

---

## 5. World

### Layout

The world is a tilemap-based vertical street. Lanes are typed and generated at runtime by `LaneManager`:

| Lane type | Description |
|---|---|
| `CAR` | Cars travel vertically (up or down depending on lane) |
| `CROWD_MEMBER` | Crowd NPCs travel vertically (up or down) |

Lanes are grouped by tile column into contiguous bands (e.g. a 3-tile-wide crowd lane becomes one `LaneStruct`). Cars stay clamped to lane center X. Crowd members drift slightly within their lane width.

### Stores

Stores are placed on both sides of the street, paired by row. Each store is an `Area2D` with:

- A unique integer `store_id`
- Three color exports: `roof_color`, `wall_color`, `door_color` — applied via a shader material at startup
- A delivery validation zone (entering with the matching `goal_store_id` counts as a delivery)
- A blocking `StaticBody2D` that is disabled when the store is the active target, allowing the player to enter

Store pairs by row are used by the `CrossingManager` for pedestrian crossings.

### Delivery truck

A visually distinct truck is parked at row 0 (top of the street). In the tutorial it has a full entrance animation (drives in, door opens). In the main game it parks idle immediately. The truck marks the top boundary conceptually; its row is excluded from random crossing spawns.

---

## 6. Entities

### Cars

Cars are `Node2D`s (not `CharacterBody2D`s — they use manual position update). Each car:

- Travels vertically in its assigned lane at `target_speed` (default 300 px/s)
- Recycles from one screen edge to the other (top ↔ bottom)
- **Brakes** automatically when a `CrossingNpc` is active in its lane within a configurable window ahead
- Kills the player instantly via an `Area2D` hitbox

There can be multiple cars on screen simultaneously, one per car lane.

### Crowd members (CrowdMember)

Crowd members are `CharacterBody2D`s walking in their vertical crowd lane at a fixed speed. They use `move_and_slide()` for collision resolution. They do not avoid or acknowledge the player explicitly — all interaction is pure physics. Because they are on collision layer 3 (NPC) and the player's mask includes layer 3, the player is pushed/carried by NPCs moving through them. The NPC itself does not react (its `collision_mask = 0`).

Crowd members drift sideways within a `max_offset` range around their lane center, giving the crowd a natural feel.

They recycle off-screen (like cars), maintaining a persistent crowd density.

### Crossing NPCs (CrossingNpc)

Pedestrians that cross the street horizontally from one store to another. They:

- Spawn at a store's X position on a specific `row_y`
- Walk horizontally at `speed` (default 180 px/s) toward the paired store on the opposite side
- Lock their Y position every frame (they are always on the crossing row)
- Emit `crossing_started` when spawned, `crossing_ended` and `queue_free()` when they reach the destination
- Alert cars to brake via the `crossing_npcs` group and `is_crossing_active()`
- Push the player via the same physics mechanism as crowd members (`collision_layer = 4`, `collision_mask = 0`)

Crossing NPCs are spawned automatically on a timer (default: 20% chance every 5 seconds) from the `CrossingManager` autoload, using a row memory system to avoid repeating recent rows.

---

## 7. Systems

### AssignmentSystem

Manages the player's current delivery target.

- Picks a store from the available pool, excluding the last `store_memory_size` (default 2) stores to prevent repetition
- Calls `player.set_goal(store_id, store)` and `player.pick_up_box(store)` to arm the player
- Connects to `store.player_entered` to detect successful delivery
- Emits `assignment_started` and `assignment_completed` signals for orchestrator scenes to react to

### ScoreSystem

Thin wrapper over an integer score counter.

- Increments on delivery completion
- Syncs to the `ScoreCounterUI` node in the HUD
- Pushes current score to `SceneManager` on every update (for end/lose screen display)
- Supports `init_from_pending_score()` to carry tutorial score into the main game

### CrossingManager (autoload: `Crossings`)

Manages crossing NPC spawning.

- Activated per-scene with `activate(world, chance, interval, row_memory_size)`
- Uses a manual `Timer` node (not `create_timer`) so it can be stopped on deactivation
- Avoids recently used crossing rows via a ring-buffer memory (`crossing_row_memory_size`, default 2)
- Row 0 (delivery truck row) is always excluded from random spawns
- Can also spawn scripted crossings directly via `spawn_crossing_npc(from_store, to_store)`

### LaneManager (autoload)

Generates and exposes the lane layout at runtime from the world tilemap. Lanes are typed structs (`LaneStruct`) describing a band of columns with a direction, center, and tile line. Car and crowd lanes are generated separately and ordered manually in `generate_lanes()`.

### SceneManager (autoload)

Single source of truth for scene transitions and cross-scene state. Stores:

- Player position and crowd NPC positions (for tutorial → game handoff)
- Current score, last run score, highscore (with `user://save.cfg` persistence)
- Pending score (tutorial result carried into game)

### SoundController (autoload)

Handles all game audio. Provides named methods (`play_door_open`, `play_car_crash_random`, etc.). Mutable via `MuteHudIcon`.

### PauseManager (autoload)

Manages global pause state. Emits `pause_toggled(bool)`.

---

## 8. Tutorial

The tutorial is a separate scene (`Tutorial.tscn`) that inherits from `BaseGameplay`.

### Scripted assignment sequence

Assignments follow a fixed order: `[2, 7, 0, 9, 8, 1, 4, 3, 5, 6]` (store IDs). After all 10 are completed, the tutorial ends.

### Graduated movement unlock

| Phase | Movement allowed |
|---|---|
| 0 | Right only |
| 1 | Right + Left |
| 2 | Right + Left + Down |
| 3 | All directions |

### Scripted crossing event

When assignment for `store_id = 1` is generated, a scripted crossing NPC is spawned between stores 2 and its pair. After a 0.9 s delay, the tutorial car is also enabled. This choreographed sequence introduces both obstacles to the player.

The `scripted_car_waiting_start` flag cancels the car spawn if the crossing NPC finishes before the delay elapses.

### Tutorial → Game handoff

On completing all 10 tutorial deliveries:
- Score is stored as `pending_score` in `SceneManager`
- Player's `global_position` is passed to the main game
- Crowd NPC positions are passed and re-spawned in the same locations

The game feels continuous — there is no loading screen or visual break.

---

## 9. Scoring and Persistence

- Each successful delivery = **+1 point**
- Score is displayed live in the HUD (top-right)
- At run end (lose or tutorial complete), the score is finalized
- If the score exceeds the saved highscore, it is saved to `user://save.cfg`
- The lose/end screen displays: current score and highscore, with a "New record!" message if applicable

---

## 10. UI

| Screen / Element | Purpose |
|---|---|
| `ScoreCounterUI` | Live score display in-game (top bar) |
| `BoostHintUI` | Animated hint showing the boost action; hides after first boost use |
| `PauseUI` | Pause menu overlay |
| `MuteHudIcon` | Toggle game audio on/off |
| `SkipHudIcon` | Skip tutorial (tutorial scene only) |
| `RestartHudIcon` | Restart run from HUD |
| `EndScreen` | Shown after completing the tutorial cleanly (if implemented) |
| `LoseScreen` | Shown after player death; displays score + highscore; offers Play Again or Menu |

---

## 11. Tone and Aesthetics

- **Setting:** A busy pedestrian shopping street during the Christmas holiday rush
- **Style:** Top-down 2D pixel art with animated sprites
- **Palette:** Store fronts are individually coloured via a shader (roof, wall, door colors), giving each store a distinct identity. The player's box is tinted to match the target store's wall color, providing an unambiguous visual assignment cue.
- **Audio:** Sound effects for door open/close, car crash. Mutable.
- **Feel:** The game should feel slightly chaotic but readable — the player is always one boost away from threading through a gap.

---

## 12. Known design notes and open questions

- **No time limit.** Deliveries are score-driven, not time-driven. Players who play slowly still score; speed is rewarded only implicitly.
- **Death is instant and absolute.** A single car hit ends the run. This is intentional for arcade feel but may need a grace period or visual warning.
- **Crowd density is tuned manually** in `LaneManager.generate_lanes()` via per-lane spawn weights. This is the primary lever for difficulty.
- **Crossing NPC timing.** Spawn chance (20%) and interval (5 s) are balanced so crossings feel eventful but not overwhelming. These are exported per-scene.
- **Store repetition memory** (size 2) prevents the same store from appearing in back-to-back assignments but allows it to reappear after two others. Adjust `store_memory_size` in `AssignmentSystem` to tune variety.
- **No explicit difficulty scaling.** The main game loop does not increase car speed or crowd density over time. This is a candidate for future iteration.
