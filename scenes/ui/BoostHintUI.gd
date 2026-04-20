extends Node2D

var target: Node2D
@export var follow_offset: Vector2 = Vector2(36, 0)

func _process(_delta: float) -> void:
	if not visible:
		return
	if target and is_instance_valid(target):
		global_position = target.global_position + follow_offset

func _ready() -> void:
	position = Vector2.ZERO
	hide_hint()
	set_process(false)

func set_target(new_target: Node2D) -> void:
	target = new_target
	set_process(target != null)

func show_hint():
	visible = true
	if target and is_instance_valid(target):
		global_position = target.global_position + follow_offset
	$AnimationPlayer.play("press_loop")

func hide_hint():
	visible = false
	$AnimationPlayer.stop()
