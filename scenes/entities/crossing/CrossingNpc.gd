extends CharacterBody2D
class_name CrossingNpc

signal crossing_started(row_y: float)
signal crossing_ended(row_y: float)

@export var speed: float = 180.0

var time := 0.0
var target_x: float = 0.0
var row_y: float = 0.0
var _active: bool = false

func _ready() -> void:
	add_to_group("crossing_npcs")

func is_crossing_active() -> bool:
	return _active
	
func _process(delta):
	time += delta
	
	# Lean forward (depends on direction)
	var dir : float = sign(velocity.x) # -1 left, +1 right
	rotation = dir * 0.15
	
	# Vertical bob (walking feel)
	var bob = sin(time * 10.0) * 0.05
	position.y += bob

func spawn_from_stores(left_store: Node2D, right_store: Node2D) -> void:
	if not is_in_group("crossing_npcs"):
		add_to_group("crossing_npcs")
	row_y = left_store.global_position.y
	global_position = Vector2(left_store.global_position.x, row_y)
	target_x = right_store.global_position.x

	var dir_x: float = sign(target_x - global_position.x)
	if dir_x == 0.0:
		dir_x = 1.0
	_active = true
	emit_signal("crossing_started", row_y)

func _physics_process(_delta: float) -> void:
	if not _active:
		return

	global_position.y = row_y

	var dir_x: float = sign(target_x - global_position.x)
	velocity = Vector2(dir_x * speed, 0.0)
	move_and_slide()

	var reached: bool = (global_position.x >= target_x) if dir_x > 0.0 else (global_position.x <= target_x)
	if reached:
		emit_signal("crossing_ended", row_y)
		queue_free()
