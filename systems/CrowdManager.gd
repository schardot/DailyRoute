extends Node2D
class_name CrowdManager

@export var crowd_count := 100
@onready var street: Area2D

const CROWD_MEMBER_SCN: PackedScene = preload("res://scenes/entities/crowd/CrowdMember.tscn")

func spawn_crowd() -> void:
	for i in range(crowd_count):
		var npc = CROWD_MEMBER_SCN.instantiate() as CrowdMember
		
		npc.global_position = street.get_random_point()
		npc.street = street

		add_child(npc)
