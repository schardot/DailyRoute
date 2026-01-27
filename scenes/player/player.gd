extends CharacterBody2D

@export var  speed := 200.0
var goal_shape: GameTypes.ShapeType
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
		GameTypes.ShapeType.TRIANGLE,
		GameTypes.ColorType.BLUE
	)
	

func set_goal(shape: GameTypes.ShapeType, color: GameTypes.ColorType):
	goal_shape = shape
	goal_color = color
	has_goal = true

	thought_bubble.set_icon(shape, color)
