extends Node2D

@onready var sprite := $Sprite2D

func _ready() -> void:
	var mat := sprite.material as ShaderMaterial
	if mat:
		sprite.material = mat.duplicate()

func set_box_color(color: Color) -> void:
	sprite.material.set_shader_parameter("tint", color)
	visible = true

func set_box_from_store(store: Node) -> void:
	if store == null:
		return
	set_box_color(store.get_wall_color())

func hide_box() -> void:
	visible = false
