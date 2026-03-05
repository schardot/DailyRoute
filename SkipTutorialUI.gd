extends CanvasLayer

@onready var skip_button: Button = $Control/SkipTutorialButton

func _ready():
	skip_button.pressed.connect(_on_skip_pressed)

func _on_skip_pressed():
	SceneManager.go_to_game()
