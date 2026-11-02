extends CharacterBody2D

const DEATH_EFFECT: PackedScene = preload("res://scenes/fx/DeathEffect.tscn")

@export var speed: float = 220.0
@export var step_interval: float = 0.45
@export var sound_wave_scene: PackedScene = preload("res://scenes/fx/SoundWave.tscn")

@export_group("Audio")
@export var screech_sound: AudioStream
@export var wing_flap_sound: AudioStream

var step_timer: float = 0.0
var is_dead: bool = false
var mobile_movement: Vector2 = Vector2.ZERO

@onready var light: PointLight2D = $PointLight2D
@onready var contour_line: Line2D = $Line2D
@onready var camera: Camera2D = $Camera2D
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

@onready var wing_flap_audio: AudioStreamPlayer2D = $WingFlapAudio
@onready var screech_audio: AudioStreamPlayer2D = $ScreechAudio

func _ready() -> void:
	setup_player_visuals()
	setup_audio_streams()
	add_to_group("player")

func setup_audio_streams() -> void:
	if screech_audio and screech_sound:
		screech_audio.stream = screech_sound
	if wing_flap_audio and wing_flap_sound:
		wing_flap_audio.stream = wing_flap_sound

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
	if is_dead:
		return
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	if input_dir == Vector2.ZERO:
		var dx = (1.0 if Input.is_key_pressed(KEY_D) else 0.0) - (1.0 if Input.is_key_pressed(KEY_A) else 0.0)
		var dy = (1.0 if Input.is_key_pressed(KEY_S) else 0.0) - (1.0 if Input.is_key_pressed(KEY_W) else 0.0)
		input_dir = Vector2(dx, dy).normalized()
	if mobile_movement != Vector2.ZERO:
		input_dir = mobile_movement

	velocity = input_dir * speed
	move_and_slide()

	update_animation(input_dir)

	update_wing_flap_audio(velocity.length() > 10.0)
	
	update_tilt(input_dir)
	
	if velocity.length() > 10.0:
		step_timer += delta
		if step_timer >= step_interval:
			step_timer = 0.0
			spawn_sound_wave(1.5, 0.5, 32, 0.8)
	else:
		step_timer = step_interval
	
	if Input.is_action_just_pressed("ui_accept") or Input.is_key_pressed(KEY_SPACE):
		if not get_meta("stomp_triggered_this_frame", false):
			set_meta("stomp_triggered_this_frame", true)
			stomp()
	else:
		set_meta("stomp_triggered_this_frame", false)
		
func play_wing_flap_sound() -> void:
	if wing_flap_audio:
		if wing_flap_sound and wing_flap_audio.stream == null:
			wing_flap_audio.stream = wing_flap_sound
		if wing_flap_audio.stream != null:
			wing_flap_audio.pitch_scale = randf_range(0.95, 1.05)
			wing_flap_audio.volume_db = randf_range(-2.0, 2.0)
			wing_flap_audio.play()

func play_screech_sound() -> void:
	if screech_audio:
		if screech_sound and screech_audio.stream == null:
			screech_audio.stream = screech_sound
		if screech_audio.stream != null:
			screech_audio.pitch_scale = randf_range(0.9, 1.1)
			screech_audio.play()

func update_animation(input_dir: Vector2) -> void:
	if animated_sprite == null or animated_sprite.sprite_frames == null:
		return

	var frames = animated_sprite.sprite_frames

	if velocity.length() > 10.0:
		if animated_sprite:
			animated_sprite.flip_h = (input_dir.x < 0)

		
	if frames.has_animation("move"):
		animated_sprite.play("move")
		

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") and not event.is_echo():
		stomp()
		get_viewport().set_input_as_handled()

func set_mobile_movement(direction: Vector2) -> void:
	mobile_movement = direction.limit_length(1.0)

func stomp() -> void:
	if is_dead:
		return
	play_screech_sound()
	spawn_sound_wave(2, 1, 64, 1)
	shake_camera()

	

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
	wave.max_radius = 100
	print("[player] max_radius set to ", wave.max_radius)
	get_parent().add_child(wave)

func die() -> void:
	if is_dead or get_tree().paused:
		return
	is_dead = true
	mobile_movement = Vector2.ZERO
	velocity = Vector2.ZERO
	set_physics_process(false)
	set_process_unhandled_input(false)
	wing_flap_audio.stop()
	screech_audio.stop()
	_show_death_effect.call_deferred()

func _show_death_effect() -> void:
	var screen_origin := get_global_transform_with_canvas().origin / get_viewport_rect().size
	var effect := DEATH_EFFECT.instantiate()
	get_tree().root.add_child(effect)
	effect.play(screen_origin)
	
func update_wing_flap_audio(is_moving: bool) -> void:
	if wing_flap_audio == null or wing_flap_audio.stream == null:
		return
	if is_moving and not wing_flap_audio.playing:
		wing_flap_audio.volume_db = -40.0
		wing_flap_audio.pitch_scale = randf_range(0.95, 1.05)
		wing_flap_audio.play()
		create_tween().tween_property(wing_flap_audio, "volume_db", -10.0, 0.2)
	
	elif not is_moving and wing_flap_audio.playing:
		if wing_flap_audio.get_meta("fading_out", false):
			return
		wing_flap_audio.set_meta("fading_out", true)
		
		var t = create_tween()
		t.tween_property(wing_flap_audio, "volume_db", -40.0, 0.25)
		t.tween_callback(func():
			wing_flap_audio.stop()
			wing_flap_audio.set_meta("fading_out", false)
		)
func update_tilt(input_dir: Vector2) -> void:
	if animated_sprite == null:
		return
		
	var target_rotation: float = 0.0
	
	if input_dir != Vector2.ZERO:
		# Получаем угол вектора движения (в радианах)
		var angle_rad = input_dir.angle()
		
		# Если персонаж движется ВПРАВО (или вправо-вверх/вниз)
		if input_dir.x > 0:
			# В Godot ось Y смотрит вниз, поэтому чтобы наклонить нос ВВЕРХ, 
			# нужно вычесть угол из 0 (или прибавить отрицательный).
			# Вправо-вверх (y < 0) даст нам отрицательный угол (поворот против часовой).
			target_rotation = angle_rad
			
		# Если персонаж движется ВЛЕВО (спрайт отражен)
		elif input_dir.x < 0:
			# Из-за flip_h текстура смотрит влево. 
			# Чтобы наклонить нос ВВЕРХ (против часовой стрелки визуально),
			# нужно инвертировать угол по оси Y.
			target_rotation = -angle_rad
			
		# Если летит строго вверх или вниз (x == 0)
		else:
			target_rotation = 0.0
			
		# Ограничиваем максимальный наклон, чтобы не было кувырков через голову.
		# Например, чтобы нос не задирался выше 45 градусов (PI/4) от горизонтали.
		target_rotation = clamp(target_rotation, -PI / 4.0, PI / 4.0)
		
	animated_sprite.rotation = target_rotation
