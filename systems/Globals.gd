extends Node

const OFFSCREEN_MARGIN_Y := 48.0
const _CROWD_MEMBER_SCENE: PackedScene = preload("res://scenes/entities/crowd/CrowdMember.tscn")

var _crowd_default_half_height: float = -1.0

## Vertical half-extent of the default `CrowdMember` collision shape (cached). Used before any NPC exists (e.g. spawn Y).
func get_world_half_height() -> float:
	if _crowd_default_half_height >= 0.0:
		return _crowd_default_half_height
	var inst := _CROWD_MEMBER_SCENE.instantiate() as Node2D
	var cs := inst.get_node("CollisionShape2D") as CollisionShape2D
	_crowd_default_half_height = get_collision_shape_world_half_height(cs)
	inst.free()
	return _crowd_default_half_height

func get_screen_size() -> Vector2:
	return get_viewport().get_visible_rect().size

func wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
	
func wait_short():
	await wait(2)

func wait_medium():
	await wait(3)

func wait_long():
	await wait(20)

func random_bool() -> bool:
	return randf() < 0.5

func random_sign() -> float:
	return 1.0 if random_bool() else -1.0

func get_collision_shape_world_radius(collision_shape: CollisionShape2D) -> float:
	if not collision_shape:
		return 0.0

	var shape := collision_shape.shape
	var local_radius: float = 0.0

	if shape is CircleShape2D:
		local_radius = shape.radius
	elif shape is CapsuleShape2D:
		local_radius = shape.radius
	elif shape is RectangleShape2D:
		local_radius = max(shape.size.x, shape.size.y) * 0.5

	var scale: Vector2 = collision_shape.global_transform.get_scale()
	return local_radius * max(abs(scale.x), abs(scale.y))
	
func get_collision_shape_world_half_height(collision_shape: CollisionShape2D) -> float:
	if not collision_shape or collision_shape.shape == null:
		return 0.0
	var shape := collision_shape.shape
	var local_half_h: float = 0.0
	if shape is CapsuleShape2D:
		local_half_h = (shape.height * 0.5) + shape.radius
	elif shape is RectangleShape2D:
		local_half_h = shape.size.y * 0.5
	elif shape is CircleShape2D:
		local_half_h = shape.radius
	var sy := absf(collision_shape.global_transform.get_scale().y)
	return local_half_h * sy
