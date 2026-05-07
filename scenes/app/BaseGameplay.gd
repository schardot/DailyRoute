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
	score_system = ScoreSystem.create((systems_root if systems_root != null else self), score_ui)
	return score_system

func create_assignment_system(stores_ref: Array) -> AssignmentSystem:
	assignment_system = AssignmentSystem.create((systems_root if systems_root != null else self), player, stores_ref)
	return assignment_system

func activate_crossings(chance: float, try_interval: float, row_memory_size: int) -> void:
	Crossings.activate(world, chance, try_interval, row_memory_size)
	_crossings_active = true

func init_delivery_truck_idle() -> void:
	if delivery_truck and delivery_truck.has_method("park_idle"):
		delivery_truck.call("park_idle")

func start_delivery_truck_intro() -> void:
	if delivery_truck and delivery_truck.has_method("start_intro"):
		delivery_truck.call("start_intro")

func disable_car() -> void:
	if not car:
		return
	if car.has_method("set_enabled"):
		car.call("set_enabled", false)
		return
	if car is Node2D:
		(car as Node2D).visible = false
	car.set_physics_process(false)
	car.set_process(false)
	var hitbox: Node = car.get_node_or_null("Hitbox")
	if hitbox and hitbox is Area2D:
		(hitbox as Area2D).monitoring = false

