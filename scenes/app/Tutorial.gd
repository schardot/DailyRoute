extends  Node2D

func _ready():
	$TutorialController.store_opened.connect(_on_store_opened)
	_disable_car_for_tutorial()

func _on_store_opened():
	var sound: Node = get_node_or_null("/root/SoundController")
	if sound and sound.has_method("play_bell"):
		sound.call("play_bell")

func init_car() -> void:
	var world: Node = $World
	var car: Node = world.get_car() if world and world.has_method("get_car") else null
	if not car:
		return
	if car.has_method("spawn_car"):
		car.call("spawn_car")

func _disable_car_for_tutorial() -> void:
	var world: Node = $World
	var car: Node = world.get_car() if world and world.has_method("get_car") else null
	if not car:
		return
	# Keep it in the scene for later, but disable it for now.
	if car is Node2D:
		(car as Node2D).visible = false
	if car.has_method("set_physics_process"):
		car.call("set_physics_process", false)
	if car.has_method("set_process"):
		car.call("set_process", false)
	var hitbox: Node = car.get_node_or_null("Hitbox")
	if hitbox and hitbox.has_method("set"):
		hitbox.call("set", "monitoring", false)
