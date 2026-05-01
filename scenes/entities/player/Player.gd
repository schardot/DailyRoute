extends CharacterBody2D

@export var  speed := 300.0 #velocity.length()

# --- BOOST
signal boost_used
var is_boosting = false
# ---------------

var goal_color: GameTypes.ColorType
var has_goal := false
var can_move_left := true
var can_move_right := true
var can_move_up := true
var can_move_down := true
var time := 0.0
var last_direction := Vector2.DOWN

#@onready var push_area := $PushArea
@onready var thought_bubble := $ThoughtBubble
	
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

	# 1. Start from current velocity
	var desired_velocity = input_dir.normalized() * speed

	# 2. Blend input with existing velocity
	velocity = velocity.move_toward(desired_velocity, speed * 6 * delta)
	#push_npcs()
	# 3. Move
	move_and_slide()
	
	update_animation(input_dir)


func _ready() -> void:
	thought_bubble.set_icon(
		GameTypes.ColorType.BLUE
	)

func set_goal(color: GameTypes.ColorType, store_for_display: Node = null) -> void:
	goal_color = color
	has_goal = true
	thought_bubble.show()
	if store_for_display != null and store_for_display.has_method("get_wall_color"):
		thought_bubble.set_bubble_color(store_for_display.get_wall_color())
	else:
		thought_bubble.set_icon(color)

func clear_goal():
	has_goal = false
	thought_bubble.hide()

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

func die() -> void:
	SoundController.call("play_car_crash_random")
	SceneManager.go_to_lose_screen()

func update_animation(input_dir: Vector2):
	if input_dir != Vector2.ZERO:
		last_direction = input_dir

	if input_dir == Vector2.ZERO:
		if abs(last_direction.x) > abs(last_direction.y):
			if last_direction.x > 0:
				play_anim("idle_right")
			else:
				play_anim("idle_left")
		else:
			if last_direction.y > 0:
				play_anim("idle_down")
			else:
				play_anim("idle_up")
	else:
		if abs(input_dir.x) > abs(input_dir.y):
			if input_dir.x > 0:
				play_anim("walk_right")
			else:
				play_anim("walk_left")
		else:
			if input_dir.y > 0:
				play_anim("walk_down")
			else:
				play_anim("walk_up")
