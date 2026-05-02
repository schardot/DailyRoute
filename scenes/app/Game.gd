extends Node2D

@onready var world: Node2D  = $World
@onready var player: CharacterBody2D = world.get_player()
@onready var crowd_container: CrowdManager = world.get_crowd()
@onready var car: Node2D = world.get_car()
@onready var delivery_truck: Node2D = $DeliveryTruck

const CAR_SCENE: PackedScene = preload("res://scenes/entities/car/Car.tscn")

@export var crossing_spawn_chance: float = 0.2
@export var crossing_try_interval: float = 5.0
@export var crossing_row_memory_size: int = 2

var crossing_manager: CrossingManager

var stores: Array = []
var current_assignment_store: Area2D

func _ready() -> void:
	add_to_group("game")
	crossing_manager = CrossingManager.new()
	add_child(crossing_manager)

	init_player()
	init_stores()
	init_tilemap()
	init_lanes()
	init_delivery_truck()
	crossing_manager.configure(world, crossing_spawn_chance, crossing_try_interval, crossing_row_memory_size)
	crossing_manager.start_auto_spawn()

	generate_assignment()

func generate_assignment() -> void:
	if stores.is_empty():
		return

	var available_stores: Array = []
	for store in stores:
		if store != current_assignment_store:
			available_stores.append(store)

	if available_stores.is_empty():
		available_stores = stores.duplicate()

	current_assignment_store = available_stores.pick_random()
	player.set_goal(current_assignment_store.color, current_assignment_store)

func on_assignment_completed(_completed_store: Area2D) -> void:
	_completed_store.completed = false
	_completed_store.unblock_store()
	#crowd_container.call_deferred("spawn_npc")
	generate_assignment()

# ---- INIT FUNCTIONS

func init_player():
	if SceneManager.player_position != Vector2.ZERO:
		player.global_position = SceneManager.player_position

func init_stores():
	stores = get_tree().get_nodes_in_group("stores")
	for store in stores:
		store.unblock_store()
		store.player_entered.connect(func() -> void: on_assignment_completed(store))
	assert(stores.size() > 0)

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

	# Reuse the scene car for the first lane, then instantiate one per remaining car lane.
	car.lane = car_lanes[0]
	car.spawn_car()

	var parent_node: Node = car.get_parent()
	for i in range(1, car_lanes.size()):
		var extra_car: Node2D = CAR_SCENE.instantiate()
		extra_car.lane = car_lanes[i]
		parent_node.add_child(extra_car)
		extra_car.spawn_car()

func init_tilemap():
	LaneManager.set_tilemap(world.get_tilemap())
	LaneManager.generate_lanes()

func init_delivery_truck() -> void:
	if not delivery_truck:
		return
	if delivery_truck.has_method("park_idle"):
		delivery_truck.park_idle()

