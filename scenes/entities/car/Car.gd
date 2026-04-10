extends Node2D

@export var target_speed: float = 300.0
@export var accel: float = 900.0
@export var brake_decel: float = 1600.0
@export var brake_window_ahead_y: float = 260.0
@export var brake_window_behind_y: float = 0.0

var street
var direction: Vector2 = Vector2.DOWN
var current_speed: float = 0.0
var velocity: Vector2 = Vector2.ZERO
var world_radius: float = 0.0
var world_half_height: float = 0.0
var lane : LaneStruct

@onready var hitbox: Area2D = $Hitbox
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	world_radius = Globals.get_collision_shape_world_radius(collision_shape)
	world_half_height = _compute_world_half_height()
	if hitbox and not hitbox.body_entered.is_connected(_on_hitbox_body_entered):
		hitbox.body_entered.connect(_on_hitbox_body_entered)
 
func spawn_car(street_ref) -> void:
	street = street_ref

	var spawn_pos: Vector2 = street.get_spawn_point()
	spawn_pos.x = LaneManager.get_random_lane_x(LaneManager.LaneType.CAR)
	global_position = spawn_pos

	var street_center: Vector2 = street.get_center()
	direction = Vector2.DOWN if spawn_pos.y < street_center.y else Vector2.UP
	_nudge_inside_street()
	current_speed = target_speed

func _physics_process(delta: float) -> void:
	#var should_brake: bool = _should_brake_for_crossing_npc()
	#var desired_speed: float = 0.0 if should_brake else target_speed
	#var rate: float = brake_decel if should_brake else accel
	
	var desired_speed: float = target_speed
	var rate: float =  accel
	
	current_speed = move_toward(current_speed, desired_speed, rate * delta)

	velocity = direction * current_speed
	global_position += velocity * delta

	_clamp_to_street()
	_check_recycle()

func _should_brake_for_crossing_npc() -> bool:
	if not street:
		return false

	var my_lane := LaneManager.get_nearest_lane_by_type(global_position.x, LaneManager.LaneType.CAR)
	var candidates:= get_tree().get_nodes_in_group("crossing_npcs")

	for n in candidates:
		if not (n is Node2D):
			continue
		var npc: Node2D = n
		if npc.has_method("is_crossing_active") and not npc.call("is_crossing_active"):
			continue

		# Brake only for crossers ahead of us (in our movement direction), not behind.
		var dir_sign: float = sign(direction.y)
		if dir_sign == 0.0:
			dir_sign = 1.0
		var ahead_dist: float = (npc.global_position.y - global_position.y) * dir_sign
		if ahead_dist < -brake_window_behind_y:
			continue
		if ahead_dist > brake_window_ahead_y:
			continue

		var npc_lane := LaneManager.get_nearest_lane_by_type(npc.global_position.x, LaneManager.LaneType.CAR)
		if npc_lane == my_lane:
			return true

	return false

func _check_recycle() -> void:
	if not street:
		return

	var exit: int = street.get_y_exit(global_position, world_half_height)
	if exit == 0:
		return

	var spawn_top: bool = exit == 1
	global_position = street.get_spawn_line(spawn_top)
	global_position.x = LaneManager.get_random_lane_x(LaneManager.LaneType.CAR)
	direction = Vector2.DOWN if spawn_top else Vector2.UP
	_nudge_inside_street()

func _nudge_inside_street() -> void:
	# Spawn lines are exactly on the street edge; nudge inside by our half-height
	# to avoid interacting with world bounds/colliders at the edges.
	if direction.y > 0.0:
		global_position.y += world_half_height
	else:
		global_position.y -= world_half_height

func _compute_world_half_height() -> float:
	if not collision_shape:
		return 0.0
	var shape := collision_shape.shape
	if shape is RectangleShape2D:
		var world_scale: Vector2 = collision_shape.global_transform.get_scale()
		return (shape.size.y * 0.5) * abs(world_scale.y)
	return world_radius

func _clamp_to_street() -> void:
	if not street:
		return
	global_position = street.clamp_point_to_street(global_position, world_radius)

func _on_hitbox_body_entered(body: Node) -> void:
	if body and body.is_in_group("player") and body.has_method("die"):
		body.call("die")
