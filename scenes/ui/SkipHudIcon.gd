extends HudAnimatedIconButton


func _ready() -> void:
	super._ready()
	interacted.connect(_on_interacted)


func _on_interacted() -> void:
	var tutorial_controller: Node = get_tree().current_scene.get_node_or_null("TutorialController")
	if tutorial_controller != null and tutorial_controller.has_method("get_score"):
		SceneManager.set_pending_score(tutorial_controller.call("get_score"))
	SceneManager.go_to_game()
