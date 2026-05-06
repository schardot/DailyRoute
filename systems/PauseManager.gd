extends Node

signal pause_toggled(is_paused: bool)

var is_paused := false

func set_paused(value: bool) -> void:
	is_paused = value
	get_tree().paused = value
	emit_signal("pause_toggled", value)

func toggle_pause():
	set_paused(not is_paused)

func pause():
	set_paused(true)

func resume():
	set_paused(false)
