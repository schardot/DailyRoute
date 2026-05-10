extends CharacterBody2D
class_name CrowdMember

var speed := 40.0
var lane : LaneStruct:
	set(value):
		lane = value
		_update_walk_animation()

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _physics_process(_delta):
	if lane == null:
		return
	velocity = get_base_velocity()
	move_and_slide()
	
	var max_offset = 20.0
	var offset = global_position.x - lane.center.x
	offset = clamp(offset, -max_offset, max_offset)
	global_position.x = lane.center.x + offset
	_check_recycle()

func get_base_velocity() -> Vector2:
	return Vector2(0, lane.direction.y) * speed

func _check_recycle():
	if not lane:
		return
	var half_h := Globals.get_collision_shape_world_half_height(collision_shape)
	var viewport_h := get_viewport().get_visible_rect().size.y
	var top_edge : float = -half_h - Globals.OFFSCREEN_MARGIN_Y
	var bottom_edge : float = viewport_h + half_h + Globals.OFFSCREEN_MARGIN_Y
	if lane.direction.y > 0.0 and global_position.y > bottom_edge:
		global_position = Vector2(lane.center.x, top_edge)
	elif lane.direction.y < 0.0 and global_position.y < top_edge:
		global_position = Vector2(lane.center.x, bottom_edge)

func get_world_radius() -> float:
	var cs := collision_shape
	if not cs:
		return 0.0
	return Globals.get_collision_shape_world_radius(cs)

func _ready():
	_update_walk_animation()

func _update_walk_animation():
	if lane == null:
		return
	if lane.direction == Vector2.DOWN:
		$AnimatedSprite2D.play("walk_down")
	else:
		$AnimatedSprite2D.play("walk_up")
