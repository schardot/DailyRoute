extends BaseGameplay

const CAR_SCENE: PackedScene = preload("res://scenes/entities/car/Car.tscn")

@export var crossing_spawn_chance: float = 0.2
@export var crossing_try_interval: float = 5.0
@export var crossing_row_memory_size: int = 2

func setup_run() -> void:
	create_score_system()
	score_system.init_from_pending_score()

	_init_player_from_handoff()
	var stores_ref := init_stores()
	create_assignment_system(stores_ref)
	assignment_system.assignment_completed.connect(on_assignment_completed)

	_init_lanes()
	delivery_truck.park_idle()
	
	activate_crossings(crossing_spawn_chance, crossing_try_interval, crossing_row_memory_size)
	assignment_system.start_random_assignment()

func on_assignment_completed(_completed_store: Area2D) -> void:
	player.deliver_box()
	score_system.add(1)
	assignment_system.start_random_assignment()

func _init_player_from_handoff() -> void:
	if SceneManager.player_position != Vector2.ZERO:
		player.global_position = SceneManager.player_position

func init_npcs(lane: LaneStruct):

	if SceneManager.crowd_positions.size() > 0:
		for pos in SceneManager.crowd_positions:
			lane = LaneManager.get_nearest_lane_by_type(pos.x, LaneManager.LaneType.CROWD_MEMBER)
			crowd_container.spawn_npc(lane, pos)
		SceneManager.crowd_positions.clear()
	else:
		crowd_container.spawn_line(lane.line, lane)

func _init_lanes():
	var car_lanes: Array[LaneStruct] = []
	for lane in LaneManager.LanesArray:	
		match lane.type:
			LaneManager.LaneType.CROWD_MEMBER:
				init_npcs(lane)
			LaneManager.LaneType.CAR:
				car_lanes.append(lane)

	if not car_lanes.is_empty():
		init_cars(car_lanes)

func init_cars(car_lanes: Array[LaneStruct]) -> void:
	if not car or car_lanes.is_empty():
		return

	car.lane = car_lanes[0]
	car.spawn_car()

	var parent_node: Node = car.get_parent()
	for i in range(1, car_lanes.size()):
		var extra_car: Node2D = CAR_SCENE.instantiate()
		extra_car.lane = car_lanes[i]
		parent_node.add_child(extra_car)
		extra_car.spawn_car()
