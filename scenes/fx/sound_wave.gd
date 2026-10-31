extends Node2D

@export var max_scale: float = 8.0
@export var max_energy: float = 3.0
@export var expand_duration: float = 0.6  # Время расширения волны на 100% яркости до конца
@export var fade_duration: float = 1.5    # Время плавного затухания энергии ПОСЛЕ достижения конца
@export var ray_count: int = 64
@export var wall_reveal_duration: float = 3.0
@export var spawn_echo_points: bool = true

# Свойство duration для совместимости с player.gd
var duration: float:
	get:
		return fade_duration
	set(val):
		fade_duration = val

@onready var light: PointLight2D = $PointLight2D
@onready var area_2d: Area2D = $Area2D
@onready var collision_shape: CollisionShape2D = $Area2D/CollisionShape2D

var echo_point_scene: PackedScene = preload("res://scenes/fx/EchoPoint.tscn")
var current_radius: float = 0.0
var current_intensity: float = 1.0

func _ready() -> void:
	ensure_ring_texture()

	if light:
		light.energy = max_energy
		light.texture_scale = 0.1
		light.shadow_enabled = true

	if collision_shape and collision_shape.shape is CircleShape2D:
		collision_shape.shape.radius = 10.0

	# Последовательная двухфазная анимация волны
	var tween = create_tween()

	# ФАЗА 1: Волна быстро расширяется до края на 100% ПОЛНОЙ яркости
	tween.tween_property(light, "texture_scale", max_scale, expand_duration)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# ФАЗА 2: ТОЛЬКО ПОСЛЕ достижения конца энергия волны плавно гаснет до 0
	tween.tween_property(light, "energy", 0.0, fade_duration)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# Удаляем узел после завершения затухания
	tween.tween_callback(queue_free)

	call_deferred("cast_echolocation_rays")

func _process(_delta: float) -> void:
	if light:
		current_radius = light.texture_scale * 128.0
		current_intensity = light.energy / max_energy if max_energy > 0.0 else 0.0
		if collision_shape and collision_shape.shape is CircleShape2D:
			collision_shape.shape.radius = current_radius

func ensure_ring_texture() -> void:
	if light and light.texture == null:
		light.texture = create_ring_texture()

func create_ring_texture() -> GradientTexture2D:
	var tex = GradientTexture2D.new()
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(0.5, 0.0)

	var grad = Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.75, 0.88, 0.96, 1.0])
	grad.colors = PackedColorArray([
		Color(0.0, 0.0, 0.0, 0.0),
		Color(0.0, 0.0, 0.0, 0.0),
		Color(1.0, 1.0, 1.0, 1.0),
		Color(1.0, 1.0, 1.0, 0.8),
		Color(0.0, 0.0, 0.0, 0.0)
	])

	tex.gradient = grad
	tex.width = 256
	tex.height = 256
	return tex

func cast_echolocation_rays() -> void:
	if ray_count <= 0:
		return

	var space_state = get_world_2d().direct_space_state
	var actual_max_dist = max_scale * 80.0
	var angle_step = (2.0 * PI) / float(ray_count)

	for i in range(ray_count):
		var angle = i * angle_step
		var ray_dir = Vector2(cos(angle), sin(angle))
		var query = PhysicsRayQueryParameters2D.create(
			global_position,
			global_position + ray_dir * actual_max_dist
		)
		query.exclude = [self]

		var result = space_state.intersect_ray(query)
		if result:
			var hit_pos = result.position
			var hit_normal = result.normal
			var collider = result.collider

			if collider and collider.has_method("reveal"):
				collider.reveal(wall_reveal_duration)

			if spawn_echo_points and echo_point_scene:
				var echo = echo_point_scene.instantiate()
				echo.global_position = hit_pos
				if echo.has_method("setup"):
					echo.setup(hit_normal)
				get_parent().add_child(echo)

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.has_method("reveal"):
		body.reveal(wall_reveal_duration)
