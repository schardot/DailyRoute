extends Node2D

const CROSSING_NPC_SCN: PackedScene = preload("res://scenes/entities/crossing/CrossingNpc.tscn")

@onready var world: Node2D  = $World
@onready var player: Node = world.get_player()
@onready var crowd_container: CrowdManager = world.get_crowd()
@onready var street = world.get_street()
@onready var car: Node2D = world.get_car()

var stores: Array = []
var current_assignment_store: Area2D

func _ready() -> void:
	add_to_group("game")

	init_player()
	init_stores()
	init_lanes()

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
	player.set_goal(current_assignment_store.color)

func on_assignment_completed(_completed_store: Area2D) -> void:
	_completed_store.completed = false
	_completed_store.unblock_store()
	call_deferred("spawn_crossing_npc")
	crowd_container.call_deferred("spawn_npc")
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
	crowd_container.street = street
	if SceneManager.crowd_positions.size() > 0:
		for pos in SceneManager.crowd_positions:
			lane = LaneManager.get_nearest_lane_by_type(pos.x, LaneManager.LaneType.CROWD_MEMBER)
			crowd_container.spawn_npc(lane, pos)
		SceneManager.crowd_positions.clear()
	else:
		crowd_container.spawn_line(lane.line, lane)

func init_lanes():
	var i := 0
	for lane in LaneManager.LanesArray:	
		match lane.type:
			LaneManager.LaneType.CROWD_MEMBER:
					init_npcs(lane)
			LaneManager.LaneType.CAR:
					init_car(lane)
		i += 1

func init_car(lane: LaneStruct) -> void:
	if not car:
		return
	car.lane = lane
	car.spawn_car(street)

func spawn_crossing_npc() -> void:
	if not world:
		return

	var pair: Array = world.get_random_store_pair()
	if pair.size() < 2:
		return

	var from_store: Node2D = pair[0]
	var to_store: Node2D = pair[1]
	if randf() < 0.5:
		var tmp: Node2D = from_store
		from_store = to_store
		to_store = tmp

	var npc: CrossingNpc = CROSSING_NPC_SCN.instantiate() as CrossingNpc
	world.get_entities_root().add_child(npc)
	npc.z_index = 3
	npc.spawn_from_stores(from_store, to_store)
