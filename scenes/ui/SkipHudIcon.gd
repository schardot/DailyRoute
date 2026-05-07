extends HudAnimatedIconButton


func _ready() -> void:
	super._ready()
	interacted.connect(_on_interacted)


func _on_interacted() -> void:
	var tutorial: Node = get_tree().current_scene
	if tutorial != null and tutorial.has_method("get_score"):
		SceneManager.set_pending_score(tutorial.call("get_score"))
	SceneManager.go_to_game()
