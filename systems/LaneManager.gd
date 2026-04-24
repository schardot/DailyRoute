extends Node

enum LaneType {
	EMPTY,
	CAR,
	CROWD_MEMBER,
	GROUP
}

const TILE_SIZE_PX: float = 32.0
const CAR_LANE_WIDTH_TILES: int = 3

var LanesArray = []
var tilemap: TileMapLayer


#func populate_lanes_array():
	#LanesArray.clear()
	#
	#LanesArray.append(LaneStruct.new(LaneType.CAR, [1], Vector2.DOWN, Vector2(lane_x(0), 0)))
	#LanesArray.append(LaneStruct.new(LaneType.CROWD_MEMBER, [1, 2, 3], Vector2.DOWN, Vector2(lane_x(1), 0)))
	#LanesArray.append(LaneStruct.new(LaneType.CAR, [1], Vector2.UP, Vector2(lane_x(2), 0)))
	#LanesArray.append(LaneStruct.new(LaneType.CROWD_MEMBER, [0], Vector2.UP, Vector2(lane_x(3), 0)))
	#LanesArray.append(LaneStruct.new(LaneType.CAR, [0], Vector2.DOWN, Vector2(lane_x(4), 0)))
	#LanesArray.append(LaneStruct.new(LaneType.CROWD_MEMBER, [1, 3, 1], Vector2.UP, Vector2(lane_x(5), 0)))
	#LanesArray.append(LaneStruct.new(LaneType.CAR, [0], Vector2.UP, Vector2(lane_x(6), 0)))

# ----- tileset

func set_tilemap(tm):
	tilemap = tm

# ----------------------------
# PUBLIC API
# ----------------------------

func get_random_lane_by_type(type: LaneType) -> LaneStruct:
	var options = []

	for lane in LanesArray:
		if lane.type == type:
			options.append(lane)

	assert(not options.is_empty(), "No lanes of requested type")
	return options.pick_random()

func get_random_lane_x(type: LaneType) -> float:
	return get_random_lane_by_type(type).center.x

func get_car_lane_width_px() -> float:
	return float(CAR_LANE_WIDTH_TILES) * TILE_SIZE_PX

func get_nearest_lane_by_type(world_x: float, lane_type: LaneType) -> LaneStruct:
	var best: LaneStruct = null
	var best_dist: float = INF

	for lane in LanesArray:
		if lane.type != lane_type:
			continue

		var d: float = abs(lane.center.x - world_x)

		if d < best_dist:
			best_dist = d
			best = lane

	assert(best != null, "No lanes found for requested type")
	return best

# ----------------------------
# LANE GENERATION
# ----------------------------

func generate_lanes():
	LanesArray.clear()

	var columns_by_type = _collect_columns()

	for type_key in columns_by_type.keys():
		var columns = columns_by_type[type_key]
		var grouped = _group_columns(columns)

		for i in range(grouped.size()):
			var lane_cols = grouped[i]

			var center_x: int = lane_cols[lane_cols.size() / 2]
			var center_y: int = _get_center_y()

			var world_pos: Vector2 = tilemap.map_to_local(Vector2i(center_x, center_y))

			var lane_type: LaneType = _map_type(type_key)
			var direction: Vector2 = _get_direction(lane_type, i)
			var spawn_line: Array = _get_spawn_pattern(lane_type, i)
			var lane_line: Array = lane_cols if lane_type == LaneType.CAR else spawn_line

			LanesArray.append(
				LaneStruct.new(
					lane_type,
					lane_line,
					direction,
					world_pos
				)
			)

# ----------------------------
# HELPERS
# ----------------------------

func _collect_columns() -> Dictionary:
	var result := {
		"driveable": [],
		"walkable": []
	}

	var used = tilemap.get_used_rect()

	for x in range(used.position.x, used.end.x):
		var column_data = null

		for y in range(used.position.y, used.end.y):
			var data = tilemap.get_cell_tile_data(Vector2i(x, y))
			if data:
				column_data = data
				break

		if not column_data:
			continue

		var is_non_walkable = bool(column_data.get_custom_data("non walkable"))
		var is_driveable = bool(column_data.get_custom_data("driveable"))
		var is_walkable = bool(column_data.get_custom_data("walkable"))

		if is_non_walkable:
			continue

		if is_driveable:
			result["driveable"].append(x)
		elif is_walkable:
			result["walkable"].append(x)

	return result


func _group_columns(columns: Array) -> Array:
	if columns.is_empty():
		return []

	columns.sort()

	var lanes = []
	var current = [columns[0]]

	for i in range(1, columns.size()):
		if columns[i] == columns[i - 1] + 1:
			current.append(columns[i])
		else:
			lanes.append(current)
			current = [columns[i]]

	lanes.append(current)
	return lanes


func _map_type(type_key: String) -> LaneType:
	match type_key:
		"driveable":
			return LaneType.CAR
		"walkable":
			return LaneType.CROWD_MEMBER
		_:
			return LaneType.EMPTY


func _get_direction(lane_type: LaneType, index: int) -> Vector2:
	if lane_type == LaneType.CAR:
		return Vector2.DOWN if index % 2 == 0 else Vector2.UP
	elif lane_type == LaneType.CROWD_MEMBER:
		return Vector2.UP  # or random later

	return Vector2.ZERO


func _get_spawn_pattern(lane_type: LaneType, index: int) -> Array:
	if lane_type == LaneType.CAR:
		return [0] if index % 2 == 0 else [1]
	elif lane_type == LaneType.CROWD_MEMBER:
		return [1, 2, 3]  # tweak later

	return []


func _get_center_y() -> int:
	var used_ = tilemap.get_used_rect()
	return used_.position.y + used_.size.y / 2
	
