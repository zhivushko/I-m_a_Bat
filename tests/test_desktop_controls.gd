# Run: Godot --headless --path . --fixed-fps 60 --audio-driver Dummy --script res://tests/test_desktop_controls.gd
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

func settle(frames: int = 3) -> void:
	for frame in range(frames):
		await process_frame

func key(code: Key, pressed: bool, repeat: bool = false) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	event.echo = repeat
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func click(button: Button) -> void:
	for pressed in [true, false]:
		mouse(button.get_global_rect().get_center(), pressed)
	await settle()

func mouse(point: Vector2, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = root.get_final_transform() * point
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func waves(scene: Node) -> int:
	return scene.get_children().filter(func(node): return node.has_method("cast_echolocation_rays")).size()

func run() -> void:
	root.size = Vector2i(1280, 720)
	var scene = load("res://scenes/level/level_1.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await settle()
	var player = scene.get_node("Player")
	var hud = scene.get_node("UI/GameHUD")
	check(hud.visible and hud.charge_bar.counter.text == "ЭХО  3/3", "The desktop HUD displays the initial echo reserve")
	check(hud.pause_button.visible, "The on-screen pause button remains available")
	var start_position: Vector2 = player.position
	key(KEY_D, true)
	for frame in range(15):
		await physics_frame
	check(player.position.x > start_position.x + 30.0, "WASD moves the player")
	key(KEY_D, false)
	for frame in range(2):
		await physics_frame
	check(player.velocity == Vector2.ZERO, "Releasing movement stops the player")
	key(KEY_RIGHT, true)
	for frame in range(2):
		await physics_frame
	check(player.velocity.x > 0.0, "Arrow keys also move the player")
	key(KEY_RIGHT, false)
	for frame in range(2):
		await physics_frame
	var before := waves(scene)
	key(KEY_SPACE, true)
	check(waves(scene) == before + 1 and player.sonar_charges == 2, "Space emits one echo and spends one charge")
	key(KEY_SPACE, true, true)
	check(waves(scene) == before + 1, "Keyboard repeat does not duplicate echo")
	key(KEY_SPACE, false)
	# Former joystick and echo areas must no longer intercept desktop clicks.
	var before_clicks := waves(scene)
	mouse(Vector2(148, 580), true)
	var motion := InputEventMouseMotion.new()
	motion.position = root.get_final_transform() * Vector2(210, 580)
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	Input.parse_input_event(motion)
	Input.flush_buffered_events()
	for frame in range(2):
		await physics_frame
	check(player.velocity == Vector2.ZERO, "Dragging in the former joystick area cannot move the player")
	mouse(Vector2(210, 580), false)
	mouse(Vector2(1132, 580), true)
	mouse(Vector2(1132, 580), false)
	check(waves(scene) == before_clicks, "The former mobile echo area has no hidden button")

	await click(hud.pause_button)
	check(paused and hud.owns_pause and hud.pause_panel.visible, "Clicking the retained pause button opens Pause")
	var paused_progress: float = player.get_sonar_recharge_progress()
	for frame in range(10):
		await process_frame
	check(player.get_sonar_recharge_progress() == paused_progress, "Pause freezes echo recharge")
	key(KEY_ESCAPE, true)
	key(KEY_ESCAPE, false)
	await settle()
	check(not paused and not hud.owns_pause, "Escape resumes gameplay")
	key(KEY_ESCAPE, true)
	key(KEY_ESCAPE, false)
	await settle()
	check(paused and hud.pause_panel.visible, "Escape can also open Pause")
	await click(hud.resume_button)
	check(not paused and not hud.owns_pause, "Clicking Continue resumes gameplay")
	await click(hud.pause_button)
	var old_id: int = scene.get_instance_id()
	await click(hud.restart_button)
	await settle()
	check(not paused and current_scene.get_instance_id() != old_id, "Pause Restart reloads the level")
	scene = current_scene
	hud = scene.get_node("UI/GameHUD")
	check(hud.charge_bar.counter.text == "ЭХО  3/3", "Restart restores the charge indicator")
	for dimensions in [Vector2i(960, 540), Vector2i(1920, 1080), Vector2i(2340, 1080)]:
		root.size = dimensions
		await settle()
		var screen := Rect2(Vector2.ZERO, hud.size)
		check(screen.encloses(hud.charge_bar.get_global_rect()), "Charges fit the desktop viewport at " + str(dimensions))
		check(screen.encloses(hud.pause_button.get_global_rect()), "The pause button fits the viewport at " + str(dimensions))
		check(not hud.pause_button.get_global_rect().intersects(hud.charge_bar.get_global_rect()), "Pause and charges do not overlap")
	for path in ["res://scenes/level/Main.tscn", "res://scenes/level/level_2.tscn", "res://scenes/level/level_3.tscn"]:
		root.get_node("MenuNavigation").go_to_scene(path)
		await settle(5)
		hud = current_scene.get_node("UI/GameHUD")
		check(hud.visible and hud.pause_button.visible, "Desktop HUD loads in " + path.get_file())
		check(current_scene.get_node_or_null("UI/MobileControls") == null, "Mobile controls are absent from " + path.get_file())
	current_scene.queue_free()
	await process_frame
	if not failed:
		print("ALL DESKTOP CONTROL CHECKS PASSED")
	quit(1 if failed else 0)
