extends TileMapLayer

var shader_material: ShaderMaterial

func _ready() -> void:
	# Назначаем шейдер эха на весь слой
	var sonar_shader = load("res://assets/shaders/echo_wave.gdshader")
	if sonar_shader:
		shader_material = ShaderMaterial.new()
		shader_material.shader = sonar_shader
		material = shader_material

func reveal(duration: float = 3.0) -> void:
	# Вызывается из sound_wave.gd при попадании луча
	if shader_material == null:
		return
	shader_material.set_shader_parameter("reveal_alpha", 1.0)
	var tween = create_tween()
	tween.tween_method(
		func(val: float): shader_material.set_shader_parameter("reveal_alpha", val),
		1.0, 0.0, duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func update_sonar_waves(centers: Array, radii: Array, max_radii: Array, alphas: Array) -> void:
	if shader_material == null:
		return
	shader_material.set_shader_parameter("wave_centers", centers)
	shader_material.set_shader_parameter("wave_radii", radii)
	shader_material.set_shader_parameter("max_radii", max_radii)
	shader_material.set_shader_parameter("global_alphas", alphas)
	shader_material.set_shader_parameter("active_waves_count", centers.size())
