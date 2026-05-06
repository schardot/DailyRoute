extends CharacterBody2D

@export var  speed := 300.0

signal boost_used
var is_boosting = false

var goal_color: GameTypes.ColorType
var has_goal := false
var is_carrying := false
var can_move_left := true
var can_move_right := true
var can_move_up := true
var can_move_down := true
var time := 0.0
var last_direction := Vector2.DOWN
var _last_input_dir := Vector2.ZERO

@export_group("Box (hands)")
@export var box_hand_offset_up: Vector2 = Vector2(0, -10)
@export var box_hand_offset_down: Vector2 = Vector2(0, 14)
@export var box_hand_offset_left: Vector2 = Vector2(-14, 20)
@export var box_hand_offset_right: Vector2 = Vector2(14, 20)

@onready var box := $Box
@onready var box_sprite: Sprite2D = $Box/Sprite2D

func _ready() -> void:
	box.hide_box()
	
func _physics_process(delta: float) -> void:
	var input_dir := Vector2.ZERO
	if Input.is_action_pressed("ui_right") && can_move_right:
		input_dir.x += 1
	if Input.is_action_pressed("ui_left") && can_move_left:
		input_dir.x -= 1
	if Input.is_action_pressed("ui_down") && can_move_down:
		input_dir.y += 1
	if Input.is_action_pressed("ui_up") && can_move_up:
		input_dir.y -= 1

	if Input.is_action_just_pressed("push"):
		is_boosting = true
		boost_used.emit()
		var boost_dir: Vector2 = input_dir.normalized()
		if boost_dir == Vector2.ZERO:
			boost_dir = velocity.normalized()
		if boost_dir != Vector2.ZERO:
			velocity += boost_dir * 700.0
	
	if is_boosting:
		Globals.wait(0.2)
		is_boosting = false

	var desired_velocity = input_dir.normalized() * speed

	velocity = velocity.move_toward(desired_velocity, speed * 6 * delta)
	move_and_slide()

	_last_input_dir = input_dir
	update_animation(input_dir)


func pick_up_box(color_type: GameTypes.ColorType, store_for_wall_color: Node = null) -> void:
	is_carrying = true
	if store_for_wall_color != null and store_for_wall_color.has_method("get_wall_color"):
		box.set_box_from_store(store_for_wall_color)
	else:
		box.set_box_type(color_type)
	box.show()
	update_animation(_last_input_dir)

func deliver_box() -> void:
	is_carrying = false
	box.hide_box()
	update_animation(_last_input_dir)

func set_goal(color: GameTypes.ColorType, store_for_display: Node = null) -> void:
	goal_color = color
	has_goal = true

func clear_goal():
	has_goal = false
	deliver_box()

func set_movement(left, right, up, down):
	can_move_left = left
	can_move_right = right
	can_move_down = down
	can_move_up = up

func play_anim(name: StringName) -> void:
	var sprite: AnimatedSprite2D = $AnimatedSprite2D
	if sprite.sprite_frames == null:
		return
	if not sprite.sprite_frames.has_animation(name):
		return
	if sprite.animation != name:
		sprite.play(name)

func _play_first_existing(names: Array) -> void:
	var sprite: AnimatedSprite2D = $AnimatedSprite2D
	if sprite.sprite_frames == null:
		return
	for n in names:
		if sprite.sprite_frames.has_animation(n):
			play_anim(n)
			return

func die() -> void:
	SoundController.call("play_car_crash_random")
	SceneManager.go_to_lose_screen()

func update_animation(input_dir: Vector2) -> void:
	if input_dir != Vector2.ZERO:
		last_direction = input_dir

	var dir_src := input_dir if input_dir != Vector2.ZERO else last_direction
	var x_heavy : bool = abs(dir_src.x) > abs(dir_src.y)
	var dir_key: String
	if x_heavy:
		dir_key = "right" if dir_src.x > 0 else "left"
	else:
		dir_key = "down" if dir_src.y > 0 else "up"

	if input_dir == Vector2.ZERO:
		if is_carrying:
			_play_first_existing(["carry_idle_" + dir_key, "idle_" + dir_key])
		else:
			play_anim("idle_" + dir_key)
	else:
		if is_carrying:
			_play_first_existing(["carry_" + dir_key, "walk_" + dir_key])
		else:
			play_anim("walk_" + dir_key)

	if is_carrying:
		_update_box_hand_pose(dir_key)

func _update_box_hand_pose(dir_key: String) -> void:
	var o: Vector2
	match dir_key:
		"up":
			o = box_hand_offset_up
			box.z_index = -1
		"down":
			o = box_hand_offset_down
			box.z_index = 0
		"left":
			o = box_hand_offset_left
			box.z_index = 0
		"right":
			o = box_hand_offset_right
			box.z_index = 0
		_:
			o = box_hand_offset_down
			box.z_index = 0
	box.position = o
	if box_sprite:
		box_sprite.flip_h = dir_key == "left"
