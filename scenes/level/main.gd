extends Node2D

@onready var canvas_modulate: CanvasModulate = $CanvasModulate
@onready var player: CharacterBody2D = $Player
@onready var walls_layer: TileMapLayer = $WallsLayer
@onready var ambient: AudioStreamPlayer = $AmbientHum
@onready var audio_points: Node2D = $AudioPoints

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color.BLACK)
	if canvas_modulate:
		canvas_modulate.color = Color(0, 0, 0, 1)
	if ambient:
		ambient.volume_db = -20.0
		if not ambient.playing:
			ambient.play()

func _process(_delta: float) -> void:
	update_sonar_shader_on_walls()

func update_sonar_shader_on_walls() -> void:
	if walls_layer == null:
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
				max_radii.append(max_r if max_r != null else 200.0)
				var g_alpha = child.get("global_alpha")
				alphas.append(g_alpha if g_alpha != null else 1.0)

	walls_layer.update_sonar_waves(centers, radii, max_radii, alphas)
