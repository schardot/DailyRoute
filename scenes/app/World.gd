extends Node2D
class_name World

@onready var player = $Entities/Player
@onready var stores_container = $Entities/Stores
@onready var car = $Entities/Car
@onready var crowd = $Entities/Crowd
@onready var entities_root = $Entities
@onready var tilemap = $Environment/TileMapLayer

const STORE_ROW_PAIRS: Array[Array] = [
	[0, 5],
	[1, 6],
	[2, 7],
	[3, 8],
	[4, 9],
]
var store_pair_map: Dictionary = {}
var stores_by_id: Dictionary = {}

func _ready() -> void:
	LaneManager.set_tilemap(tilemap)
	LaneManager.generate_lanes()
	_build_store_pair_map()
	_cache_stores()
	for store in get_tree().get_nodes_in_group("stores"):
		store.set_colors(Color.RED, Color.BEIGE)

func _build_store_pair_map() -> void:
	for pair in STORE_ROW_PAIRS:
		if pair.size() < 2:
			continue
		
		var a: int = pair[0]
		var b: int = pair[1]
		
		store_pair_map[a] = b
		store_pair_map[b] = a
		
func _cache_stores() -> void:
	for store in get_tree().get_nodes_in_group("stores"):
		stores_by_id[store.store_id] = store

func get_player():
	return player

func get_stores() -> Array:
	return stores_container.get_children()

func get_car():
	return car

func get_crowd():
	return crowd

func get_entities_root():
	return entities_root

func get_paired_store(store_id: int) -> Area2D:
	var paired_id = store_pair_map.get(store_id)
	if paired_id == null:
		return null
	
	return stores_by_id.get(paired_id)

func get_store_pairs_by_row() -> Array[Array]:
	var pairs: Array[Array] = []
	
	for pair_ids in STORE_ROW_PAIRS:
		if pair_ids.size() < 2:
			continue
		
		var left = stores_by_id.get(pair_ids[0])
		var right = stores_by_id.get(pair_ids[1])
		
		if left and right:
			pairs.append([left, right])
	return pairs

func get_random_store_pair() -> Array:
	var pairs: Array[Array] = get_store_pairs_by_row()
	if pairs.is_empty():
		return []
	return pairs.pick_random()

func get_tilemap() -> TileMapLayer:
	return tilemap
