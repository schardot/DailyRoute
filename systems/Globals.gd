extends Node

# -----------------
# LIFECYCLE
# -----------------

func _ready() -> void:
	randomize()

# -----------------
# SCREEN HELPERS
# -----------------

func get_screen_size() -> Vector2:
	return get_viewport().get_visible_rect().size

# -----------------
# RANDOM HELPERS
# -----------------

func random_bool() -> bool:
	return randf() < 0.5

func random_sign() -> float:
	return 1.0 if random_bool() else -1.0

# -----------------
# COLLISION HELPERS
# -----------------

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

# -----------------
# COLOR HELPERS
# -----------------

func color_type_to_color(c: GameTypes.ColorType) -> Color:
	match c:
		GameTypes.ColorType.RED:
			return Color.RED
		GameTypes.ColorType.GREEN:
			return Color.GREEN
		GameTypes.ColorType.BLUE:
			return Color.BLUE
		GameTypes.ColorType.YELLOW:
			return Color.YELLOW
		GameTypes.ColorType.PURPLE:
			return Color.PURPLE
		GameTypes.ColorType.ORANGE:
			return Color.ORANGE
		GameTypes.ColorType.CYAN:
			return Color.CYAN
		GameTypes.ColorType.PINK:
			return Color.PINK
		GameTypes.ColorType.BROWN:
			return Color.BROWN
		GameTypes.ColorType.WHITE:
			return Color.WHITE
		_:
			return Color.BLACK

# -----------------
# GLOBAL SIGNALS
# -----------------

# Emitted when the player completes an assignment (reaches the correct store)
signal assignment_completed

# Emitted when the player dies (e.g. hit by a car)
signal player_died
