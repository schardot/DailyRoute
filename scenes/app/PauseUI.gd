extends CanvasLayer

@onready var pause_button: Button = $Control/PauseButton

func _ready():
	pause_button.pressed.connect(_on_pause_pressed)

func _on_pause_pressed():
	PauseManager.toggle_pause()
