@export var shape: GameTypes.ShapeType
@export var color: GameTypes.ColorType

@onready var icon_label := $Label
@onready var icon_rect := $ColorRect

func update_icon():
	# same code as stores
