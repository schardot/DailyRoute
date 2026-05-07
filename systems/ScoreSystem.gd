extends Node
class_name ScoreSystem

var score: int = 0
var score_ui: ScoreCounterUI

static func create(parent: Node, ui: ScoreCounterUI = null) -> ScoreSystem:
	var sys := ScoreSystem.new()
	if parent != null:
		parent.add_child(sys)
	if ui != null:
		sys.bind_ui(ui)
	return sys

func bind_ui(ui: ScoreCounterUI) -> void:
	score_ui = ui
	_sync_ui()

func init_from_pending_score() -> int:
	score = SceneManager.consume_pending_score()
	SceneManager.set_current_score(score)
	_sync_ui()
	return score

func reset() -> void:
	set_score(0)

func set_score(value: int) -> void:
	score = maxi(value, 0)
	SceneManager.set_current_score(score)
	_sync_ui()

func add(delta: int) -> int:
	set_score(score + delta)
	return score

func _sync_ui() -> void:
	if score_ui:
		score_ui.set_value(score)

