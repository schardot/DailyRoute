extends CharacterBody2D

@export var speed := 60.0
@export var street: Area2D

var direction := Vector2.ZERO

func _ready():
	_pick_new_direction()

func _physics_process(_delta):
	velocity = direction * speed
	move_and_slide()
	if street:
		_keep_inside_street()

	if randi() % 120 == 0:
		_pick_new_direction()

func _pick_new_direction():
	direction = Vector2(
		randf_range(-1, 1),
		randf_range(-1, 1)
	).normalized()

func _keep_inside_street():
	var shape = street.get_node("CollisionShape2D").shape
	var xform = street.global_transform

	# Convert crowd position into street-local space
	var local_pos = xform.affine_inverse() * global_position

	if shape is RectangleShape2D:
		var extents = shape.extents
		local_pos.x = clamp(local_pos.x, -extents.x, extents.x)
		local_pos.y = clamp(local_pos.y, -extents.y, extents.y)

		# Convert back to world space
		global_position = xform * local_pos
