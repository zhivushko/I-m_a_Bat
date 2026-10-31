# Run: Godot --headless --path . --fixed-fps 60 --audio-driver Dummy --script res://tests/test_mobile_controls.gd
extends SceneTree

var failed: bool = false

func _initialize() -> void:
	run.call_deferred()

func check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: ", message)
	else:
		failed = true
		push_error(message)

func touch(index: int, position: Vector2, pressed: bool, canceled: bool = false) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = root.get_final_transform() * position
	event.pressed = pressed
	event.canceled = canceled
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func drag(index: int, position: Vector2) -> void:
	var event := InputEventScreenDrag.new()
	event.index = index
	event.position = root.get_final_transform() * position
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func tap_button(button: Button, index: int) -> void:
	var center := button.get_global_rect().get_center()
	touch(index, center, true)
	touch(index, center, false)

func waves(scene: Node) -> int:
	return scene.get_children().filter(func(node): return node.has_method("cast_echolocation_rays")).size()

func run() -> void:
	root.size = Vector2i(1280, 720)
	var scene = load("res://scenes/level/level_1.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	for frame in range(3):
		await process_frame
	var player = scene.get_node("Player")
	var controls = scene.get_node("UI/MobileControls")
	check(controls.visible and controls.size == root.get_visible_rect().size, "Mobile controls cover the gameplay viewport")
	check(scene.get_node_or_null("UI/ControlHint") == null, "Debug and keyboard-hint labels are absent")
	var center: Vector2 = controls.joystick_center
	var echo_center: Vector2 = controls.sonar_center
	var full_throw: float = 56.0 * controls.touch_scale
	touch(0, center + Vector2(2, 2), true)
	check(player.mobile_movement == Vector2.ZERO, "Joystick dead zone prevents accidental drift")
	drag(0, center + Vector2(full_throw, 0))
	check(player.mobile_movement.x > 0.99, "A touch drag steers the player")
	var start_position: Vector2 = player.position
	for frame in range(15):
		await physics_frame
	check(player.position.x > start_position.x + 30.0, "Touch input actually moves the player through the level")
	var before_echo := waves(scene)
	touch(3, echo_center, true)
	check(waves(scene) == before_echo + 1, "A second finger emits exactly one sonar wave")
	check(player.mobile_movement.x > 0.99 and controls.joystick_pointer == 0, "Echo does not interrupt a held joystick")
	drag(3, center)
	check(controls.joystick_pointer == 0 and player.mobile_movement.x > 0.99, "Dragging the echo finger cannot steal joystick ownership")
	touch(3, center, false)
	check(player.mobile_movement.x > 0.99, "Releasing echo keeps the movement finger active")
	drag(0, echo_center)
	check(waves(scene) == before_echo + 1, "Dragging the movement finger over echo does not trigger another wave")
	drag(0, center + Vector2(90, -90))
	check(is_equal_approx(player.mobile_movement.length(), 1.0), "Diagonal joystick speed stays bounded")
	touch(0, center, false, true)
	for frame in range(2):
		await physics_frame
	check(player.mobile_movement == Vector2.ZERO and player.velocity == Vector2.ZERO, "Canceling a touch stops the player")
	touch(7, center + Vector2(-full_throw, 0), true)
	controls.notification(controls.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(player.mobile_movement == Vector2.ZERO and controls.joystick_pointer == -1, "Losing focus releases held controls")
	touch(7, center, false)
	var mouse := InputEventMouseButton.new()
	mouse.button_index = MOUSE_BUTTON_LEFT
	mouse.position = center + Vector2(full_throw, 0)
	mouse.pressed = true
	Input.parse_input_event(mouse)
	Input.flush_buffered_events()
	check(player.mobile_movement.x > 0.99, "Mouse dragging can preview mobile controls on desktop")
	mouse = mouse.duplicate()
	mouse.pressed = false
	Input.parse_input_event(mouse)
	Input.flush_buffered_events()
	check(player.mobile_movement == Vector2.ZERO, "Mouse release resets the joystick")
	touch(0, center + Vector2(full_throw, 0), true)
	touch(8, controls.pause_center, true)
	for frame in range(2):
		await process_frame
	check(paused and controls.owns_pause and controls.pause_panel.visible, "The pause control opens a usable pause menu")
	check(player.mobile_movement == Vector2.ZERO, "Opening pause clears held movement")
	before_echo = waves(scene)
	touch(9, echo_center, true)
	check(waves(scene) == before_echo, "Gameplay touch controls are inactive while paused")
	tap_button(controls.resume_button, 10)
	for frame in range(2):
		await process_frame
	check(not paused and not controls.owns_pause, "Touching Continue resumes gameplay")
	if paused:
		controls._resume()
	var key := InputEventKey.new()
	key.keycode = KEY_SPACE
	key.physical_keycode = KEY_SPACE
	key.pressed = true
	before_echo = waves(scene)
	Input.parse_input_event(key)
	Input.flush_buffered_events()
	check(waves(scene) == before_echo + 1, "Keyboard echo still emits one wave per key press")
	key = key.duplicate()
	key.echo = true
	Input.parse_input_event(key)
	Input.flush_buffered_events()
	check(waves(scene) == before_echo + 1, "Keyboard repeat cannot duplicate echo")
	key = key.duplicate()
	key.echo = false
	key.pressed = false
	Input.parse_input_event(key)
	Input.flush_buffered_events()
	touch(0, center + Vector2(full_throw, 0), true)
	player.die()
	for frame in range(4):
		await process_frame
	check(not controls.visible and player.mobile_movement == Vector2.ZERO, "Death hides and releases the mobile controls")
	for frame in range(150):
		await process_frame
	scene = current_scene
	controls = scene.get_node("UI/MobileControls")
	check(not paused and controls.visible and controls.movement == Vector2.ZERO, "Respawn restores fresh controls without stuck movement")
	var scene_id: int = scene.get_instance_id()
	touch(12, controls.pause_center, true)
	for frame in range(2):
		await process_frame
	tap_button(controls.restart_button, 13)
	for frame in range(5):
		await process_frame
	check(not paused and current_scene.get_instance_id() != scene_id, "Touching Restart restarts the current level")
	controls = current_scene.get_node("UI/MobileControls")
	touch(14, controls.pause_center, true)
	for frame in range(2):
		await process_frame
	tap_button(controls.levels_button, 15)
	for frame in range(5):
		await process_frame
	check(not paused and current_scene.scene_file_path.ends_with("LevelSelect.tscn"), "Touching Level Select leaves pause and opens the menu")
	if paused:
		paused = false
	for path in ["res://scenes/level/Main.tscn", "res://scenes/level/level_2.tscn", "res://scenes/level/level_3.tscn"]:
		change_scene_to_file(path)
		for frame in range(4):
			await process_frame
		controls = current_scene.get_node("UI/MobileControls")
		check(controls.visible and current_scene.get_node_or_null("UI/ControlHint") == null, "Clean mobile controls load in " + path.get_file())
	for window_size in [Vector2i(960, 540), Vector2i(2340, 1080), Vector2i(720, 960)]:
		root.size = window_size
		for frame in range(3):
			await process_frame
		var screen := Rect2(Vector2.ZERO, controls.size)
		check(screen.has_point(controls.joystick_center) and screen.has_point(controls.sonar_center) and screen.has_point(controls.pause_center), "Touch controls stay on screen after resizing to " + str(window_size))
		check(screen.encloses(controls.charge_bar.get_global_rect()), "The charge indicator stays within the resized viewport")
		check(controls.charge_bar.get_global_rect().end.x < controls.pause_center.x - 34.0 * controls.ui_scale, "The charge indicator stays clear of the pause button")
		touch(30, controls.joystick_center + Vector2(56 * controls.touch_scale, 0), true)
		check(controls.movement.x > 0.99, "Physical touch coordinates still hit the joystick at " + str(window_size))
		touch(30, controls.joystick_center, false)
		var count_before := waves(current_scene)
		touch(31, controls.sonar_center, true)
		check(waves(current_scene) == count_before + 1, "Echo hit area matches its drawn position at " + str(window_size))
		touch(31, controls.sonar_center, false)
	current_scene.queue_free()
	await process_frame
	if not failed:
		print("ALL MOBILE CONTROL CHECKS PASSED")
	quit(1 if failed else 0)
