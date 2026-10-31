extends CharacterBody2D

@export var speed: float = 220.0
@export var step_interval: float = 0.4
@export var sound_wave_scene: PackedScene = preload("res://scenes/fx/SoundWave.tscn")

var step_timer: float = 0.0

@onready var light: PointLight2D = $PointLight2D
@onready var contour_line: Line2D = $Line2D
@onready var camera: Camera2D = $Camera2D
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	setup_player_visuals()

func setup_player_visuals() -> void:
	if contour_line:
		var circle_points = PackedVector2Array()
		var radius = 14.0
		var segments = 24
		for i in range(segments + 1):
			var angle = (float(i) / float(segments)) * 2.0 * PI
			circle_points.append(Vector2(cos(angle), sin(angle)) * radius)
		contour_line.points = circle_points
		contour_line.width = 2.0
		contour_line.default_color = Color.WHITE

		var mat = CanvasItemMaterial.new()
		mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
		contour_line.material = mat

	if light and light.texture == null:
		light.texture = create_player_glow_texture()
		light.energy = 0.5
		light.texture_scale = 0.8
		light.shadow_enabled = false

	if animated_sprite:
		var mat = CanvasItemMaterial.new()
		mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
		animated_sprite.material = mat

func create_player_glow_texture() -> GradientTexture2D:
	var tex = GradientTexture2D.new()
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(0.5, 0.0)

	var grad = Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.4, 1.0])
	grad.colors = PackedColorArray([
		Color(1.0, 1.0, 1.0, 0.6),
		Color(1.0, 1.0, 1.0, 0.3),
		Color(0.0, 0.0, 0.0, 0.0)
	])

	tex.gradient = grad
	tex.width = 128
	tex.height = 128
	return tex

func _physics_process(delta: float) -> void:
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	if input_dir == Vector2.ZERO:
		var dx = (1.0 if Input.is_key_pressed(KEY_D) else 0.0) - (1.0 if Input.is_key_pressed(KEY_A) else 0.0)
		var dy = (1.0 if Input.is_key_pressed(KEY_S) else 0.0) - (1.0 if Input.is_key_pressed(KEY_W) else 0.0)
		input_dir = Vector2(dx, dy).normalized()

	velocity = input_dir * speed
	move_and_slide()

	update_animation(input_dir)

	if velocity.length() > 10.0:
		step_timer += delta
		if step_timer >= step_interval:
			step_timer = 0.0
			spawn_sound_wave(3.0, 1.5, 24, 1.2)
	else:
		step_timer = step_interval

	if Input.is_action_just_pressed("ui_accept") or Input.is_key_pressed(KEY_SPACE):
		if not get_meta("stomp_triggered_this_frame", false):
			set_meta("stomp_triggered_this_frame", true)
			stomp()
	else:
		set_meta("stomp_triggered_this_frame", false)

func update_animation(input_dir: Vector2) -> void:
	if animated_sprite == null or animated_sprite.sprite_frames == null:
		return

	var frames = animated_sprite.sprite_frames

	if velocity.length() > 10.0:
		if animated_sprite:
			animated_sprite.flip_h = (input_dir.x < 0)

		if frames.has_animation("walk"):
			animated_sprite.play("walk")
		elif frames.has_animation("move"):
			animated_sprite.play("move")
		elif frames.has_animation("new_animation"):
			animated_sprite.play("new_animation")
		elif frames.has_animation("default"):
			animated_sprite.play("default")
	else:
		if frames.has_animation("idle"):
			animated_sprite.play("idle")
		elif frames.has_animation("default"):
			animated_sprite.play("default")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE:
			stomp()

func stomp() -> void:
	spawn_sound_wave(8.5, 3.5, 64, 1.6)
	shake_camera()

	if animated_sprite and animated_sprite.sprite_frames:
		if animated_sprite.sprite_frames.has_animation("stomp"):
			animated_sprite.play("stomp")
		elif animated_sprite.sprite_frames.has_animation("attack"):
			animated_sprite.play("attack")

func shake_camera() -> void:
	if camera:
		var tween = create_tween()
		for i in range(4):
			var offset_vec = Vector2(randf_range(-6.0, 6.0), randf_range(-6.0, 6.0))
			tween.tween_property(camera, "offset", offset_vec, 0.04)
		tween.tween_property(camera, "offset", Vector2.ZERO, 0.04)

func spawn_sound_wave(max_scale: float, energy: float, num_rays: int, duration: float) -> void:
	if not sound_wave_scene:
		return
	var wave = sound_wave_scene.instantiate()
	wave.global_position = global_position
	wave.max_scale = max_scale
	wave.max_energy = energy
	wave.ray_count = num_rays
	wave.fade_duration = duration
	get_parent().add_child(wave)
