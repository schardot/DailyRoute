@tool
extends Area2D

var completed := false
signal player_entered()

@onready var block_shape: CollisionShape2D = $StaticBody2D/BlockShape
@onready var sprite: Sprite2D = $Visuals/Sprite2D
@export var store_id: int
@export var color: GameTypes.ColorType = GameTypes.ColorType.RED

const UNIVERSAL_ROOF_COLOR := Color("#E8D4A8")
const UNIVERSAL_DOOR_COLOR := Color("#C8A878")
const WALL_COLORS := [
	Color("#FFB3CC"),  # Rosa chiclete
	Color("#C9A8FF"),  # Roxo lavanda
	Color("#F0F0F0"),  # Branco gelo
	Color("#A8D8FF"),  # Azul céu
	Color("#FFB87A"),  # Laranja pêssego
	Color("#A8E8A8"),  # Verde menta
	Color("#FFF0A0"),  # Amarelo limão
	Color("#FF9090"),  # Vermelho salmão
	Color("#90E8D8"),  # Turquesa
	Color("#F0DEC0"),  # Bege areia
]

func _ready():
	_ensure_unique_material()
	_apply_store_palette()
	_setup_area()

	block_shape.disabled = false
	add_to_group("stores")
	

func unblock_store():
	block_shape.set_deferred("disabled", true)

func _on_store_body_entered(body):
	if not body.is_in_group("player"):
		return
	
	if completed:
		return
	if not body.has_goal:
		return

	if body.goal_color == color:
		_correct_feedback()

func _correct_feedback():
	completed = true
	emit_signal("player_entered")


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

func _get_wall_color_for_store() -> Color:
	if WALL_COLORS.is_empty():
		return Color.WHITE
	if store_id >= 0 and store_id < WALL_COLORS.size():
		return WALL_COLORS[store_id]
	return WALL_COLORS[0]

## Same wall tint as the shader (for UI / thought bubble).
func get_wall_color() -> Color:
	return _get_wall_color_for_store()

func _apply_store_palette() -> void:
	set_colors(UNIVERSAL_ROOF_COLOR, _get_wall_color_for_store(), UNIVERSAL_DOOR_COLOR)

func set_colors(roof: Color, wall: Color, door: Color):
	var mat = sprite.material as ShaderMaterial
	if mat == null:
		return
	mat.set_shader_parameter("roof_color", roof)
	mat.set_shader_parameter("wall_color", wall)
	mat.set_shader_parameter("door_color", door)
