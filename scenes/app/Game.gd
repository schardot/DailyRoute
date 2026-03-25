extends Node2D

const ASSIGNMENTS_TO_WIN := 5

var completed_assignments := 0 
var level_completed := false

@onready var world: Node2D  = $World
@onready var player: Node = world.get_player()
@onready var crowd_container: CrowdManager = $World/Entities/Crowd
@onready var street: Area2D = $World/Environment/Street

var stores: Array = []

func _ready() -> void:
	randomize()
	add_to_group("game")
	
	init_player()
	init_stores()
	init_npcs()

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

func on_assignment_completed() -> void:
	if level_completed:
		return

	completed_assignments += 1

	if completed_assignments >= ASSIGNMENTS_TO_WIN:
		end_level()
	else:
		crowd_container.spawn_npc()
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
		store.player_entered.connect(on_assignment_completed)
	assert(stores.size() > 0)

func init_npcs():
	crowd_container.street = street
	if SceneManager.crowd_positions.size() > 0:
		for pos in SceneManager.crowd_positions:
			crowd_container.spawn_npc(pos)
		SceneManager.crowd_positions.clear()
	else:
		crowd_container.spawn_crowd_staggered()
