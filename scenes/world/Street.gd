extends Area2D

@onready var collision_shape : CollisionShape2D = $CollisionShape2D

func get_random_point() -> Vector2:
	var shape := collision_shape.shape
	
	if shape is RectangleShape2D:
		var half : Vector2 = shape.size / 2.0
		var local := Vector2(
			randf_range(-half.x, half.x),
			randf_range(-half.y, half.y)
		)
		return collision_shape.global_transform * local
	push_error("Street: unsupported collision shape")
	return global_position

func clamp_point_to_street(world_point: Vector2, world_margin: float) -> Vector2:
	var shape := collision_shape.shape

	if shape is RectangleShape2D:
		var inv := collision_shape.global_transform.affine_inverse()
		var local_point := inv * world_point

		var _scale := collision_shape.global_transform.get_scale()
		var local_margin : float = world_margin / max(_scale.x, _scale.y)

		var half_size : Vector2 = shape.size * 0.5

		local_point.x = clamp(
			local_point.x,
			-half_size.x + local_margin,
			half_size.x - local_margin
		)
		local_point.y = clamp(
			local_point.y,
			-half_size.y + local_margin,
			half_size.y - local_margin
		)

		return collision_shape.global_transform * local_point

	return collision_shape.global_position
	
