extends Node

const SCRIPTED_EVENT_STORE_ID: int = 1
const SCRIPTED_EVENT_FROM_STORE_ID: int = 2
const SCRIPTED_EVENT_CAR_LANE_INDEX: int = 2
const SCRIPTED_EVENT_BRAKE_DELAY_SEC: float = 1.0
const TUTORIAL_CROSSING_SPAWN_CHANCE: float = 0.2
const TUTORIAL_CROSSING_TRY_INTERVAL: float = 5.0
const TUTORIAL_CROSSING_MEMORY_SIZE: int = 2

@onready var world: Node2D = $"../World"
var player: CharacterBody2D
@onready var crowd_member = $"../TutorialActors/CrowdMember"
@onready var stop_point = $"../Map/StoreEntrance/NpcStopPoint"
@onready var spawn_point = $"../Map/SpawnPoint/NpcSpawnPoint"
@onready var hint = $"../BoostHintUi"
var street: Area2D
var crowd_container: CrowdManager
@onready var prompt := $"../SpaceToPushUi/TutorialPrompt"
signal store_opened

var current_phase = 0
var assignment_order := [2, 7, 0, 9, 8, 1, 4, 3, 5, 6]
var stores: Array
var store_map := {}
var first_push := false
var crowd_growth_started := false
var scripted_tutorial_event_done: bool = false
var scripted_tutorial_car_original_speed: float = 0.0
var scripted_crossing_active: bool = false
var crossing_manager: CrossingManager

func _ready() -> void:
	await get_tree().process_frame
	player = world.get_player()
	street = world.get_street()
	crowd_container = world.get_crowd()
	hint.set_target(player)
	crossing_manager = CrossingManager.new()
	add_child(crossing_manager)
	crossing_manager.configure(world, TUTORIAL_CROSSING_SPAWN_CHANCE, TUTORIAL_CROSSING_TRY_INTERVAL, TUTORIAL_CROSSING_MEMORY_SIZE)
	if player.has_signal("boost_used"):
		player.boost_used.connect(_on_player_boost_used)

	init_stores()
	init_npc()
	generate_assignment()

func generate_assignment():
	var currentStoreNum : int = assignment_order[current_phase]
	var currentStoreNode : Node = store_map[currentStoreNum]

	player.set_goal(currentStoreNode.color)
	currentStoreNode.unblock_store()
	emit_signal("store_opened")
	apply_phase_movement_rules()
	if currentStoreNum == 0:
		hint.show_hint()
	if currentStoreNum == SCRIPTED_EVENT_STORE_ID and not scripted_tutorial_event_done:
		call_deferred("_start_scripted_tutorial_crossing_event")

func on_assignment_completed() -> void:
	current_phase += 1
	if current_phase >= assignment_order.size():
		tutorial_complete()
		return

	var next_store_num: int = assignment_order[current_phase]
	if next_store_num != SCRIPTED_EVENT_STORE_ID:
		call_deferred("_spawn_crossing_npc")

	if crowd_growth_started:
		crowd_container.street = street
		crowd_container.call_deferred("spawn_npc")
		crowd_container.call_deferred("spawn_npc")

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
	crowd_growth_started = true

func _on_player_boost_used() -> void:
	hint.hide_hint()

func _spawn_crossing_npc() -> void:
	if crossing_manager == null:
		return
	crossing_manager.spawn_crossing_npc()

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
	npc.crossing_started.connect(_on_scripted_crossing_started)
	npc.crossing_ended.connect(_on_scripted_crossing_ended)

	_prepare_scripted_tutorial_car()

func _prepare_scripted_tutorial_car() -> void:
	var car: Node = world.get_car()
	if car == null:
		return

	if car is Node2D:
		(car as Node2D).visible = true
	car.set_process(true)
	car.set_physics_process(true)

	var hitbox: Area2D = car.get_node_or_null("Hitbox")
	if hitbox:
		# Keep tutorial focused on the braking behavior instead of punishing collisions.
		hitbox.monitoring = false

	if SCRIPTED_EVENT_CAR_LANE_INDEX < 0 or SCRIPTED_EVENT_CAR_LANE_INDEX >= LaneManager.LanesArray.size():
		return
	var lane: LaneStruct = LaneManager.LanesArray[SCRIPTED_EVENT_CAR_LANE_INDEX]
	if lane.type != LaneManager.LaneType.CAR:
		return
	var spawn_top: bool = lane.direction.y > 0.0
	var spawn_pos: Vector2 = street.get_spawn_line(spawn_top)
	spawn_pos.x = lane.center.x
	car.set("global_position", spawn_pos)

	car.set("street", street)
	car.set("direction", lane.direction)
	scripted_tutorial_car_original_speed = car.get("target_speed")
	car.set("current_speed", scripted_tutorial_car_original_speed)

func _on_scripted_crossing_started(_row_y: float) -> void:
	scripted_crossing_active = true
	await get_tree().create_timer(SCRIPTED_EVENT_BRAKE_DELAY_SEC).timeout
	if not scripted_crossing_active:
		return
	var car: Node = world.get_car()
	if car == null:
		return
	car.set("target_speed", 0.0)

func _on_scripted_crossing_ended(_row_y: float) -> void:
	scripted_crossing_active = false
	var car: Node = world.get_car()
	if car == null:
		return
	car.set("target_speed", scripted_tutorial_car_original_speed)
