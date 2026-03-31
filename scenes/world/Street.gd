extends Area2D
class_name Street

@onready var collision_shape : CollisionShape2D = $CollisionShape2D

const FIXED_LANES: int = 7

enum LaneType {
	EMPTY,
	CAR,
	CROWD_MEMBER,
	GROUP
}

var lane_layout: Array[LaneType] = [
	LaneType.CAR,          # 1
	LaneType.CROWD_MEMBER, # 2
	LaneType.CAR,        # 3
	LaneType.EMPTY,        # 4
	LaneType.CAR,          # 5
	LaneType.CROWD_MEMBER, # 6
	LaneType.EMPTY         # 7 (reserved for later)
]
var _lane_centers_cache: Dictionary = {}

func get_spawn_point() -> Vector2:
	return get_spawn_line(randf() < 0.5)

func get_lane_centers_x(world_margin: float) -> Array[float]:
	var cache_key: float = snappedf(world_margin, 0.01)
	if _lane_centers_cache.has(cache_key):
		return _lane_centers_cache[cache_key]

	var centers: Array[float] = []
	var rect: RectangleShape2D = _get_rect_shape()
	var half: Vector2 = rect.size * 0.5
	var min_x: float = -half.x + world_margin
	var max_x: float = half.x - world_margin
	assert(max_x > min_x, "Street lanes have no usable width for this world_margin")

	var lane_count: int = max(FIXED_LANES, 1)

	for i in range(lane_count):
		var t: float = (float(i) + 0.5) / float(lane_count)
		var local_x: float = lerp(min_x, max_x, t)
		var world_x: float = (collision_shape.global_transform * Vector2(local_x, 0.0)).x
		centers.append(world_x)

	_lane_centers_cache[cache_key] = centers
	return centers

func get_lane_index_for_world_x(world_x: float, world_margin: float) -> int:
	var centers: Array[float] = get_lane_centers_x(world_margin)
	assert(not centers.is_empty(), "Street lane centers must not be empty")

	var best_idx: int = 0
	var best_dist: float = abs(centers[0] - world_x)
	for i in range(1, centers.size()):
		var d: float = abs(centers[i] - world_x)
		if d < best_dist:
			best_dist = d
			best_idx = i

	return best_idx + 1 # 1-indexed

func _pick_lane_x_by_type(lane_type: LaneType, world_margin: float) -> float:
	var centers: Array[float] = get_lane_centers_x(world_margin)
	assert(not centers.is_empty(), "Street lane centers must not be empty")

	var options: Array[float] = []
	var lane_count: int = max(FIXED_LANES, 1)
	for i in range(lane_count):
		if i < lane_layout.size() and lane_layout[i] == lane_type:
			options.append(centers[i])

	assert(not options.is_empty(), "Street lane layout has no lanes for requested type")
	return options.pick_random()

func pick_lane_x_for_cars(world_margin: float) -> float:
	return _pick_lane_x_by_type(LaneType.CAR, world_margin)

func pick_lane_x_for_npcs(world_margin: float) -> float:
	return _pick_lane_x_by_type(LaneType.CROWD_MEMBER, world_margin)

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
