extends Node

const BELL_STREAM_PATH := "res://assets/sounds/BellRing.mp3"
const CAR_CRASH_1_STREAM_PATH := "res://assets/sounds/CarCrash1.mp3"
const CAR_CRASH_2_STREAM_PATH := "res://assets/sounds/CarCrash2.mp3"
const KEY_PRESS_STREAM_PATH := "res://assets/sounds/KeyPressed.mp3"

var bell_stream: AudioStream
var car_crash_stream_1: AudioStream
var car_crash_stream_2: AudioStream
var key_press_stream: AudioStream
const CAR_CRASH_VOLUME_DB := -25.0
const KEY_PRESS_VOLUME_DB := -18.0

var bell_player: AudioStreamPlayer
var car_crash_player_1: AudioStreamPlayer
var car_crash_player_2: AudioStreamPlayer
var key_press_player: AudioStreamPlayer

func _ready() -> void:
	bell_stream = _try_load_stream(BELL_STREAM_PATH)
	car_crash_stream_1 = _try_load_stream(CAR_CRASH_1_STREAM_PATH)
	car_crash_stream_2 = _try_load_stream(CAR_CRASH_2_STREAM_PATH)
	key_press_stream = _try_load_stream(KEY_PRESS_STREAM_PATH)

	bell_player = AudioStreamPlayer.new()
	bell_player.name = "BellPlayer"
	add_child(bell_player)

	car_crash_player_1 = AudioStreamPlayer.new()
	car_crash_player_1.name = "CarCrashPlayer1"
	car_crash_player_1.volume_db = CAR_CRASH_VOLUME_DB
	add_child(car_crash_player_1)

	car_crash_player_2 = AudioStreamPlayer.new()
	car_crash_player_2.name = "CarCrashPlayer2"
	car_crash_player_2.volume_db = CAR_CRASH_VOLUME_DB
	add_child(car_crash_player_2)

	key_press_player = AudioStreamPlayer.new()
	key_press_player.name = "KeyPressPlayer"
	key_press_player.volume_db = KEY_PRESS_VOLUME_DB
	add_child(key_press_player)

func _try_load_stream(path: String) -> AudioStream:
	if path.is_empty():
		return null
	if not ResourceLoader.exists(path):
		return null
	return load(path) as AudioStream

func play_bell() -> void:
	if not bell_stream:
		return
	bell_player.stream = bell_stream
	bell_player.play()

func play_key_press() -> void:
	if not key_press_stream:
		return
	key_press_player.stream = key_press_stream
	key_press_player.play()

func set_key_press_stream(stream: AudioStream) -> void:
	key_press_stream = stream

func set_key_press_stream_path(path: String) -> void:
	key_press_stream = _try_load_stream(path)

func play_car_crash_1() -> void:
	if not car_crash_stream_1:
		return
	car_crash_player_1.stream = car_crash_stream_1
	car_crash_player_1.play()

func play_car_crash_2() -> void:
	if not car_crash_stream_2:
		return
	car_crash_player_2.stream = car_crash_stream_2
	car_crash_player_2.play()

func play_car_crash_random() -> void:
	if car_crash_stream_1 and car_crash_stream_2:
		if Globals.random_bool():
			play_car_crash_1()
		else:
			play_car_crash_2()
	elif car_crash_stream_1:
		play_car_crash_1()
	elif car_crash_stream_2:
		play_car_crash_2()
