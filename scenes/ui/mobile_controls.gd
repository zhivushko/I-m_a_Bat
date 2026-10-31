extends Control

signal movement_changed(direction: Vector2)
signal sonar_pressed

const MOUSE_POINTER: int = -2
const DEAD_ZONE: float = 0.12

@onready var pause_panel: Control = $PausePanel
@onready var resume_button: Button = $PausePanel/Center/Panel/Margin/Buttons/Resume
@onready var restart_button: Button = $PausePanel/Center/Panel/Margin/Buttons/Restart
@onready var levels_button: Button = $PausePanel/Center/Panel/Margin/Buttons/Levels

var movement: Vector2 = Vector2.ZERO
var joystick_center: Vector2
var sonar_center: Vector2
var pause_center: Vector2
var ui_scale: float = 1.0
var joystick_pointer: int = -1
var sonar_pointer: int = -1
var joystick_offset: Vector2 = Vector2.ZERO
var sonar_flash: float = 0.0
var owns_pause: bool = false
var player: CharacterBody2D

func _ready() -> void:
	resized.connect(_update_layout)
	resume_button.pressed.connect(_resume)
	restart_button.pressed.connect(_restart)
	levels_button.pressed.connect(_open_levels)
	_update_layout()

func bind_player(target: CharacterBody2D) -> void:
	player = target
	movement_changed.connect(player.set_mobile_movement)
	sonar_pressed.connect(player.stomp)

func _process(delta: float) -> void:
	var blocked: bool = not is_instance_valid(player) or player.get("is_dead") == true
	blocked = blocked or (get_tree().paused and not owns_pause)
	visible = not blocked
	if blocked or owns_pause:
		_release_all()
	if sonar_flash > 0.0:
		sonar_flash = maxf(0.0, sonar_flash - delta)
		queue_redraw()

func _update_layout() -> void:
	_release_all()
	ui_scale = clampf(minf(size.x, size.y) / 720.0, 0.8, 1.15)
	var insets := Vector4.ZERO
	if OS.has_feature("mobile"):
		var safe := DisplayServer.get_display_safe_area()
		var screen_size := Vector2(DisplayServer.window_get_size())
		if safe.has_area() and screen_size.x > 0.0 and screen_size.y > 0.0:
			var ratio := size / screen_size
			insets = Vector4(safe.position.x * ratio.x, safe.position.y * ratio.y,
				maxf(0.0, screen_size.x - safe.end.x) * ratio.x,
				maxf(0.0, screen_size.y - safe.end.y) * ratio.y)
	var bottom := size.y - insets.w - 108.0 * ui_scale
	joystick_center = Vector2(insets.x + 108.0 * ui_scale, bottom)
	sonar_center = Vector2(size.x - insets.z - 108.0 * ui_scale, bottom)
	pause_center = Vector2(size.x - insets.z - 54.0 * ui_scale, insets.y + 54.0 * ui_scale)
	queue_redraw()

func _draw() -> void:
	var white := Color(1.0, 1.0, 1.0, 0.42)
	var active := Color(1.0, 1.0, 1.0, 0.85)
	var radius := 76.0 * ui_scale
	draw_circle(joystick_center, radius, Color(0.0, 0.0, 0.0, 0.2))
	draw_arc(joystick_center, radius, 0.0, TAU, 80, white, 1.5 * ui_scale, true)
	draw_arc(joystick_center, 52.0 * ui_scale, 0.0, TAU, 64, Color(1, 1, 1, 0.1), ui_scale, true)
	var knob := joystick_center + joystick_offset
	draw_circle(knob, 27.0 * ui_scale, Color(1, 1, 1, 0.08))
	draw_arc(knob, 27.0 * ui_scale, 0.0, TAU, 48, active, 1.5 * ui_scale, true)
	draw_circle(knob, 2.0 * ui_scale, active)
	var echo_active := sonar_pointer != -1 or sonar_flash > 0.0
	draw_circle(sonar_center, 56.0 * ui_scale, Color(1, 1, 1, 0.13 if echo_active else 0.035))
	draw_arc(sonar_center, 56.0 * ui_scale, 0.0, TAU, 64, active if echo_active else white, 1.5 * ui_scale, true)
	for index in range(3):
		draw_arc(sonar_center, (12.0 + index * 11.0) * ui_scale, -PI * 0.7, PI * 0.7, 32,
			Color(1, 1, 1, 0.85 - index * 0.2), 1.6 * ui_scale, true)
	draw_circle(sonar_center, 3.0 * ui_scale, active)
	draw_string(ThemeDB.fallback_font, sonar_center + Vector2(-60, 88) * ui_scale,
		"ЭХО", HORIZONTAL_ALIGNMENT_CENTER, 120.0 * ui_scale, int(16 * ui_scale), active)
	draw_circle(pause_center, 24.0 * ui_scale, Color(0, 0, 0, 0.25))
	draw_arc(pause_center, 24.0 * ui_scale, 0.0, TAU, 48, white, ui_scale, true)
	for x in [-5.0, 5.0]:
		draw_line(pause_center + Vector2(x, -7) * ui_scale, pause_center + Vector2(x, 7) * ui_scale, active, 2.5 * ui_scale, true)

