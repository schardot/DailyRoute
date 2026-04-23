extends Node

var bell_stream: AudioStream = preload("res://assets/sounds/BellRing.mp3")
var car_crash_stream_1: AudioStream = preload("res://assets/sounds/CarCrash1.mp3")
var car_crash_stream_2: AudioStream = preload("res://assets/sounds/CarCrash2.mp3")
const CAR_CRASH_VOLUME_DB := -25.0

var bell_player: AudioStreamPlayer
var car_crash_player_1: AudioStreamPlayer
var car_crash_player_2: AudioStreamPlayer

func _ready() -> void:
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

func play_bell() -> void:
	if not bell_stream:
		return
	bell_player.stream = bell_stream
	bell_player.play()

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
