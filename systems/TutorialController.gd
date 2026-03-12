extends Node

@onready var world: Node2D = $"../World"
@onready var player: CharacterBody2D = $"../World/Entities/Player"
signal store_opened

var current_phase = 0
var assignment_order := [2, 7, 0, 9, 8, 1, 4, 3, 5, 6]
var stores: Array
var store_map := {}

func _ready() -> void:
	await get_tree().process_frame
	
	init_stores()
	
	generate_assignment()

func generate_assignment():
	var currentStoreNum : int = assignment_order[current_phase]
	var currentStoreNode : Node = store_map[currentStoreNum]
	
	player.set_goal(currentStoreNode.color)
	currentStoreNode.unblock_store()
	emit_signal("store_opened")
	apply_phase_movement_rules()

func on_assignment_completed() -> void:
	current_phase += 1
	
	if current_phase >= assignment_order.size():
		tutorial_complete()
		return
		
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

func tutorial_complete() -> void:
	player.clear_goal()
	reset_stores()
	SceneManager.player_position = player.global_position
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
	
