extends Node2D

@onready var world: World = $World
@onready var tutorial_controller: Node = $TutorialController
@onready var delivery_truck: Node = $DeliveryTruck

func _ready():
	tutorial_controller.store_opened.connect(_on_store_opened)
	_disable_car_for_tutorial()
	_start_delivery_truck_intro()

func _on_store_opened():
	var sound: Node = get_node_or_null("/root/SoundController")
	if sound and sound.has_method("play_bell"):
		sound.call("play_bell")

func init_car() -> void:
	var car: Node = world.get_car() if world and world.has_method("get_car") else null
	if not car:
		return
	if car.has_method("spawn_car"):
		car.call("spawn_car")

func _disable_car_for_tutorial() -> void:
	var car: Node = world.get_car() if world and world.has_method("get_car") else null
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

func _start_delivery_truck_intro() -> void:
	if not delivery_truck:
		return
	if delivery_truck.has_method("start_intro"):
		delivery_truck.call("start_intro")
