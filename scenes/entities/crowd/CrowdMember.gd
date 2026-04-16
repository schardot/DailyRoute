extends CharacterBody2D
class_name CrowdMember

var speed := 40.0
var time := 0.0

# ---- TUTORIAL SETTINGS ONLY
var has_target := false
var target_position: Vector2
var arrived := false
var dir_override : Vector2 = Vector2.ZERO

#signal pushed
# ----------------------------

var street: Area2D
#var push_offset: Vector2 = Vector2.ZERO
#var was_pushed := false
var lane : LaneStruct


@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready():
	pass

func _get_collision_shape() -> CollisionShape2D:
	if collision_shape:
		return collision_shape
	collision_shape = get_node_or_null("CollisionShape2D") as CollisionShape2D
	return collision_shape

func _process(delta):
	time += delta    
	var squash = sin(time * 4.0) * 0.05
	scale.x = 1.0 + squash
	scale.y = 1.0 - squash
		
func _physics_process(_delta):
	if lane == null:
		return
	if has_target:
		set_tutorial_npc()
	elif arrived:
		dir_override = Vector2.ZERO
	apply_velocity()
	move_and_slide()
	if lane:
		global_position.x = lane.center.x
	if street:
		var radius := get_world_radius()
		global_position = street.clamp_point_to_street(global_position, radius)
		_check_recycle()

func apply_velocity():
	if dir_override == Vector2.ZERO:
		velocity = Vector2(0, lane.direction.y) * speed
	else:
		velocity = Vector2(0, dir_override.y) * speed

func _check_recycle():
	if has_target or not lane:
		return
	var npc_half_height := 0.0
	var cs := _get_collision_shape()
	if not cs:
		return
	var s = cs.shape
	if s is CapsuleShape2D:
		npc_half_height = (s.height * 0.5 + s.radius) * cs.global_transform.get_scale().y
	var exit : int = street.get_y_exit(global_position, npc_half_height)
	if exit == 0:
		return
	var spawn_top := exit == 1
	global_position = street.get_spawn_line(spawn_top)
	global_position.x = lane.center.x
	#push_offset = Vector2.ZERO
	#was_pushed = false

#func apply_push(dir: Vector2):
	#was_pushed = true
	#push_offset += dir * 3000
	#emit_signal("pushed")

func get_world_radius() -> float:
	var cs := _get_collision_shape()
	if not cs:
		return 0.0
	return Globals.get_collision_shape_world_radius(cs)

func set_tutorial_npc():
	var dir = target_position - global_position

	if dir.length() < 5:
		dir_override = Vector2.ZERO
		has_target = false
		arrived = true
	else:
		arrived = false
		dir_override = dir.normalized()
