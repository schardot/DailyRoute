extends CharacterBody2D

@export var  speed := 300.0

var goal_color: GameTypes.ColorType
var has_goal := false
var can_move_left := true
var can_move_right := true
var can_move_up := true
var can_move_down := true
var time := 0.0

@onready var push_area := $PushArea
@onready var thought_bubble := $ThoughtBubble


func _process(delta):
	time += delta    
	var squash = sin(time * 4.0) * 0.05
	scale.x = 1.0 + squash
	scale.y = 1.0 - squash
	
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
		var boost_dir: Vector2 = input_dir.normalized()
		if boost_dir == Vector2.ZERO:
			boost_dir = velocity.normalized()
		if boost_dir != Vector2.ZERO:
			velocity += boost_dir * 700.0

	# 1. Start from current velocity
	var desired_velocity = input_dir.normalized() * speed

	# 2. Blend input with existing velocity
	velocity = velocity.move_toward(desired_velocity, speed * 6 * delta)
	#push_npcs()
	# 3. Move
	move_and_slide()

	# 4. Apply crowd push AFTER movement
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()

		if collider.is_in_group("crowd"):
			velocity += collision.get_normal() * 120


func _ready() -> void:
	thought_bubble.set_icon(
		GameTypes.ColorType.BLUE
	)

func set_goal(color: GameTypes.ColorType):
	goal_color = color
	has_goal = true
	thought_bubble.show()
	thought_bubble.set_icon(color)

func clear_goal():
	has_goal = false
	thought_bubble.hide()

func set_movement(left, right, up, down):
	can_move_left = left
	can_move_right = right
	can_move_down = down
	can_move_up = up

func push_npcs():
	var bodies = push_area.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("crowd"):
			var dir = (body.global_position - global_position).normalized()
			body.apply_push(dir)

func die() -> void:
	var sound: Node = get_node_or_null("/root/SoundController")
	if sound and sound.has_method("play_car_crash_random"):
		sound.call("play_car_crash_random")
	SceneManager.go_to_lose_screen()
