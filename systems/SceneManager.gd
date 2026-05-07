extends Node

var player_position: Vector2 = Vector2.ZERO
var crowd_positions: Array = []
var pending_score: int = 0
var has_pending_score: bool = false

var current_score: int = 0
var last_run_score: int = 0
var highscore: int = 0
var last_run_new_record: bool = false

const SAVE_PATH := "user://save.cfg"
const SAVE_SECTION := "scores"
const SAVE_HIGHSCORE_KEY := "highscore"

func _ready() -> void:
	_load_highscore()

func _load_highscore() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(SAVE_PATH)
	if err != OK:
		highscore = 0
		return
	highscore = int(cfg.get_value(SAVE_SECTION, SAVE_HIGHSCORE_KEY, 0))
	if highscore < 0:
		highscore = 0

func _save_highscore() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value(SAVE_SECTION, SAVE_HIGHSCORE_KEY, highscore)
	cfg.save(SAVE_PATH)

func set_current_score(value: int) -> void:
	current_score = maxi(value, 0)

func get_current_score() -> int:
	return current_score

func get_highscore() -> int:
	return highscore

func finalize_run_score() -> void:
	last_run_score = current_score
	last_run_new_record = last_run_score > highscore
	if last_run_new_record:
		highscore = last_run_score
		_save_highscore()

func set_pending_score(value: int) -> void:
	pending_score = max(value, 0)
	has_pending_score = true

func consume_pending_score() -> int:
	if not has_pending_score:
		return 0
	has_pending_score = false
	return pending_score

func clear_pending_score() -> void:
	pending_score = 0
	has_pending_score = false

func go_to_tutorial():
	PauseManager.set_paused(false)
	clear_pending_score()
	set_current_score(0)
	get_tree().call_deferred("change_scene_to_file", "res://scenes/app/Tutorial.tscn")

func go_to_game():
	PauseManager.set_paused(false)
	get_tree().call_deferred("change_scene_to_file", "res://scenes/app/Game.tscn")

func go_to_menu():
	go_to_tutorial()

func go_to_end_screen():
	PauseManager.set_paused(false)
	finalize_run_score()
	get_tree().call_deferred("change_scene_to_file", "res://scenes/ui/EndScreen.tscn")

func go_to_lose_screen():
	PauseManager.set_paused(false)
	finalize_run_score()
	get_tree().call_deferred("change_scene_to_file", "res://scenes/ui/LoseScreen.tscn")
