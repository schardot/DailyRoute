extends Node
class_name AssignmentSystem

signal assignment_started(store: Area2D)
signal assignment_completed(store: Area2D)

var player: CharacterBody2D
var stores: Array = []
var current_store: Area2D

static func create(parent: Node, player_ref: CharacterBody2D, stores_ref: Array) -> AssignmentSystem:
	var sys := AssignmentSystem.new()
	if parent != null:
		parent.add_child(sys)
	sys.configure(player_ref, stores_ref)
	return sys

func configure(player_ref: CharacterBody2D, stores_ref: Array) -> void:
	player = player_ref
	stores = stores_ref
	_connect_store_signals()

func _connect_store_signals() -> void:
	for store in stores:
		if store == null:
			continue
		store.unblock_store()
		# `player_entered` has no args in this project, so bind store.
		store.player_entered.connect(func() -> void: _on_store_entered(store))

func start_assignment(store: Area2D) -> void:
	if store == null or player == null:
		return
	current_store = store

	player.set_goal(store.store_id, store)
	player.pick_up_box(store)
	store.call("play_animation", "door_open")
	assignment_started.emit(store)

func start_random_assignment(avoid_same_as_current: bool = true) -> void:
	if stores.is_empty():
		return
	var chosen: Area2D = _pick_store(current_store if avoid_same_as_current else null)
	start_assignment(chosen)

func _pick_store(exclude: Area2D) -> Area2D:
	var available: Array = []
	for s in stores:
		if s != exclude:
			available.append(s)
	if available.is_empty():
		available = stores.duplicate()
	return available.pick_random()

func _on_store_entered(store: Area2D) -> void:
	if store == null:
		return
	if current_store != null and store != current_store:
		return
	_complete_assignment(store)

func _complete_assignment(store: Area2D) -> void:
	store.call("play_animation", "door_close")
	if "completed" in store:
		store.completed = false
	store.call("unblock_store")
	current_store = null
	assignment_completed.emit(store)
