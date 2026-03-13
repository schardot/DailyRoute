extends CharacterBody2D
class_name CrowdMember

var speed := 40.0

# ---- TUTORIAL SETTINGS ONLY 
var has_target := false
var target_position: Vector2
var arrived := false
# ----------------------------

var street: Area2D
var direction := Vector2.ZERO
var push_offset: Vector2 = Vector2.ZERO
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready():
	pass

func _physics_process(_delta):
	if has_target:
		set_tutorial_npc()
	apply_velocity()
	move_and_slide()

	if street:
		var radius := get_world_radius()
		global_position = street.clamp_point_to_street(global_position, radius)

func apply_velocity():
	velocity = direction * speed
	if push_offset != Vector2.ZERO:
		velocity += push_offset
		push_offset = Vector2.ZERO

func apply_push(dir: Vector2):
	push_offset += dir * 3000

	
func _pick_new_direction():
	direction = Vector2(0, [-1, 1].pick_random())

func set_direction_from_spawn(spawn_pos: Vector2, street_center: Vector2):
	if spawn_pos.y < street_center.y:
		direction = Vector2.DOWN
	else:
		direction = Vector2.UP

func get_world_radius() -> float:
	var shape := collision_shape.shape
	var local_radius := 0.0

	if shape is CircleShape2D:
		local_radius = shape.radius
	elif shape is CapsuleShape2D:
		local_radius = shape.radius
	elif shape is RectangleShape2D:
		local_radius = max(shape.size.x, shape.size.y) * 0.5

	var _scale := collision_shape.global_transform.get_scale()
	return local_radius * max(_scale.x, _scale.y)

func set_tutorial_npc():
	var dir = target_position - global_position
		
	if dir.length() < 5:
		direction = Vector2.ZERO
		has_target = false
		speed = 0
	else:
		direction = dir.normalized()
