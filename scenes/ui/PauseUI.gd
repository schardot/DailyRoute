extends CanvasLayer

@onready var pause_hud: HudAnimatedIconButton = $TopBar/PauseHud


func _ready() -> void:
	pause_hud.interacted.connect(_on_pause_pressed)


func _on_pause_pressed() -> void:
	PauseManager.toggle_pause()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		PauseManager.toggle_pause()
