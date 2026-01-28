extends CharacterBody2D

@export var  speed := 500.0
var goal_color: GameTypes.ColorType
var has_goal := false

@onready var thought_bubble := $ThoughtBubble

func _physics_process(_delta: float) -> void:

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Vector2.ZERO
	
	if Input.is_action_pressed("ui_right"):
		direction.x += 1
	if Input.is_action_pressed("ui_left"):
		direction.x -= 1
	if Input.is_action_pressed("ui_down"):
		direction.y += 1
	if Input.is_action_pressed("ui_up"):
		direction.y -= 1

	velocity = direction.normalized() * speed
	move_and_slide()

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
