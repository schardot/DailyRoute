extends Node2D
class_name CrowdManager

@export var crowd_count := 10
@onready var street: Area2D

const CROWD_MEMBER_SCN: PackedScene = preload("res://scenes/entities/crowd/CrowdMember.tscn")

func spawn_crowd() -> void:
	for i in range(crowd_count):
		spawn_npc()

func spawn_crowd_staggered(interval: float = 0.3) -> void:
	for i in range(crowd_count):
		spawn_npc()
		await get_tree().create_timer(interval).timeout

func spawn_npc(pos: Vector2 = Vector2.ZERO):
	var npc = CROWD_MEMBER_SCN.instantiate() as CrowdMember
	
	var spawn = pos if pos != Vector2.ZERO else street.get_spawn_point()
	npc.global_position = spawn
	
	npc.street = street
	npc.set_direction_from_spawn(spawn, street.get_center())

	add_child(npc)
