extends CanvasLayer

@onready var restart_button: Button = $VBoxContainer/RestartButton
@onready var resume_button: Button = $VBoxContainer/ResumeButton

func _ready():
	restart_button.pressed.connect(_on_restart_pressed)
	resume_button.pressed.connect(_on_resume_pressed)

func _on_restart_pressed():
	PauseManager.resume()
	SceneManager.go_to_tutorial()

func _on_resume_pressed():
	self.visible = false
	PauseManager.resume()
