extends Node2D
class_name CrowdManager

@export var crowd_count := 10
@onready var street: Area2D
var is_spawning := false

const CROWD_MEMBER_SCN: PackedScene = preload("res://scenes/entities/crowd/CrowdMember.tscn")

func spawn_npc(lane: LaneStruct, pos: Vector2 = Vector2.ZERO):
	var npc = CROWD_MEMBER_SCN.instantiate() as CrowdMember
	
	var spawn: Vector2
	
	if pos == Vector2.ZERO:
		spawn = lane.center
	else:
		spawn = pos
	 
	npc.global_position = spawn
	npc.street = street
	npc.lane = lane
	add_child(npc)

func _spawn_group(num: int, lane: LaneStruct):
	while num > 0:
		spawn_npc(lane)
		await Globals.wait_short()
		num -= 1

func spawn_line(line: Array[int], lane: LaneStruct):
	for value in line:
		await _spawn_group(value, lane)
		await Globals.wait_medium()
	
