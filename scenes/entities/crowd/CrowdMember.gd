extends CharacterBody2D
class_name CrowdMember

var speed := 40.0

# ---- TUTORIAL SETTINGS ONLY 
var has_target := false
var target_position: Vector2
var arrived := false
signal pushed
# ----------------------------

var street: Area2D
var direction := Vector2.ZERO
var push_offset: Vector2 = Vector2.ZERO
var separation_velocity: Vector2 = Vector2.ZERO
var was_pushed := false

const SEPARATION_STRENGTH = 60.0
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready():
	pass

func _physics_process(_delta):
	if has_target:
		set_tutorial_npc()
	elif was_pushed and direction == Vector2.ZERO:
		_pick_new_direction()
		was_pushed = false
	apply_velocity()
	move_and_slide()
	_resolve_npc_collisions()

	if street:
		var radius := get_world_radius()
		global_position = street.clamp_point_to_street(global_position, radius)

func apply_velocity():
	velocity = direction * speed
	if push_offset != Vector2.ZERO:
		velocity += push_offset
		push_offset = Vector2.ZERO
	if separation_velocity != Vector2.ZERO:
		velocity += separation_velocity
		separation_velocity = Vector2.ZERO

func _resolve_npc_collisions():
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider is CrowdMember:
			var diff = global_position.x - collider.global_position.x
			var side = sign(diff) if abs(diff) > 0.5 else (1.0 if randf() > 0.5 else -1.0)
			separation_velocity.x += side * SEPARATION_STRENGTH

func apply_push(dir: Vector2):
	was_pushed = true
	push_offset += dir * 3000
	emit_signal("pushed")

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
	else:
		direction = dir.normalized()
