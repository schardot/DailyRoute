extends CharacterBody2D
class_name CrossingNpc

signal crossing_started(row_y: float)
signal crossing_ended(row_y: float)

@export var speed: float = 180.0

var target_x: float = 0.0
var row_y: float = 0.0
var _active: bool = false

func _ready() -> void:
	add_to_group("crossing_npcs")

func is_crossing_active() -> bool:
	return _active
	

func spawn_from_stores(left_store: Node2D, right_store: Node2D) -> void:
	if not is_in_group("crossing_npcs"):
		add_to_group("crossing_npcs")
	row_y = left_store.global_position.y
	global_position = Vector2(left_store.global_position.x, row_y)
	target_x = right_store.global_position.x

	var dir_x: float = sign(target_x - global_position.x)
	if dir_x == 0.0:
		dir_x = 1.0
	_update_anim_for_direction(dir_x)
		
	_active = true
	emit_signal("crossing_started", row_y)

func _physics_process(_delta: float) -> void:
	if not _active:
		return

	global_position.y = row_y

	var dir_x: float = sign(target_x - global_position.x)
	if dir_x == 0.0:
		dir_x = 1.0
	_update_anim_for_direction(dir_x)
		
	velocity = Vector2(dir_x * speed, 0.0)
	move_and_slide()

	var reached: bool = (global_position.x >= target_x) if dir_x > 0.0 else (global_position.x <= target_x)
	if reached:
		emit_signal("crossing_ended", row_y)
		queue_free()

func play_anim(name: StringName) -> void:
	var sprite: AnimatedSprite2D = $AnimatedSprite2D
	if sprite.animation != name:
		sprite.play(name)
	elif not sprite.is_playing():
		# Ensure the current animation resumes if it got stopped.
		sprite.play()

func _update_anim_for_direction(dir_x: float) -> void:
	play_anim("crossing_right" if dir_x > 0.0 else "crossing_left")
