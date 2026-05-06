extends Node

const SCRIPTED_EVENT_STORE_ID: int = 1
const SCRIPTED_EVENT_FROM_STORE_ID: int = 2
const SCRIPTED_EVENT_CAR_SPAWN_DELAY_SEC: float = 0.9
const TUTORIAL_CROSSING_SPAWN_CHANCE: float = 0.2
const TUTORIAL_CROSSING_TRY_INTERVAL: float = 5.0
const TUTORIAL_CROSSING_MEMORY_SIZE: int = 2

@onready var world: Node2D = $"../World"
var player: CharacterBody2D
@onready var crowd_member = $"../TutorialActors/CrowdMember"
@onready var hint = $"../BoostHintUi"
var crowd_container: CrowdManager
signal store_opened

var current_phase = 0
var assignment_order := [2, 7, 0, 9, 8, 1, 4, 3, 5, 6]
var stores: Array
var store_map := {}
var scripted_tutorial_event_done: bool = false
var scripted_tutorial_car_original_speed: float = 0.0
var crossing_manager: CrossingManager
var scripted_car_waiting_start: bool = false

var score: int = 0
@onready var score_ui: ScoreCounterUI = $"../HudTopRight/HudCanvas/TopBar/ScoreCounterUi"

func _ready() -> void:
	await get_tree().process_frame
	player = world.get_player()
	crowd_container = world.get_crowd()
	hint.set_target(player)
	crossing_manager = CrossingManager.new()
	add_child(crossing_manager)
	crossing_manager.configure(world, TUTORIAL_CROSSING_SPAWN_CHANCE, TUTORIAL_CROSSING_TRY_INTERVAL, TUTORIAL_CROSSING_MEMORY_SIZE)
	if player.has_signal("boost_used"):
		player.boost_used.connect(_on_player_boost_used)

	score = 0
	if score_ui:
		score_ui.reset()

	init_stores()
	init_npc()
	generate_assignment()

func generate_assignment():
	var currentStoreNum : int = assignment_order[current_phase]
	var currentStoreNode : Node = store_map[currentStoreNum]

	player.set_goal(currentStoreNode.color, currentStoreNode)
	player.pick_up_box(currentStoreNode.color, currentStoreNode)
	currentStoreNode.unblock_store()
	emit_signal("store_opened")
	apply_phase_movement_rules()
	if currentStoreNum == 0:
		hint.show_hint()
	if currentStoreNum == SCRIPTED_EVENT_STORE_ID and not scripted_tutorial_event_done:
		call_deferred("_start_scripted_tutorial_crossing_event")

func on_assignment_completed() -> void:
	player.deliver_box()
	score += 1
	if score_ui:
		score_ui.set_value(score)
	current_phase += 1
	if current_phase >= assignment_order.size():
		tutorial_complete()
		return

	var next_store_num: int = assignment_order[current_phase]
	if next_store_num != SCRIPTED_EVENT_STORE_ID and current_phase >= 1:
		call_deferred("_try_spawn_crossing_npc_with_chance")

	generate_assignment()

func apply_phase_movement_rules():
	match current_phase:
		0:
			player.set_movement(true, false, false, false)
		1:
			player.set_movement(true, true, false, false)
		2:
			player.set_movement(true, true, true, false)
		3:
			player.set_movement(true, true, true, true)

func tutorial_complete():
	player.clear_goal()
	reset_stores()
	SceneManager.player_position = player.global_position
	SceneManager.crowd_positions = []
	for npc in crowd_container.get_children():
		SceneManager.crowd_positions.append(npc.global_position)
	SceneManager.go_to_game()

func reset_stores():
	for store in stores:
		store.completed = false

func init_stores():
	stores = get_tree().get_nodes_in_group("stores")
	assert(stores.size() > 0)

	for store in stores:
		store_map[store.store_id] = store
		store.player_entered.connect(on_assignment_completed)

func init_npc():
	crowd_member.visible = false
	crowd_member.set_physics_process(false)
	#crowd_member.lane.direction = Vector2.ZERO
	crowd_member.velocity = Vector2.ZERO

func _on_crowd_member_pushed():
	pass

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
	var car: Node = world.get_car()
	if car == null:
		return

	if car is Node2D:
		(car as Node2D).visible = true
	car.set_process(true)
	car.set_physics_process(true)

	var hitbox: Area2D = car.get_node_or_null("Hitbox")
	if hitbox:
		hitbox.monitoring = true

	var lane: LaneStruct = _get_preferred_car_lane()
	if lane == null:
		return
	scripted_tutorial_car_original_speed = car.get("target_speed")
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
	var car: Node = world.get_car()
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
