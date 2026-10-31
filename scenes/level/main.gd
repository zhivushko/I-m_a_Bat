extends Node2D

@onready var canvas_modulate: CanvasModulate = $CanvasModulate
@onready var player: CharacterBody2D = $Player
@onready var walls_layer: TileMapLayer = $TileMapLayer
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
		# Только SoundWave (у него есть cast_echolocation_rays)
		if child.has_method("cast_echolocation_rays") and child.get("current_radius") != null:
			if centers.size() < 8:
				centers.append(child.global_position)
				radii.append(child.get("current_radius"))
				max_radii.append(child.get("max_radius"))
				alphas.append(child.get("global_alpha"))
	
	walls_layer.update_sonar_waves(centers, radii, max_radii, alphas)
