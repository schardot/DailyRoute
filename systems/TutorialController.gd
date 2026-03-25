extends Node

@onready var world: Node2D = $"../World"
@onready var player: CharacterBody2D = $"../World/Entities/Player"
@onready var crowd_member = $"../TutorialActors/CrowdMember"
@onready var stop_point = $"../Map/StoreEntrance/NpcStopPoint"
@onready var spawn_point = $"../Map/SpawnPoint/NpcSpawnPoint"
@onready var street: Area2D = $"../World/Environment/Street"
@onready var crowd_container: CrowdManager = $"../World/Entities/Crowd"
@onready var prompt := $"../SpaceToPushUi/TutorialPrompt"
signal store_opened

var current_phase = 0
var assignment_order := [2, 7, 0, 9, 8, 1, 4, 3, 5, 6]
var stores: Array
var store_map := {}
var first_push := false
var crowd_growth_started := false

func _ready() -> void:
	await get_tree().process_frame
	crowd_member.pushed.connect(_on_crowd_member_pushed)
	
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

func on_assignment_completed() -> void:
	current_phase += 1
	print("current phase: ", current_phase)
	if current_phase >= assignment_order.size():
		tutorial_complete()
		return
	
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
	crowd_member.target_position = stop_point.global_position
	crowd_member.has_target = true
	crowd_member.speed = 70
	crowd_member.global_position = spawn_point.global_position
	crowd_member.street = street

func _on_crowd_member_pushed():
	crowd_growth_started = true	
