extends Node

enum LaneType {
	EMPTY,
	CAR,
	CROWD_MEMBER,
	GROUP
}

var LanesArray: Array[LaneStruct]
var street_width = 0.0
var street_center = 0.0
var lane_width = 0.0
const LANE_COUNT := 7

func set_street_bounds(w: float, center_x: float):
	street_width = w
	street_center = center_x
	lane_width = street_width / LANE_COUNT
	populate_lanes_array()

func lane_x(i):
	return street_center - street_width / 2 + (i + 0.5) * lane_width

func populate_lanes_array():
	LanesArray.clear()
	
	LanesArray.append(LaneStruct.new(LaneType.CAR, [1], Vector2.DOWN, Vector2(lane_x(0), 0)))
	LanesArray.append(LaneStruct.new(LaneType.CROWD_MEMBER, [1, 2, 3], Vector2.DOWN, Vector2(lane_x(1), 0)))
	LanesArray.append(LaneStruct.new(LaneType.CAR, [1], Vector2.UP, Vector2(lane_x(2), 0)))
	LanesArray.append(LaneStruct.new(LaneType.CROWD_MEMBER, [0], Vector2.UP, Vector2(lane_x(3), 0)))
	LanesArray.append(LaneStruct.new(LaneType.CAR, [0], Vector2.DOWN, Vector2(lane_x(4), 0)))
	LanesArray.append(LaneStruct.new(LaneType.CROWD_MEMBER, [1, 3, 1], Vector2.UP, Vector2(lane_x(5), 0)))
	LanesArray.append(LaneStruct.new(LaneType.CAR, [0], Vector2.UP, Vector2(lane_x(6), 0)))

func get_random_lane_by_type(type: LaneType) -> LaneStruct:
	var options: Array[LaneStruct] = []
	
	for lane in LanesArray:
		if lane.type == type:
			options.append(lane)
	
	assert(not options.is_empty(), "No lanes of requested type")
	return options.pick_random()

func get_random_lane_x(type:  LaneType) -> float:
	return get_random_lane_by_type(type).center.x

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
