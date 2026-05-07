extends Node2D

@onready var world: World = $World
@onready var delivery_truck: Node = $DeliveryTruck

func _ready():
	_disable_car_for_tutorial()
	_start_delivery_truck_intro()

func _disable_car_for_tutorial() -> void:
	var car_node: Node = world.get_car() if world and world.has_method("get_car") else null
	if not car_node:
		return
	if car_node.has_method("set_enabled"):
		car_node.call("set_enabled", false)
		return
	if car_node is Node2D:
		(car_node as Node2D).visible = false
	car_node.set_physics_process(false)
	car_node.set_process(false)
	var hitbox: Node = car_node.get_node_or_null("Hitbox")
	if hitbox and hitbox is Area2D:
		(hitbox as Area2D).monitoring = false

func _start_delivery_truck_intro() -> void:
	if not delivery_truck:
		return
	if delivery_truck.has_method("start_intro"):
		delivery_truck.call("start_intro")
