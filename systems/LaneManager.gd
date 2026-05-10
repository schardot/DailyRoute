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

func generate_lanes() -> void:
	LanesArray.clear()

	var center_y: int = _get_center_y()
	var columns_by_type := _collect_columns()
	var car_groups: Array = _group_columns(columns_by_type.get("driveable", []))
	var crowd_groups: Array = _group_columns(columns_by_type.get("walkable", []))

	_append_manual_lane(LaneType.CAR, [1], Vector2.DOWN, car_groups, 0, center_y)
	_append_manual_lane(LaneType.CROWD_MEMBER, [1, 2, 3], Vector2.DOWN, crowd_groups, 0, center_y)
	_append_manual_lane(LaneType.CAR, [1], Vector2.UP, car_groups, 1, center_y)
	_append_manual_lane(LaneType.CROWD_MEMBER, [3, 1, 2], Vector2.DOWN, crowd_groups, 1, center_y)
	_append_manual_lane(LaneType.CAR, [1], Vector2.DOWN, car_groups, 2, center_y)
	_append_manual_lane(LaneType.CROWD_MEMBER, [1, 3, 1], Vector2.UP, crowd_groups, 2, center_y)
	_append_manual_lane(LaneType.CROWD_MEMBER, [1, 3, 1], Vector2.UP, crowd_groups, 3 , center_y)
	_append_manual_lane(LaneType.CAR, [1], Vector2.UP, car_groups, 3, center_y)

func set_tilemap(tm):
	tilemap = tm

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


func _get_center_y() -> int:
	var used_ = tilemap.get_used_rect()
	return int(used_.position.y + used_.size.y * 0.5)


func _append_manual_lane(lane_type: LaneType, line: Array, dir: Vector2, groups: Array, group_index: int, center_y: int) -> void:
	if groups.is_empty():
		return
	var idx: int = mini(group_index, groups.size() - 1)
	var lane_cols: Array = groups[idx]
	var center_x: int = lane_cols[int(lane_cols.size() * 0.5)]
	var world_pos: Vector2 = tilemap.map_to_local(Vector2i(center_x, center_y))
	LanesArray.append(LaneStruct.new(lane_type, line, dir, world_pos))
