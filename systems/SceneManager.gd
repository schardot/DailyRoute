extends Node

var player_position: Vector2 = Vector2.ZERO
var crowd_positions: Array = []

func go_to_tutorial():
	PauseManager.set_paused(false)
	get_tree().call_deferred("change_scene_to_file", "res://scenes/app/Tutorial.tscn")

func go_to_game():
	PauseManager.set_paused(false)
	get_tree().call_deferred("change_scene_to_file", "res://scenes/app/Game.tscn")

func go_to_menu():
	go_to_tutorial()

func go_to_end_screen():
	PauseManager.set_paused(false)
	get_tree().call_deferred("change_scene_to_file", "res://scenes/ui/EndScreen.tscn")

func go_to_lose_screen():
	PauseManager.set_paused(false)
	get_tree().call_deferred("change_scene_to_file", "res://scenes/ui/LoseScreen.tscn")
