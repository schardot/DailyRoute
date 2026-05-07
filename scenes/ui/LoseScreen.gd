extends Control

func _ready() -> void:
	var score_label: Label = $Panel/VBoxContainer/ScoreLabel
	if score_label:
		var score := SceneManager.last_run_score
		var hs := SceneManager.highscore
		if SceneManager.last_run_new_record:
			score_label.text = "New record! You beat your highscore.\nHighscore: %d\nScore: %d" % [hs, score]
		else:
			score_label.text = "Highscore: %d\nScore: %d" % [hs, score]

func _on_play_again_pressed() -> void:
	SceneManager.go_to_game()