func _input(event: InputEvent) -> void:
	if not visible or owns_pause or get_tree().paused or not is_instance_valid(player) or player.get("is_dead") == true:
		return
	if event is InputEventMouse and event.device == InputEvent.DEVICE_ID_EMULATION:
		return
	var consumed := false
	if event is InputEventScreenTouch:
		if event.pressed and not event.canceled:
			consumed = _press(event.index, _local_point(event.position))
		else:
			consumed = _release(event.index)
	elif event is InputEventScreenDrag:
		consumed = _drag(event.index, _local_point(event.position))
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			consumed = _press(MOUSE_POINTER, _local_point(event.position))
		else:
			consumed = _release(MOUSE_POINTER)
	elif event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
		consumed = _drag(MOUSE_POINTER, _local_point(event.position))
	if consumed:
		get_viewport().set_input_as_handled()

func _local_point(point: Vector2) -> Vector2:
	return get_global_transform_with_canvas().affine_inverse() * point

func _press(pointer: int, point: Vector2) -> bool:
	if point.distance_to(pause_center) <= 34.0 * ui_scale:
		_open_pause()
		return true
	if joystick_pointer == -1 and point.distance_to(joystick_center) <= 108.0 * ui_scale:
		joystick_pointer = pointer
		_set_joystick(point)
		return true
	if sonar_pointer == -1 and point.distance_to(sonar_center) <= 72.0 * ui_scale:
		sonar_pointer = pointer
		sonar_flash = 0.16
		sonar_pressed.emit()
		queue_redraw()
		return true
	return false

func _drag(pointer: int, point: Vector2) -> bool:
	if pointer == joystick_pointer:
		_set_joystick(point)
		return true
	return pointer == sonar_pointer

func _release(pointer: int) -> bool:
	var consumed := false
	if pointer == joystick_pointer:
		joystick_pointer = -1
		_set_movement(Vector2.ZERO)
		joystick_offset = Vector2.ZERO
		consumed = true
	if pointer == sonar_pointer:
		sonar_pointer = -1
		consumed = true
	queue_redraw()
	return consumed

func _set_joystick(point: Vector2) -> void:
	var direction := ((point - joystick_center) / (56.0 * ui_scale)).limit_length(1.0)
	joystick_offset = direction * 49.0 * ui_scale
	var strength := maxf(0.0, (direction.length() - DEAD_ZONE) / (1.0 - DEAD_ZONE))
	_set_movement(direction.normalized() * strength)
	queue_redraw()

func _set_movement(value: Vector2) -> void:
	if movement != value:
		movement = value
		movement_changed.emit(movement)

func _release_all() -> void:
	joystick_pointer = -1
	sonar_pointer = -1
	joystick_offset = Vector2.ZERO
	_set_movement(Vector2.ZERO)
	queue_redraw()

func _open_pause() -> void:
	_release_all()
	owns_pause = true
	pause_panel.show()
	get_tree().paused = true

func _resume() -> void:
	pause_panel.hide()
	owns_pause = false
	get_tree().paused = false
	_release_all()

func _restart() -> void:
	_resume()
	get_tree().reload_current_scene.call_deferred()

func _open_levels() -> void:
	_resume()
	get_tree().change_scene_to_file.call_deferred("res://scenes/ui/LevelSelect.tscn")

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_release_all()
	elif what == NOTIFICATION_APPLICATION_PAUSED and is_instance_valid(player) and not get_tree().paused and not player.get("is_dead"):
		_open_pause()

func _exit_tree() -> void:
	_release_all()
	if owns_pause:
		get_tree().paused = false
