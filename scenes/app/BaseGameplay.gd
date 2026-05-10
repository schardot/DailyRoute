extends Node2D
class_name BaseGameplay

@onready var world: World = $World
@onready var systems_root: Node = $Systems
@onready var hud_top_right: Node = $HudTopRight
@onready var score_ui: ScoreCounterUI = $HudTopRight/HudCanvas/TopBar/ScoreCounterUi

@onready var player: CharacterBody2D = world.get_player()
@onready var crowd_container: CrowdManager = world.get_crowd()
@onready var car: Node = world.get_car()
@onready var delivery_truck: Node = world.get_delivery_truck()

var stores: Array = []
var score_system: ScoreSystem
var assignment_system: AssignmentSystem
var _crossings_active: bool = false

func _ready() -> void:
	setup_run()

func _exit_tree() -> void:
	if _crossings_active:
		Crossings.deactivate()
		_crossings_active = false

func setup_run() -> void:
	# Overridden by subclasses.
	pass

func init_stores() -> Array:
	stores = get_tree().get_nodes_in_group("stores")
	assert(stores.size() > 0)
	return stores

func create_score_system() -> ScoreSystem:
	score_system = ScoreSystem.create(systems_root, score_ui)
	return score_system

func create_assignment_system(stores_ref: Array) -> AssignmentSystem:
	assignment_system = AssignmentSystem.create(systems_root , player, stores_ref)
	return assignment_system

func activate_crossings(chance: float, try_interval: float, row_memory_size: int) -> void:
	Crossings.activate(world, chance, try_interval, row_memory_size)
	_crossings_active = true

func disable_car() -> void:
	if not car:
		return
	car.set_enabled(false)
