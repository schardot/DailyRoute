extends Node2D
class_name CrowdManager

@export var crowd_count := 10
@onready var player: CharacterBody2D
var is_spawning := false

const CROWD_MEMBER_SCN: PackedScene = preload("res://scenes/entities/crowd/CrowdMember.tscn")
const SPAWN_MARGIN_Y := 8.0

func spawn_npc(lane: LaneStruct, pos: Vector2 = Vector2.ZERO):
	var npc = CROWD_MEMBER_SCN.instantiate() as CrowdMember
	
	var spawn: Vector2
	
	if pos == Vector2.ZERO:
		spawn = _get_lane_spawn_position(npc, lane)
	else:
		spawn = pos
	 
	npc.global_position = spawn
	npc.player = player
	npc.lane = lane
	add_child(npc)

func _get_lane_spawn_position(npc: CrowdMember, lane: LaneStruct) -> Vector2:
	var radius := npc.get_world_radius()
	var viewport_h := get_viewport().get_visible_rect().size.y
	var spawn_y := -radius - SPAWN_MARGIN_Y if lane.direction.y > 0.0 else viewport_h + radius + SPAWN_MARGIN_Y
	return Vector2(lane.center.x, spawn_y)

func _spawn_group(num: int, lane: LaneStruct):
	while num > 0:
		spawn_npc(lane)
		await Globals.wait_short()
		num -= 1

func spawn_line(line: Array, lane: LaneStruct):
	for value in line:
		await _spawn_group(int(value), lane)
		await Globals.wait_medium()
	
