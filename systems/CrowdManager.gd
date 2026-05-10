extends Node2D
class_name CrowdManager

const CROWD_MEMBER_SCN: PackedScene = preload("res://scenes/entities/crowd/CrowdMember.tscn")
const OFFSCREEN_MARGIN_Y := 48.0

func spawn_npc(lane: LaneStruct, pos: Vector2 = Vector2.ZERO):
	var npc = CROWD_MEMBER_SCN.instantiate() as CrowdMember

	var spawn: Vector2

	if pos == Vector2.ZERO:
		spawn = _get_lane_spawn_position(lane)
	else:
		spawn = pos

	npc.global_position = spawn
	npc.lane = lane
	add_child(npc)

func _get_lane_spawn_position(lane: LaneStruct) -> Vector2:
	var half_h : float = Globals.get_world_half_height()
	var viewport_h := get_viewport().get_visible_rect().size.y
	var spawn_y: float = (-half_h - OFFSCREEN_MARGIN_Y) if lane.direction.y > 0.0 else (viewport_h + half_h + OFFSCREEN_MARGIN_Y)
	return Vector2(lane.center.x, spawn_y)

func spawn_line(line: Array, lane: LaneStruct) -> void:
	for i in line.size():
		var count: int = int(line[i])
		for j in count:
			spawn_npc(lane)
			await Globals.wait_short()
		if i < line.size() - 1:
			await Globals.wait_medium()
