extends AudioStreamPlayer2D

@export var sound_type: String = "drop"
@export var min_interval: float = 2.5
@export var max_interval: float = 7.0
@export var random_pitch: float = 0.15
@export var spawn_wave: bool = true
@export var wave_hear_radius: float = 350.0

var mini_wave_scene: PackedScene = preload("res://scenes/fx/SoundWave.tscn")
var _timer: float = 0.0
var _next: float = 0.0

func _ready() -> void:
	max_distance = 400.0
	attenuation = 1.6
	volume_db = -4.0
	bus = "Master"
	_next = randf_range(0.3, max_interval)
	_schedule_next()

func _process(delta: float) -> void:
	_timer += delta
	if _timer >= _next:
		_timer = 0.0
		_play_once()
		_schedule_next()

const SOUNDS := {
	"drop": [
		preload("res://assets/sounds/Water_1.ogg"),
		preload("res://assets/sounds/Water_2.ogg"),
		preload("res://assets/sounds/Water_3.ogg"),
		preload("res://assets/sounds/Water_4.ogg"),
	],
	"rock": [
		preload("res://assets/sounds/Stone_1.ogg"),
		preload("res://assets/sounds/Stone_2.ogg"),
		preload("res://assets/sounds/Stone_3.ogg"),
		preload("res://assets/sounds/Stone_4.ogg"),
	],
}

func _play_once() -> void:
	var variants = SOUNDS.get(sound_type, [])
	if variants.is_empty():
		return
	stream = variants.pick_random()
	pitch_scale = 1.0 + randf_range(-random_pitch, random_pitch)
	play()
	
	if spawn_wave and _player_can_hear():
		_spawn_mini_wave()

func _spawn_mini_wave() -> void:
	if mini_wave_scene == null:
		return
	var w = mini_wave_scene.instantiate()
	w.global_position = global_position
	w.max_scale = 2.0
	w.max_energy = 0.8
	w.ray_count = 8
	w.fade_duration = 0.4
	w.set("spawn_echo_points", false)
	get_parent().add_child(w)

func _player_can_hear() -> bool:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		player = get_tree().get_first_node_in_group("Player") 
	if player == null:
		return false
	return global_position.distance_to(player.global_position) <= wave_hear_radius

func _schedule_next() -> void:
	_next = randf_range(min_interval, max_interval)
