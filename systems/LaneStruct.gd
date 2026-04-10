extends Node

class_name LaneStruct

var type: LaneManager.LaneType
var line: Array[int]
var direction: Vector2
var center: Vector2

func _init(_type: LaneManager.LaneType, _line: Array[int], _dir: Vector2, _center: Vector2):
		type = _type
		line = _line
		direction = _dir
		center = _center
