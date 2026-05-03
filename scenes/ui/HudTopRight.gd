extends Node

@export var show_skip_tutorial: bool = true


func _ready() -> void:
	var skip := get_node_or_null("HudCanvas/TopBar/SkipTutorialUi")
	if skip:
		skip.visible = show_skip_tutorial
