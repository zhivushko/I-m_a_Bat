# Run: Godot --headless --path . --fixed-fps 60 --audio-driver Dummy --script res://tests/test_sonar_charges.gd
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

func waves(scene: Node) -> int:
	return scene.get_children().filter(func(node): return node.has_method("cast_echolocation_rays")).size()

func touch(index: int, point: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = root.get_final_transform() * point
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func run() -> void:
	root.size = Vector2i(1280, 720)
	var scene = load("res://scenes/level/level_1.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	for frame in range(3):
		await process_frame
	var player = scene.get_node("Player")
	var controls = scene.get_node("UI/MobileControls")
	var bar = controls.charge_bar
	check(player.sonar_charges == 3 and bar.counter.text == "ЭХО  3/3", "A level starts with three visible charges")
	for cell in bar.charge_cells:
		check(cell.value == 1.0, "An available charge is shown as a full segment")
	for shot in range(3):
		player.stomp()
	check(player.sonar_charges == 0 and waves(scene) == 3, "Three immediate screams consume the entire reserve")
	check(bar.counter.text == "ЭХО  0/3" and not controls.sonar_available, "HUD and echo button immediately reflect an empty reserve")
	var pitch: float = player.screech_audio.pitch_scale
	player.stomp()
	check(waves(scene) == 3 and player.screech_audio.pitch_scale == pitch, "A fourth scream creates no wave or new scream pitch")
	touch(5, controls.sonar_center, true)
	touch(5, controls.sonar_center, false)
	check(waves(scene) == 3 and player.sonar_charges == 0, "The touch button cannot bypass an empty reserve")
	for frame in range(60):
		await physics_frame
	check(player.sonar_charges == 0 and absf(player.get_sonar_recharge_progress() - 0.5) < 0.025, "Recharging progresses gradually rather than restoring a charge instantly")
	check(absf(bar.charge_cells[0].value - 0.5) < 0.025 and bar.charge_cells[1].value == 0.0, "Only the next missing segment fills during recharge")
	controls._open_pause()
	var paused_progress: float = player.get_sonar_recharge_progress()
	player.stomp()
	for frame in range(120):
		await process_frame
	check(player.sonar_charges == 0 and player.get_sonar_recharge_progress() == paused_progress, "Pause stops recharge and blocks screaming")
	controls._resume()
	for frame in range(65):
		await physics_frame
	check(player.sonar_charges == 1 and controls.sonar_available, "One charge becomes usable after two active seconds")
	check(bar.charge_cells[0].value == 1.0 and bar.charge_cells[1].value < 0.1, "The HUD advances to filling the second charge")
	var progress_before: float = player.get_sonar_recharge_progress()
	player.stomp()
	check(player.sonar_charges == 0 and player.get_sonar_recharge_progress() == progress_before, "Using a restored charge preserves current recharge progress")
	for frame in range(400):
		await physics_frame
	check(player.sonar_charges == 3 and player.get_sonar_recharge_progress() == 0.0, "Charges restore one at a time up to the maximum of three")
	for cell in bar.charge_cells:
		check(cell.value == 1.0, "Every segment is full once recovery completes")
	for frame in range(150):
		await physics_frame
	for shot in range(3):
		player.stomp()
	for frame in range(30):
		await physics_frame
	check(player.sonar_charges == 0 and player.get_sonar_recharge_progress() < 0.3, "Idle time at full capacity does not bank extra charges")
	player.die()
	for frame in range(4):
		await process_frame
	check(not controls.visible, "The charge bar hides with controls during death")
	for frame in range(150):
		await process_frame
	var fresh_player = current_scene.get_node("Player")
	var fresh_controls = current_scene.get_node("UI/MobileControls")
	check(not paused and fresh_player.sonar_charges == 3 and fresh_controls.charge_bar.counter.text == "ЭХО  3/3", "Respawn resets the charge reserve and HUD")
	root.get_node("GameManager").load_level(2)
	for frame in range(5):
		await process_frame
	check(current_scene.get_node("Player").sonar_charges == 3, "A new level starts with its own full reserve")
	current_scene.queue_free()
	await process_frame
	if not failed:
		print("ALL SONAR CHARGE CHECKS PASSED")
	quit(1 if failed else 0)
