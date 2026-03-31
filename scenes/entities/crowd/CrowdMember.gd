extends CharacterBody2D
class_name CrowdMember

var speed := 40.0
const MOVE_DIR: Vector2 = Vector2.DOWN

# ---- TUTORIAL SETTINGS ONLY
var has_target := false
var target_position: Vector2
var arrived := false
signal pushed
# ----------------------------

var street: Area2D
var direction := Vector2.ZERO
var push_offset: Vector2 = Vector2.ZERO
var was_pushed := false

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready():
	pass

func _get_collision_shape() -> CollisionShape2D:
	if collision_shape:
		return collision_shape
	collision_shape = get_node_or_null("CollisionShape2D") as CollisionShape2D
	return collision_shape

func _physics_process(_delta):
	if has_target:
		set_tutorial_npc()
	elif arrived:
		direction = Vector2.ZERO
	else:
		direction = MOVE_DIR
	apply_velocity()
	move_and_slide()

	if street:
		var radius := get_world_radius()
		global_position = street.clamp_point_to_street(global_position, radius)
		_check_recycle()

func apply_velocity():
	velocity = direction * speed
	if push_offset != Vector2.ZERO:
		velocity += push_offset
		push_offset = Vector2.ZERO

func _check_recycle():
	if has_target:
		return
	var npc_half_height := 0.0
	var cs := _get_collision_shape()
	if not cs:
		return
	var s = cs.shape
	if s is CapsuleShape2D:
		npc_half_height = s.height / 2.0 * cs.global_transform.get_scale().y
	var exit : int = street.get_y_exit(global_position, npc_half_height)
	if exit == 0:
		return
	var spawn_top := exit == 1
	global_position = street.get_spawn_line(spawn_top)
	if street and street.has_method("pick_lane_x_for_npcs"):
		var radius: float = get_world_radius()
		global_position.x = street.call("pick_lane_x_for_npcs", radius)
	direction = MOVE_DIR
	push_offset = Vector2.ZERO
	was_pushed = false

func apply_push(dir: Vector2):
	was_pushed = true
	push_offset += dir * 3000
	emit_signal("pushed")

func set_direction_from_spawn(_spawn_pos: Vector2, _street_center: Vector2):
	direction = MOVE_DIR

func get_world_radius() -> float:
	var cs := _get_collision_shape()
	if not cs:
		return 0.0
	return Globals.get_collision_shape_world_radius(cs)

func set_tutorial_npc():
	var dir = target_position - global_position

	if dir.length() < 5:
		direction = Vector2.ZERO
		has_target = false
		arrived = true
	else:
		arrived = false
		direction = dir.normalized()
