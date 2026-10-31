extends Node2D

var level_time: float = 0.0

@onready var canvas_modulate: CanvasModulate = $CanvasModulate
@onready var player: CharacterBody2D = $Player
@onready var walls_container: Node2D = $Walls
@onready var ambient: AudioStreamPlayer = $AmbientHum
@onready var audio_points: Node2D = $AudioPoints

var wall_scene: PackedScene = preload("res://scenes/world/Wall.tscn")

func _ready() -> void:
	level_time = 0.0
	RenderingServer.set_default_clear_color(Color.BLACK)
	if canvas_modulate:
		canvas_modulate.color = Color(0, 0, 0, 1)

	if walls_container and walls_container.get_child_count() == 0:
		build_test_maze()
	
	if ambient:
		ambient.volume_db = -20.0
		if not ambient.playing:
			ambient.play()

func _process(delta: float) -> void:
	if not get_tree().paused:
		level_time += delta
	update_sonar_shader_on_walls()

func update_sonar_shader_on_walls() -> void:
	if walls_container == null:
		return

	var centers: Array = []
	var radii: Array = []
	var max_radii: Array = []
	var alphas: Array = []

	for child in get_children():
		if child.has_method("cast_echolocation_rays") and child.get("current_radius") != null:
			if centers.size() < 8:
				centers.append(child.global_position)
				radii.append(child.get("current_radius"))
				var max_r = child.get("max_radius")
				max_radii.append(max_r if max_r != null else 600.0)
				var g_alpha = child.get("global_alpha")
				alphas.append(g_alpha if g_alpha != null else 1.0)

	for wall in walls_container.get_children():
		if wall.has_method("update_sonar_waves"):
			wall.update_sonar_waves(centers, radii, max_radii, alphas)

func build_test_maze() -> void:
	var wall_data = [
		[Vector2(640, 30), Vector2(1200, 30)],
		[Vector2(640, 690), Vector2(1200, 30)],
		[Vector2(30, 360), Vector2(30, 690)],
		[Vector2(1250, 360), Vector2(30, 690)],

		[Vector2(300, 200), Vector2(250, 40)],
		[Vector2(500, 350), Vector2(40, 260)],
		[Vector2(300, 500), Vector2(200, 40)],
		[Vector2(800, 220), Vector2(40, 280)],
		[Vector2(950, 450), Vector2(280, 40)],
		[Vector2(700, 550), Vector2(200, 40)],
		[Vector2(1050, 250), Vector2(40, 200)]
	]

	for data in wall_data:
		var pos = data[0]
		var size = data[1]

		var w = wall_scene.instantiate()
		w.global_position = pos

		var half_w = size.x / 2.0
		var half_h = size.y / 2.0
		var poly = PackedVector2Array([
			Vector2(-half_w, -half_h),
			Vector2(half_w, -half_h),
			Vector2(half_w, half_h),
			Vector2(-half_w, half_h)
		])
		w.polygon_points = poly
		walls_container.add_child(w)
