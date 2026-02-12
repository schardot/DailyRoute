extends Node2D

@onready var player = $Entities/Player
@onready var stores_container = $Entities/Stores

func get_player():
	return player

func get_stores() -> Array:
	return stores_container.get_children()
