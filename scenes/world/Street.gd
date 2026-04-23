extends Area2D
class_name Street

@onready var collision_shape : CollisionShape2D = $CollisionShape2D

func _ready():
	var rect := _get_rect_shape()
	LaneManager.set_street_bounds(rect.size.x, collision_shape.global_position.x)

func get_spawn_point() -> Vector2:
	return get_spawn_line(randf() < 0.5)
	
func clamp_point_to_street(world_point: Vector2, world_margin: float) -> Vector2:
	var rect: RectangleShape2D = _get_rect_shape()
	var inv := collision_shape.global_transform.affine_inverse()
	var local_point := inv * world_point
	var half_size: Vector2 = rect.size * 0.5

	local_point.x = clamp(
		local_point.x,
		-half_size.x + world_margin,
		half_size.x - world_margin
	)

	return collision_shape.global_transform * local_point

func get_center() -> Vector2:
	return collision_shape.global_position

func get_spawn_line(top: bool) -> Vector2:
	var rect: RectangleShape2D = _get_rect_shape()
	var half: Vector2 = rect.size * 0.5
	var x := randf_range(-half.x, half.x)
	var y := -half.y if top else half.y
	return collision_shape.global_transform * Vector2(x, y)

func get_y_exit(world_pos: Vector2, margin: float = 0.0) -> int:
	var rect: RectangleShape2D = _get_rect_shape()
	var local_y := (collision_shape.global_transform.affine_inverse() * world_pos).y
	var half_y : float = rect.size.y * 0.5
	if local_y < -(half_y + margin):
		return -1
	if local_y > half_y + margin:
		return 1
	return 0
	
func _get_rect_shape() -> RectangleShape2D:
	var rect := collision_shape.shape as RectangleShape2D
	assert(rect != null, "Street requires RectangleShape2D")
	return rect
