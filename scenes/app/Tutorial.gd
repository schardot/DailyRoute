extends BaseGameplay

const SCRIPTED_EVENT_STORE_ID: int = 1
const SCRIPTED_EVENT_FROM_STORE_ID: int = 2
const SCRIPTED_EVENT_CAR_SPAWN_DELAY_SEC: float = 0.9
const TUTORIAL_CROSSING_SPAWN_CHANCE: float = 0.2
const TUTORIAL_CROSSING_TRY_INTERVAL: float = 5.0
const TUTORIAL_CROSSING_MEMORY_SIZE: int = 2

@onready var crowd_member = $TutorialActors/CrowdMember
@onready var hint = $BoostHintUi

signal store_opened

var current_phase: int = 0
var assignment_order := [2, 7, 0, 9, 8, 1, 4, 3, 5, 6]
var store_map := {}
var crossing_manager: CrossingManager
var current_assignment_store: Node = null
var scripted_tutorial_event_done: bool = false
var scripted_tutorial_car_original_speed: float = 0.0
var scripted_car_waiting_start: bool = false

func setup_run() -> void:
	disable_car()
	start_delivery_truck_intro()

	await get_tree().process_frame
	hint.set_target(player)

	crossing_manager = Crossings
	activate_crossings(TUTORIAL_CROSSING_SPAWN_CHANCE, TUTORIAL_CROSSING_TRY_INTERVAL, TUTORIAL_CROSSING_MEMORY_SIZE)

	if player.has_signal("boost_used"):
		player.boost_used.connect(_on_player_boost_used)

	create_score_system()
	score_system.reset()

	_init_stores()
	_init_npc()
	_generate_assignment()

func _init_stores() -> void:
	var stores_ref := init_stores()
	for store in stores_ref:
		store_map[store.store_id] = store

	create_assignment_system(stores_ref)
	assignment_system.assignment_started.connect(func(_s: Area2D) -> void: emit_signal("store_opened"))
	assignment_system.assignment_completed.connect(func(_s: Area2D) -> void: _on_assignment_completed())

func _generate_assignment() -> void:
	var current_store_num: int = assignment_order[current_phase]
	var current_store_node: Node = store_map[current_store_num]
	current_assignment_store = current_store_node

	assignment_system.start_assignment(current_store_node)
	_apply_phase_movement_rules()
	if current_store_num == 0:
		hint.show_hint()
	if current_store_num == SCRIPTED_EVENT_STORE_ID and not scripted_tutorial_event_done:
		call_deferred("_start_scripted_tutorial_crossing_event")

func _on_assignment_completed() -> void:
	player.deliver_box()
	score_system.add(1)
	current_phase += 1
	if current_phase >= assignment_order.size():
		_tutorial_complete()
		return

	var next_store_num: int = assignment_order[current_phase]
	if next_store_num != SCRIPTED_EVENT_STORE_ID and current_phase >= 1:
		call_deferred("_try_spawn_crossing_npc_with_chance")

	_generate_assignment()

func _apply_phase_movement_rules() -> void:
	match current_phase:
		0:
			player.set_movement(true, false, false, false)
		1:
			player.set_movement(true, true, false, false)
		2:
			player.set_movement(true, true, true, false)
		3:
			player.set_movement(true, true, true, true)

func _tutorial_complete() -> void:
	SceneManager.set_pending_score(score_system.score)
	_reset_stores()
	SceneManager.player_position = player.global_position
	SceneManager.crowd_positions = []
	for npc in crowd_container.get_children():
		SceneManager.crowd_positions.append(npc.global_position)
	SceneManager.go_to_game()

func _reset_stores() -> void:
	for store in stores:
		store.completed = false

func get_score() -> int:
	return score_system.score

func _init_npc() -> void:
	crowd_member.visible = false
	crowd_member.set_physics_process(false)
	crowd_member.velocity = Vector2.ZERO

func _on_player_boost_used() -> void:
	hint.hide_hint()

func _try_spawn_crossing_npc_with_chance() -> void:
	if crossing_manager == null:
		return
	crossing_manager.try_spawn_with_chance()

func _start_scripted_tutorial_crossing_event() -> void:
	if scripted_tutorial_event_done:
		return
	if crossing_manager == null:
		return
	scripted_tutorial_event_done = true

	var from_store: Node2D = store_map.get(SCRIPTED_EVENT_FROM_STORE_ID)
	var to_store: Node2D = world.get_paired_store(SCRIPTED_EVENT_FROM_STORE_ID)
	if from_store == null or to_store == null:
		return

	var npc: CrossingNpc = crossing_manager.spawn_crossing_npc(from_store, to_store)
	if npc == null:
		return
	npc.crossing_ended.connect(_on_scripted_crossing_ended)

	call_deferred("_start_scripted_car_for_crossing", npc.row_y)

func _spawn_scripted_tutorial_car() -> void:
	if car == null:
		return

	if car.has_method("set_enabled"):
		car.call("set_enabled", true)
	elif car is Node2D:
		(car as Node2D).visible = true
	car.set_process(true)
	car.set_physics_process(true)

	var hitbox: Area2D = car.get_node_or_null("Hitbox")
	if hitbox:
		hitbox.monitoring = true

	var lane: LaneStruct = _get_preferred_car_lane()
	if lane == null:
		return
	scripted_tutorial_car_original_speed = float(car.get("target_speed"))
	car.set("lane", lane)
	if car.has_method("spawn_car"):
		car.call("spawn_car")
		return
	car.set("direction", lane.direction)
	car.set("current_speed", scripted_tutorial_car_original_speed)

func _start_scripted_car_for_crossing(_row_y: float) -> void:
	scripted_car_waiting_start = true
	if SCRIPTED_EVENT_CAR_SPAWN_DELAY_SEC > 0.0:
		await get_tree().create_timer(SCRIPTED_EVENT_CAR_SPAWN_DELAY_SEC).timeout
	if not scripted_car_waiting_start:
		return
	_spawn_scripted_tutorial_car()

func _on_scripted_crossing_ended(_row_y: float) -> void:
	scripted_car_waiting_start = false
	if car == null:
		return
	car.set("target_speed", scripted_tutorial_car_original_speed)

func _get_preferred_car_lane() -> LaneStruct:
	var car_lanes: Array[LaneStruct] = []
	for lane: LaneStruct in LaneManager.LanesArray:
		if lane.type == LaneManager.LaneType.CAR:
			car_lanes.append(lane)

	if car_lanes.is_empty():
		return null

	var center_x: float = get_viewport().get_visible_rect().size.x * 0.5
	var best: LaneStruct = car_lanes[0]
	var best_width: int = best.line.size()
	var best_dist: float = absf(best.center.x - center_x)

	for lane: LaneStruct in car_lanes:
		var lane_width: int = lane.line.size()
		var dist: float = absf(lane.center.x - center_x)
		if lane_width > best_width or (lane_width == best_width and dist < best_dist):
			best = lane
			best_width = lane_width
			best_dist = dist

	return best
