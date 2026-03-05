extends Node

var is_paused := false

func _ready():
	print("SceneManager READY")

# -----------------
# PAUSE
# -----------------

func toggle_pause():
	is_paused = !is_paused
	get_tree().paused = is_paused

func set_pause(value: bool):
	is_paused = value
	get_tree().paused = value
	
# -----------------
# SCENES
# -----------------

func go_to_tutorial():
	set_pause(false)
	get_tree().change_scene_to_file("res://scenes/app/Tutorial.tscn")

func go_to_game():
	set_pause(false)
	get_tree().change_scene_to_file("res://scenes/app/Game.tscn")

func go_to_end_screen():
	set_pause(false)
	get_tree().change_scene_to_file("res://scenes/app/EndScreen.tscn")
