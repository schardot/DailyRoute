extends Node2D

const ASSIGNMENTS_TO_WIN := 5

var completed_assignments := 0
var level_completed := false


@onready var player = $Player

var stores: Array = []


func _unhandled_input(event):
	if event.is_action_pressed("ui_quit"):
		get_tree().quit()

func _ready():
	add_to_group("game")
	stores = get_tree().get_nodes_in_group("stores")
	generate_assignment()

func on_assignment_completed():
	if level_completed:
		return

	completed_assignments += 1
	print("ASSIGNMENTS COMPLETED:", completed_assignments)

	if completed_assignments >= ASSIGNMENTS_TO_WIN:
		end_level()
	else:
		generate_assignment()

func generate_assignment():
	var available_stores: Array = []

	for store in stores:
		if not store.completed:
			available_stores.append(store)

	if available_stores.is_empty():
		print("⚠️ No available stores left")
		end_level()
		return

	var store = available_stores.pick_random()

	player.set_goal(store.color)

	print(
		"NEW ASSIGNMENT:",
		store.name,
		store.color
	)

func end_level():
	level_completed = true
	print("🎄 LEVEL COMPLETED 🎄")
	player.clear_goal()
