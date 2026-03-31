extends Node2D

const ASSIGNMENTS_TO_WIN := 5
const CROSSING_NPC_SCN: PackedScene = preload("res://scenes/entities/crossing/CrossingNpc.tscn")

var completed_assignments := 0 
var level_completed := false

@onready var world: Node2D  = $World
@onready var player: Node = world.get_player()
@onready var crowd_container: CrowdManager = world.get_crowd()
@onready var street = world.get_street()
@onready var car: Node2D = world.get_car()

var stores: Array = []

func _ready() -> void:
	add_to_group("game")
	
	init_player()
	init_stores()
	init_npcs()
	init_car()

	generate_assignment()

func generate_assignment() -> void:
	if level_completed:
		return

	var available_stores: Array = []

	for store in stores:
		if not store.completed:
			available_stores.append(store)

	if available_stores.is_empty():
		end_level()
		return

	var store = available_stores.pick_random()
	player.set_goal(store.color)

func on_assignment_completed(_completed_store: Area2D) -> void:
	if level_completed:
		return

	completed_assignments += 1
	call_deferred("spawn_crossing_npc")

	if completed_assignments >= ASSIGNMENTS_TO_WIN:
		end_level()
	else:
		crowd_container.call_deferred("spawn_npc")
		generate_assignment()

func end_level() -> void:
	level_completed = true
	player.clear_goal()
	SceneManager.go_to_end_screen()

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

func init_npcs():
	crowd_container.street = street
	if SceneManager.crowd_positions.size() > 0:
		for pos in SceneManager.crowd_positions:
			crowd_container.spawn_npc(pos)
		SceneManager.crowd_positions.clear()
	else:
		crowd_container.spawn_crowd_staggered()

func init_car() -> void:
	if not car:
		return
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
