extends Node

const CROSSING_NPC_SCN: PackedScene = preload("res://scenes/entities/crossing/CrossingNpc.tscn")

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

func _ready() -> void:
	await get_tree().process_frame
	player = world.get_player()
	street = world.get_street()
	crowd_container = world.get_crowd()
	hint.set_target(player)
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

func on_assignment_completed() -> void:
	current_phase += 1
	if current_phase >= assignment_order.size():
		tutorial_complete()
		return

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
