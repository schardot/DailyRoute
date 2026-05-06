extends Node2D

@onready var sprite := $Sprite2D

func _ready() -> void:
	var mat := sprite.material as ShaderMaterial
	if mat:
		sprite.material = mat.duplicate()

func set_box_color(color: Color) -> void:
	sprite.material.set_shader_parameter("tint", color)
	visible = true

func set_box_type(color_type: GameTypes.ColorType) -> void:
	set_box_color(Globals.color_type_to_color(color_type))

func set_box_from_store(store: Node) -> void:
	if store == null:
		return
	if store.has_method("get_wall_color"):
		set_box_color(store.get_wall_color())
	else:
		push_warning("Box.set_box_from_store: store has no get_wall_color()")

func hide_box() -> void:
	visible = false
