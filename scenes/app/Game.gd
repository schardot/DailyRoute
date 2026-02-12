extends Node2D

const ASSIGNMENTS_TO_WIN := 5

@export var crowd_scene: PackedScene
@export var crowd_count := 100

var completed_assignments := 0
var level_completed := false

#@onready var player: Node = $World/Entities/Player
@onready var world: Node2D  = $World
@onready var player: Node = world.get_player()
@onready var street: Area2D = $World/Environment/Street
@onready var crowd_container: Node2D = $World/Entities/Crowd

var stores: Array = []


func _ready() -> void:
	randomize()

	add_to_group("game")

	# Collect all stores in scene
	stores = get_tree().get_nodes_in_group("stores")
	for store in stores:
		store.unblock_store()
	assert(stores.size() > 0)

	# Spawn crowd
	_spawn_crowd()

	# First assignment
	generate_assignment()


func _spawn_crowd() -> void:
	for i in range(crowd_count):
		var npc = crowd_scene.instantiate()
		npc.global_position = street.get_random_point()
		npc.street = street

		crowd_container.add_child(npc)


# =========================
# ASSIGNMENTS
# =========================

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

	print(
		"🎯 NEW ASSIGNMENT →",
		store.name,
		store.color
	)


func on_assignment_completed() -> void:
	if level_completed:
		return

	completed_assignments += 1
	print("✅ ASSIGNMENTS COMPLETED:", completed_assignments)

	if completed_assignments >= ASSIGNMENTS_TO_WIN:
		end_level()
	else:
		generate_assignment()


# =========================
# LEVEL END
# =========================

func end_level() -> void:
	level_completed = true
	player.clear_goal()
	print("🎄 LEVEL COMPLETED 🎄")
	SceneManager.go_to_end_screen()


# =========================
# INPUT
# =========================

func _unhandled_input(event):
	if event.is_action_pressed("ui_quit"):
		get_tree().quit()
