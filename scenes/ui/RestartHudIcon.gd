extends HudAnimatedIconButton


func _ready() -> void:
	super._ready()
	interacted.connect(_on_restart_interacted)


func _on_restart_interacted() -> void:
	PauseManager.resume()
	SceneManager.go_to_tutorial()
