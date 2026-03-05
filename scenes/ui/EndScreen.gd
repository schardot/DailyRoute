extends Control

func _on_play_again_pressed():
	SceneManager.go_to_game()

func _on_menu_pressed():
	SceneManager.go_to_menu()
