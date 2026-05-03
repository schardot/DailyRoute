extends HudAnimatedIconButton


func _ready() -> void:
	super._ready()
	interacted.connect(_on_interacted)


func _on_interacted() -> void:
	SceneManager.go_to_game()
