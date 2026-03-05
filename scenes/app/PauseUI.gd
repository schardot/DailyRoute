extends CanvasLayer

@onready var pause_button: Button = $PauseButton
@onready var pause_menu = $PauseMenu

func _ready():
	pause_button.pressed.connect(_on_pause_pressed)
	pause_menu.visible = false

func _on_pause_pressed():
	PauseManager.pause()
	pause_menu.visible = true
