extends Node

signal pause_toggled(is_paused: bool)

var is_paused := false

func toggle_pause():
	is_paused = !is_paused
	get_tree().paused = is_paused
	emit_signal("pause_toggled", is_paused)

func pause():
	if is_paused:
		return
	is_paused = true
	get_tree().paused = true
	emit_signal("pause_toggled", true)

func resume():
	if not is_paused:
		return
	is_paused = false
	get_tree().paused = false
	emit_signal("pause_toggled", false)
