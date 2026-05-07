extends Node2D

@onready var world: Node2D  = $World
@onready var player: CharacterBody2D = world.get_player()
@onready var crowd_container: CrowdManager = world.get_crowd()
@onready var car: Node2D = world.get_car()
@onready var delivery_truck: Node2D = $DeliveryTruck
@onready var score_ui: ScoreCounterUI = $HudTopRight/HudCanvas/TopBar/ScoreCounterUi

const CAR_SCENE: PackedScene = preload("res://scenes/entities/car/Car.tscn")

@export var crossing_spawn_chance: float = 0.2
@export var crossing_try_interval: float = 5.0
@export var crossing_row_memory_size: int = 2

var crossing_manager: CrossingManager

var stores: Array = []
var score_system: ScoreSystem
var assignment_system: AssignmentSystem

func _ready() -> void:
	var systems: Node = $Systems
	score_system = ScoreSystem.create((systems if systems != null else self), score_ui)
	score_system.init_from_pending_score()

	init_player()
	init_stores_and_assignments()
	init_lanes()
	init_delivery_truck()
	crossing_manager = Crossings
	crossing_manager.activate(world, crossing_spawn_chance, crossing_try_interval, crossing_row_memory_size)

	assignment_system.start_random_assignment()

func _exit_tree() -> void:
	if crossing_manager:
		crossing_manager.deactivate()

func on_assignment_completed(_completed_store: Area2D) -> void:
	player.deliver_box()
	score_system.add(1)
	assignment_system.start_random_assignment()

func init_player():
	if SceneManager.player_position != Vector2.ZERO:
		player.global_position = SceneManager.player_position

func init_stores_and_assignments():
	stores = get_tree().get_nodes_in_group("stores")
	assert(stores.size() > 0)
	var systems: Node = $Systems
	assignment_system = AssignmentSystem.create((systems if systems != null else self), player, stores)
	assignment_system.assignment_completed.connect(on_assignment_completed)

func init_npcs(lane: LaneStruct):
	crowd_container.player = player
	if SceneManager.crowd_positions.size() > 0:
		for pos in SceneManager.crowd_positions:
			lane = LaneManager.get_nearest_lane_by_type(pos.x, LaneManager.LaneType.CROWD_MEMBER)
			crowd_container.spawn_npc(lane, pos)
		SceneManager.crowd_positions.clear()
	else:
		crowd_container.spawn_line(lane.line, lane)

func init_lanes():
	var car_lanes: Array[LaneStruct] = []
	for lane in LaneManager.LanesArray:	
		match lane.type:
			LaneManager.LaneType.CROWD_MEMBER:
				init_npcs(lane)
			LaneManager.LaneType.CAR:
				car_lanes.append(lane)

	if not car_lanes.is_empty():
		init_cars(car_lanes)

func init_cars(car_lanes: Array[LaneStruct]) -> void:
	if not car or car_lanes.is_empty():
		return

	car.lane = car_lanes[0]
	car.spawn_car()

	var parent_node: Node = car.get_parent()
	for i in range(1, car_lanes.size()):
		var extra_car: Node2D = CAR_SCENE.instantiate()
		extra_car.lane = car_lanes[i]
		parent_node.add_child(extra_car)
		extra_car.spawn_car()

func init_delivery_truck() -> void:
	if not delivery_truck:
		return
	if delivery_truck.has_method("park_idle"):
		delivery_truck.park_idle()
