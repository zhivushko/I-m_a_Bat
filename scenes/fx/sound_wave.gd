extends Node2D

@export var max_scale: float = 8.0
@export var max_radius: float = 600.0
@export var max_energy: float = 3.0
@export var expand_duration: float = 0.6  # Время расширения сплошного круга до max_scale
@export var fade_duration: float = 1.5    # Время угасания энергии ПОСЛЕ завершения роста
@export var ray_count: int = 64
@export var wall_reveal_duration: float = 3.0
@export var spawn_echo_points: bool = true

var current_radius: float = 0.0
var global_alpha: float = 1.0

# Свойство duration для совместимости с вызовами из player.gd
var duration: float:
	get:
		return fade_duration
	set(val):
		fade_duration = val

@onready var light: PointLight2D = $PointLight2D
@onready var area_2d: Area2D = $Area2D
@onready var collision_shape: CollisionShape2D = $Area2D/CollisionShape2D

var echo_point_scene: PackedScene = preload("res://scenes/fx/EchoPoint.tscn")

func _ready() -> void:
	ensure_circle_texture()

	if light:
		light.energy = max_energy
		light.texture_scale = 0.1
		light.shadow_enabled = true

	if collision_shape and collision_shape.shape is CircleShape2D:
		collision_shape.shape.radius = 10.0

	var tween = create_tween()

	# ФАЗА 1: Сплошной заполненный круг света расширяется от 0.1 до max_scale на 100% яркости
	tween.tween_property(light, "texture_scale", max_scale, expand_duration)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "current_radius", max_radius, expand_duration)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# ФАЗА 2: ТОЛЬКО ПОСЛЕ завершения роста гасим энергию света и общую прозрачность
	tween.tween_property(light, "energy", 0.0, fade_duration)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(self, "global_alpha", 0.0, fade_duration)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# Удаление узла после полного затухания
	tween.tween_callback(queue_free)

	call_deferred("cast_echolocation_rays")

func _process(_delta: float) -> void:
	if collision_shape and collision_shape.shape is CircleShape2D:
		collision_shape.shape.radius = current_radius

func ensure_circle_texture() -> void:
	if light and light.texture == null:
		light.texture = create_circle_texture()

func create_circle_texture() -> GradientTexture2D:
	var tex = GradientTexture2D.new()
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(0.5, 0.0)

	var grad = Gradient.new()
	# СПЛОШНОЙ ЗАПОЛНЕННЫЙ КРУГ СВЕТА (БЕЗ ДЫРКИ / БУБЛИКА В ЦЕНТРЕ)
	grad.offsets = PackedFloat32Array([0.0, 0.85, 1.0])
	grad.colors = PackedColorArray([
		Color(1.0, 1.0, 1.0, 1.0),
		Color(1.0, 1.0, 1.0, 1.0),
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
	var angle_step = (2.0 * PI) / float(ray_count)

	for i in range(ray_count):
		var angle = i * angle_step
		var ray_dir = Vector2(cos(angle), sin(angle))
		var query = PhysicsRayQueryParameters2D.create(
			global_position,
			global_position + ray_dir * max_radius
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
