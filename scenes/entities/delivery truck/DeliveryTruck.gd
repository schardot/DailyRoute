extends Node2D

@export var move_speed: float = 160.0
@export var stop_global_y: float = 140.0

@onready var animated_truck: AnimatedSprite2D = $AnimatedTruck
@onready var animated_door: AnimatedSprite2D = $AnimatedDoor

var _is_entering: bool = false

func start_intro() -> void:
	if not animated_truck or not animated_door:
		return

	visible = true
	_is_entering = true
	animated_door.stop()
	animated_door.frame = 0
	animated_truck.play("walk_down")
	set_process(true)

func _ready() -> void:
	set_process(false)

## Parked state for Game scene: visible, truck motion stopped, door held open on last frame.
func park_idle() -> void:
	if not animated_truck or not animated_door:
		return
	visible = true
	set_process(false)
	_is_entering = false
	animated_truck.stop()
	animated_truck.frame = 0
	animated_door.stop()
	if animated_door.sprite_frames and animated_door.sprite_frames.has_animation("door_open"):
		var door_frames := animated_door.sprite_frames.get_frame_count("door_open")
		if door_frames > 0:
			animated_door.frame = door_frames - 1

func _process(delta: float) -> void:
	if not _is_entering:
		return

	global_position.y += move_speed * delta
	if global_position.y < stop_global_y:
		return

	global_position.y = stop_global_y
	_is_entering = false
	set_process(false)
	# Keep the truck idle-motion animation running after it parks.
	animated_truck.play("walk_down")
	_play_door_once()

func _play_door_once() -> void:
	animated_door.play("door_open")
	var frame_count := animated_door.sprite_frames.get_frame_count("door_open")
	var fps := animated_door.sprite_frames.get_animation_speed("door_open")
	if frame_count <= 0 or fps <= 0.0:
		return

	var duration := float(frame_count) / fps
	await get_tree().create_timer(duration).timeout
	animated_door.stop()
	animated_door.frame = frame_count - 1
