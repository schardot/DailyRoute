@tool
extends Area2D

var completed := false
signal player_entered()

@onready var block_shape: CollisionShape2D = $StaticBody2D/BlockShape
@onready var sprite: Sprite2D = $Visuals/Sprite2D
@onready var animated_sprite: AnimatedSprite2D = $Visuals/AnimatedSprite2D
@export var store_id: int
@export var color: GameTypes.ColorType = GameTypes.ColorType.RED

@export var roof_color: Color = Color.WHITE
@export var door_color: Color = Color.WHITE
@export var wall_color: Color = Color.WHITE

func _ready():
	_ensure_unique_material()
	_apply_store_palette()
	_setup_area()
	_setup_animations()

	block_shape.disabled = false
	add_to_group("stores")

func _setup_animations() -> void:
	if animated_sprite == null:
		return
	animated_sprite.visible = false
	if not animated_sprite.animation_finished.is_connected(_on_animation_finished):
		animated_sprite.animation_finished.connect(_on_animation_finished)

func _on_animation_finished() -> void:
	if animated_sprite == null or animated_sprite.sprite_frames == null:
		return
	var anim := animated_sprite.animation
	if anim == "door_open":
		var last: int = maxi(animated_sprite.sprite_frames.get_frame_count(anim) - 1, 0)
		animated_sprite.frame = last
		animated_sprite.pause()
	elif anim == "door_close":
		animated_sprite.pause()
		animated_sprite.visible = false

func unblock_store():
	block_shape.set_deferred("disabled", true)

func _on_store_body_entered(body):
	if not body.is_in_group("player"):
		return

	if completed:
		return

	if body.goal_color == color:
		_correct_feedback()

func _correct_feedback():
	completed = true
	player_entered.emit()

func _setup_area():
	monitoring = true
	monitorable = true
	block_shape.disabled = false

	if not body_entered.is_connected(_on_store_body_entered):
		body_entered.connect(_on_store_body_entered)

func _ensure_unique_material() -> void:
	if not sprite:
		return
	var mat := sprite.material as ShaderMaterial
	if mat == null:
		return
	sprite.material = mat.duplicate()

func get_wall_color() -> Color:
	return wall_color

func _apply_store_palette() -> void:
	set_colors(roof_color, get_wall_color(), door_color)

func set_colors(roof: Color, wall: Color, door: Color):
	var mat = sprite.material as ShaderMaterial
	if mat == null:
		return
	mat.set_shader_parameter("roof_color", roof)
	mat.set_shader_parameter("wall_color", wall)
	mat.set_shader_parameter("door_color", door)

func play_animation(anim_name: String) -> void:
	if animated_sprite == null:
		push_warning("Store.play_animation: missing Visuals/AnimatedSprite2D on %s" % name)
		return
	if animated_sprite.sprite_frames == null:
		push_warning("Store.play_animation: missing sprite_frames on %s" % name)
		return
	if not animated_sprite.sprite_frames.has_animation(anim_name):
		push_warning("Store.play_animation: animation '%s' not found on %s" % [anim_name, name])
		return
	
	if anim_name == "door_open":
		SoundController.play_door_open()
	elif anim_name == "door_close":
		SoundController.play_door_close()

	animated_sprite.visible = true
	animated_sprite.play(anim_name)
