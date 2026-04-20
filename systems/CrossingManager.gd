extends Node
class_name CrossingManager

const CROSSING_NPC_SCN: PackedScene = preload("res://scenes/entities/crossing/CrossingNpc.tscn")

var world: Node2D
var crossing_spawn_chance: float = 0.2
var crossing_try_interval: float = 5.0
var crossing_row_memory_size: int = 2

var crossing_spawn_timer: Timer
var recent_crossing_rows: Array[int] = []

func configure(world_ref: Node2D, spawn_chance: float, try_interval: float, row_memory_size: int) -> void:
	world = world_ref
	crossing_spawn_chance = spawn_chance
	crossing_try_interval = try_interval
	crossing_row_memory_size = row_memory_size
	recent_crossing_rows.clear()

func start_auto_spawn() -> void:
	if not world:
		return
	if crossing_spawn_timer == null:
		crossing_spawn_timer = Timer.new()
		crossing_spawn_timer.one_shot = true
		crossing_spawn_timer.autostart = false
		crossing_spawn_timer.timeout.connect(_on_crossing_spawn_timer_timeout)
		add_child(crossing_spawn_timer)
	_schedule_next_crossing_try()

func stop_auto_spawn() -> void:
	if crossing_spawn_timer:
		crossing_spawn_timer.stop()

func try_spawn_with_chance() -> CrossingNpc:
	if randf() >= crossing_spawn_chance:
		return null
	return spawn_crossing_npc()

func spawn_crossing_npc(from_store: Node2D = null, to_store: Node2D = null) -> CrossingNpc:
	if not world:
		return null

	if from_store == null or to_store == null:
		var pair: Array = _pick_store_pair_with_memory()
		if pair.size() < 2:
			return null
		from_store = pair[0]
		to_store = pair[1]
		if randf() < 0.5:
			var tmp: Node2D = from_store
			from_store = to_store
			to_store = tmp

	var npc: CrossingNpc = CROSSING_NPC_SCN.instantiate() as CrossingNpc
	world.get_entities_root().add_child(npc)
	npc.z_index = 3
	npc.spawn_from_stores(from_store, to_store)
	return npc

func _on_crossing_spawn_timer_timeout() -> void:
	try_spawn_with_chance()
	_schedule_next_crossing_try()

func _schedule_next_crossing_try() -> void:
	if crossing_spawn_timer == null:
		return
	crossing_spawn_timer.wait_time = max(crossing_try_interval, 0.1)
	crossing_spawn_timer.start()

func _pick_store_pair_with_memory() -> Array:
	var pairs: Array[Array] = world.get_store_pairs_by_row()
	if pairs.is_empty():
		return []

	var candidate_rows: Array[int] = []
	for i in range(pairs.size()):
		if not recent_crossing_rows.has(i):
			candidate_rows.append(i)

	if candidate_rows.is_empty():
		for i in range(pairs.size()):
			candidate_rows.append(i)

	var row_idx: int = candidate_rows.pick_random()
	_remember_crossing_row(row_idx, pairs.size())
	return pairs[row_idx]

func _remember_crossing_row(row_idx: int, total_rows: int) -> void:
	if crossing_row_memory_size <= 0:
		return
	var clamped_memory: int = clampi(crossing_row_memory_size, 1, max(total_rows - 1, 1))
	recent_crossing_rows.append(row_idx)
	while recent_crossing_rows.size() > clamped_memory:
		recent_crossing_rows.remove_at(0)
