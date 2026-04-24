extends Node2D

@export var target_speed: float = 300.0
@export var accel: float = 900.0
@export var brake_decel: float = 1600.0
@export var brake_window_ahead_y: float = 260.0
@export var brake_window_behind_y: float = 0.0

var direction: Vector2 = Vector2.DOWN
var current_speed: float = 0.0
var velocity: Vector2 = Vector2.ZERO
var world_radius: float = 0.0
var world_half_height: float = 0.0
var lane : LaneStruct
const SPAWN_MARGIN_Y := 8.0

@onready var hitbox: Area2D = $Hitbox
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	world_radius = Globals.get_collision_shape_world_radius(collision_shape)
	world_half_height = _compute_world_half_height()
	if hitbox and not hitbox.body_entered.is_connected(_on_hitbox_body_entered):
		hitbox.body_entered.connect(_on_hitbox_body_entered)
 
func spawn_car(_street_ref = null) -> void:
	if lane == null:
		lane = _resolve_lane()
		if lane == null:
			return
	direction = lane.direction
	global_position = Vector2(lane.center.x, _get_spawn_y(direction.y > 0.0))
	if direction == Vector2.DOWN:
		$AnimatedSprite2D.play("car_blue_down")
	else:
		$AnimatedSprite2D.play("car_blue_up")
	current_speed = target_speed

func _physics_process(delta: float) -> void:
	var should_brake: bool = _should_brake_for_crossing_npc()
	var desired_speed: float = 0.0 if should_brake else target_speed
	var rate: float = brake_decel if should_brake else accel
	
	#var desired_speed: float = target_speed
	#var rate: float =  accel
	
	current_speed = move_toward(current_speed, desired_speed, rate * delta)

	velocity = direction * current_speed
	global_position += velocity * delta

	_clamp_to_street()
	_check_recycle()

func _should_brake_for_crossing_npc() -> bool:
	var my_lane := LaneManager.get_nearest_lane_by_type(global_position.x, LaneManager.LaneType.CAR)
	if my_lane == null:
		return false
	var candidates:= get_tree().get_nodes_in_group("crossing_npcs")

	for n in candidates:
		var npc:= n
		if npc.has_method("is_crossing_active") and not npc.call("is_crossing_active"):
			continue

		var dir_sign: float = sign(direction.y)
		if dir_sign == 0.0:
			dir_sign = 1.0
		var ahead_dist: float = (npc.global_position.y - global_position.y) * dir_sign
		if ahead_dist < -brake_window_behind_y:
			continue
		if ahead_dist > brake_window_ahead_y:
			continue

		var lane_width_px: float = LaneManager.get_car_lane_width_px()
		var half_lane_w : float = lane_width_px * 0.5
		if (npc.global_position.x > my_lane.center.x - half_lane_w &&
			npc.global_position.x < my_lane.center.x + half_lane_w):		
			return true

	return false

func _check_recycle() -> void:
	if lane == null:
		lane = _resolve_lane()
		if lane == null:
			return
	var top_y := _get_spawn_y(true)
	var bottom_y := _get_spawn_y(false)
	if direction.y > 0.0 and global_position.y > bottom_y:
		global_position = Vector2(lane.center.x, top_y)
	elif direction.y < 0.0 and global_position.y < top_y:
		global_position = Vector2(lane.center.x, bottom_y)

func _compute_world_half_height() -> float:
	if not collision_shape:
		return 0.0
	var shape := collision_shape.shape
	if shape is RectangleShape2D:
		var world_scale: Vector2 = collision_shape.global_transform.get_scale()
		return (shape.size.y * 0.5) * abs(world_scale.y)
	return world_radius

func _clamp_to_street() -> void:
	if lane == null:
		lane = _resolve_lane()
	if lane:
		global_position.x = lane.center.x

func _get_spawn_y(spawn_top: bool) -> float:
	var viewport_h := get_viewport_rect().size.y
	if spawn_top:
		return -world_half_height - SPAWN_MARGIN_Y
	return viewport_h + world_half_height + SPAWN_MARGIN_Y

func _resolve_lane() -> LaneStruct:
	if LaneManager.LanesArray.is_empty():
		return null
	return LaneManager.get_nearest_lane_by_type(global_position.x, LaneManager.LaneType.CAR)

func _on_hitbox_body_entered(body: Node) -> void:
	if body and body.is_in_group("player") and body.has_method("die"):
		body.call("die")
