extends CharacterBody2D
class_name CrowdMember

var speed := 40.0
var lane : LaneStruct:
	set(value):
		lane = value
		_update_walk_animation()
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

# ---- TUTORIAL SETTINGS -----
#var has_target := false
#var target_position: Vector2
#var arrived := false
#var dir_override : Vector2 = Vector2.ZERO
# ----------------------------

# ---- PLAYER DETECTION ------
var player: CharacterBody2D
var player_in_area = false
const SPAWN_MARGIN_Y := 8.0
# ----------------------------

func _get_collision_shape() -> CollisionShape2D:
	if collision_shape:
		return collision_shape
	collision_shape = get_node_or_null("CollisionShape2D") as CollisionShape2D
	return collision_shape
		
func _physics_process(_delta):
	if lane == null:
		return
	var final_velocity = get_base_velocity()
	
	if player_in_area:
		var to_player = player.global_position - global_position

		if not player.is_boosting:
			open_corridor(final_velocity, to_player)
		if player.speed < 20:
			avoid_like_obstacle(to_player)
	
	velocity = final_velocity
	move_and_slide()
	if lane:
		var max_offset = 20.0
		var offset = global_position.x - lane.center.x
		offset = clamp(offset, -max_offset, max_offset)
		global_position.x = lane.center.x + offset
	_check_recycle()

func get_base_velocity() -> Vector2:
	return Vector2(0, lane.direction.y) * speed

func avoid_like_obstacle(to_player):
	var away_dir = (global_position - player.global_position).normalized()
	away_dir.y = 0
	velocity.x = away_dir.x * 300.0

func open_corridor(velocity, to_player):
	var dx = global_position.x - player.global_position.x
	var side = sign(dx)
	velocity.x = side * 300.0
	return velocity
	
func _check_recycle():
	if not lane:
		return
	var npc_half_height := get_world_radius()
	var top_y := -npc_half_height - SPAWN_MARGIN_Y
	var bottom_y := get_viewport_rect().size.y + npc_half_height + SPAWN_MARGIN_Y
	if lane.direction.y > 0.0 and global_position.y > bottom_y:
		global_position = Vector2(lane.center.x, top_y)
	elif lane.direction.y < 0.0 and global_position.y < top_y:
		global_position = Vector2(lane.center.x, bottom_y)
	#push_offset = Vector2.ZERO
	#was_pushed = false

#func apply_push(dir: Vector2):
	#was_pushed = true
	#push_offset += dir * 3000
	#emit_signal("pushed")

func get_world_radius() -> float:
	var cs := _get_collision_shape()
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

func _on_personal_space_body_entered(body: Node2D) -> void:
	print(body.name)
	if body.is_in_group("player"):
		print("player")
		player_in_area = true

func _on_personal_space_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_area = false
