extends Node

var player_position: Vector2 = Vector2.ZERO
var crowd_positions: Array = []

# -----------------
# PAUSE
# -----------------

func toggle_pause():
	get_tree().paused = !get_tree().paused

func set_pause(value: bool):
	get_tree().paused = value
	
# -----------------
# SCENES
# -----------------

func go_to_tutorial():
	set_pause(false)
	get_tree().call_deferred("change_scene_to_file", "res://scenes/app/Tutorial.tscn")

func go_to_game():
	set_pause(false)
	get_tree().call_deferred("change_scene_to_file", "res://scenes/app/Game.tscn")

func go_to_end_screen():
	set_pause(false)
	get_tree().call_deferred("change_scene_to_file", "res://scenes/ui/EndScreen.tscn")

func go_to_lose_screen():
	set_pause(false)
	get_tree().call_deferred("change_scene_to_file", "res://scenes/ui/LoseScreen.tscn")
