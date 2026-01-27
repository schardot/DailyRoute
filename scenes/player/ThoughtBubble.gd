extends Node2D

@onready var icon_rect := $ColorRect
@onready var icon_label := $Label

func set_icon(shape: GameTypes.ShapeType, color: GameTypes.ColorType):
	icon_label.text = _shape_to_symbol(shape)
	icon_rect.color = _color_to_color(color)
	visible = true


func _shape_to_symbol(s):
	match s:
		GameTypes.ShapeType.CIRCLE: return "●"
		GameTypes.ShapeType.SQUARE: return "■"
		GameTypes.ShapeType.TRIANGLE: return "▲"
		GameTypes.ShapeType.DIAMOND: return "◆"
		GameTypes.ShapeType.STAR: return "★"
		_: return "?"


func _color_to_color(c):
	match c:
		GameTypes.ColorType.RED: return Color.RED
		GameTypes.ColorType.GREEN: return Color.GREEN
		GameTypes.ColorType.BLUE: return Color.BLUE
		GameTypes.ColorType.YELLOW: return Color.YELLOW
		_: return Color.WHITE
