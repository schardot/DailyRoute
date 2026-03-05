extends CanvasLayer

@onready var pause_button: Button = $PauseButton
@onready var pause_menu = $PauseMenu

func _ready():
	pause_button.pressed.connect(_on_pause_pressed)
	pause_menu.visible = false
	PauseManager.pause_toggled.connect(_on_pause_toggled)

func _on_pause_pressed():
	PauseManager.toggle_pause()

func _input(event):
	if event.is_action_pressed("pause"):
		PauseManager.toggle_pause()

func _on_pause_toggled(is_paused: bool):
	pause_menu.visible = is_paused
