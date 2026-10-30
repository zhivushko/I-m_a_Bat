extends Node2D

@onready var canvas_modulate: CanvasModulate = $CanvasModulate
@onready var player: CharacterBody2D = $Player
@onready var walls_container: Node2D = $Walls

var wall_scene: PackedScene = preload("res://Wall.tscn")

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color.BLACK)
	if canvas_modulate:
		canvas_modulate.color = Color(0, 0, 0, 1)

	if walls_container and walls_container.get_child_count() == 0:
		build_test_maze()

func _process(_delta: float) -> void:
	update_sonar_shader_on_walls()

func update_sonar_shader_on_walls() -> void:
	if walls_container == null:
		return

	var centers: Array = []
	var radii: Array = []
	var thicknesses: Array = []
	var intensities: Array = []

	for child in get_children():
		if child.has_method("cast_echolocation_rays") and child.get("current_radius") != null:
			if centers.size() < 8:
				centers.append(child.global_position)
				radii.append(child.get("current_radius"))
				thicknesses.append(35.0)
				intensities.append(child.get("current_intensity"))

	for wall in walls_container.get_children():
		if wall.has_method("update_sonar_waves"):
			wall.update_sonar_waves(centers, radii, thicknesses, intensities)

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
