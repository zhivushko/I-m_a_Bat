# Run: Godot --headless --path . --fixed-fps 60 --audio-driver Dummy --script res://tests/test_level_3.gd
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

func travel(player: CharacterBody2D, target: Vector2) -> bool:
	var frame_limit := ceili(player.global_position.distance_to(target) / 220.0 * 60.0) + 180
	for frame in range(frame_limit):
		await physics_frame
		if not is_instance_valid(player) or player.get("is_dead"):
			return false
		var distance := target - player.global_position
		if distance.length() < 4.0:
			player.velocity = Vector2.ZERO
			return true
		player.velocity = distance.normalized() * minf(220.0, distance.length() * 60.0)
		player.move_and_slide()
	return false

func run() -> void:
	var scene = load("res://scenes/level/level_3.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await process_frame
	var player: CharacterBody2D = scene.get_node("Player")
	player.set_physics_process(false)
	player.set_process_unhandled_input(false)
	scene.get_node("LevelExit").monitoring = false
	var snakes := get_nodes_in_group("hanging_snakes")
	var tunnel_snakes := get_nodes_in_group("tunnel_snakes")
	check(snakes.size() == 11 and tunnel_snakes.size() == 7, "The original four snakes are followed by seven tunnel snakes")
	var spikes: Array = scene.get_node("Walls").get_children().filter(func(node): return node.has_node("DamageArea") and not node.is_in_group("hanging_snakes"))
	check(not spikes.is_empty(), "Level 3 reuses the cave spike scene in a separate layout")
	for snake in snakes:
		if not snake.is_in_group("tunnel_snakes"):
			check(snake.drop_timer >= 18.0 and snake.sway_amplitude <= 20.0, "The original cave retains its rare falls and gentle motion")
		snake.drop_timer = 1000.0
	var snake = scene.get_node("Walls/MiddleHangingSnake")
	var anchor: Vector2 = snake.position
	var initial_head: Vector2 = snake.spine[16]
	var head_min := initial_head
	var head_max := initial_head
	var strong_snake = scene.get_node("Walls/TunnelUpperSnakeC")
	var strong_min: Vector2 = strong_snake.spine[16]
	var strong_max := strong_min
	for frame in range(240):
		await physics_frame
		var head_position: Vector2 = snake.spine[16]
		head_min = head_min.min(head_position)
		head_max = head_max.max(head_position)
		strong_min = strong_min.min(strong_snake.spine[16])
		strong_max = strong_max.max(strong_snake.spine[16])
	check(head_max.x - head_min.x > 4.0 and head_max.y - head_min.y > 4.0, "Hanging snakes sway sideways and bob vertically")
	check(strong_max.x - strong_min.x > 70.0 and strong_max.y - strong_min.y > 16.0, "Harder tunnel snakes have a visibly wider horizontal and vertical sweep")
	check(snake.position == anchor and snake.spine[0].length() < 0.01, "The hanging tail remains attached to the ceiling")
	check(snake.body_fill.color == Color.BLACK and snake.outline.default_color == Color.WHITE, "Snake visuals use white outlines without a bright fill")
	check(not Geometry2D.triangulate_polygon(snake.body_fill.polygon).is_empty(), "The animated snake outline remains a valid polygon")
	for target in [Vector2(250, 840), Vector2(1020, 840), Vector2(1020, 550), Vector2(580, 550), Vector2(580, 240), Vector2(1390, 240), Vector2(1390, 210), Vector2(1580, 210), Vector2(1780, 275), Vector2(3300, 275), Vector2(3300, 620), Vector2(1900, 620), Vector2(1900, 935), Vector2(3300, 935), Vector2(3320, 900)]:
		var reached := await travel(player, target)
		check(reached, "Safe route reaches " + str(target))
		if not reached:
			quit(1)
			return
	check(player.position.distance_to(scene.get_node("LevelExit").position) < 4.0, "The new cave route reaches the final exit")
	player.position = Vector2(750, 540)
	player.spawn_sound_wave(8.5, 3.5, 64, 1.5)
	for frame in range(45):
		await physics_frame
	check(snake.shader_material.get_shader_parameter("active_waves_count") > 0, "Snakes receive the same echolocation waves as walls")
	check(snake.shader_material.get_shader_parameter("reveal_alpha") != null, "Sonar physics reveals a hanging snake")
	for frame in range(240):
		await physics_frame
	check(snake.shader_material.get_shader_parameter("active_waves_count") == 0 and snake.shader_material.get_shader_parameter("reveal_alpha") < 0.01, "Snakes fade back into darkness after echolocation")
	var falling_snake = scene.get_node("Walls/DeepHangingSnake")
	var hanging_position: Vector2 = falling_snake.position
	falling_snake.drop_timer = 0.0
	for frame in range(3):
		await physics_frame
	check(falling_snake.state == falling_snake.State.WARNING, "A warning precedes a fall")
	for frame in range(25):
		await physics_frame
	check(falling_snake.state == falling_snake.State.WARNING and falling_snake.position == hanging_position, "The warning gives time to react before detachment")
	for frame in range(45):
		await physics_frame
	check(falling_snake.state == falling_snake.State.FALLING and falling_snake.position.y > hanging_position.y, "The snake detaches and falls under gravity")
	for frame in range(180):
		await physics_frame
	check(falling_snake.state == falling_snake.State.RESTING, "A fallen snake lands and remains on the cave floor")
	check(not Geometry2D.triangulate_polygon(falling_snake.body_fill.polygon).is_empty(), "The resting snake retains a valid outline")
	var landed_position: Vector2 = falling_snake.position
	for frame in range(120):
		await physics_frame
	check(falling_snake.position == landed_position, "A fallen snake does not repeat its drop")
	player.position = falling_snake.to_global(falling_snake.spine[16])
	for frame in range(4):
		await process_frame
	check(player.get("is_dead") and paused, "Physical contact with a snake triggers the existing death effect")
	for frame in range(150):
		await process_frame
	check(not paused and current_scene.get_node("Player").position == Vector2(160, 800), "Snake death restarts level 3 at its own spawn")
	var respawned_player = current_scene.get_node("Player")
	respawned_player.set_physics_process(false)
	for frame in range(4320):
		await physics_frame
	for natural_snake in get_nodes_in_group("hanging_snakes"):
		if natural_snake.is_in_group("tunnel_snakes"):
			check(natural_snake.state == natural_snake.State.HANGING, "Distant tunnel snakes remain hanging until the player arrives")
		else:
			check(natural_snake.state == natural_snake.State.RESTING, "A naturally scheduled rare fall lands safely")
	var first_tunnel_snake = current_scene.get_node("Walls/TunnelUpperSnakeA")
	var waiting_timer: float = first_tunnel_snake.drop_timer
	respawned_player.position = Vector2(2040, 470)
	for frame in range(60):
		await physics_frame
	check(first_tunnel_snake.drop_timer == waiting_timer, "A nearby player in a different tunnel does not trigger a fall through the wall")
	respawned_player.position = Vector2(1780, 275)
	for frame in range(65):
		await physics_frame
	check(first_tunnel_snake.state == first_tunnel_snake.State.WARNING, "Approaching the tunnel produces a visible warning within about one second")
	for frame in range(60):
		await physics_frame
	check(first_tunnel_snake.state == first_tunnel_snake.State.FALLING or first_tunnel_snake.state == first_tunnel_snake.State.RESTING, "The first tunnel snake falls within about two seconds of approach")
	for frame in range(90):
		await physics_frame
	check(first_tunnel_snake.state == first_tunnel_snake.State.RESTING, "The triggered tunnel fall lands safely")
	respawned_player.position = Vector2(2740, 935)
	for frame in range(220):
		await physics_frame
	check(current_scene.get_node("Walls/TunnelLowerSnakeA").state == first_tunnel_snake.State.RESTING and current_scene.get_node("Walls/TunnelLowerSnakeB").state == first_tunnel_snake.State.RESTING, "The final tunnel also produces frequent visible falls")
	respawned_player.position = current_scene.get_node("LevelExit").position
	for frame in range(60):
		await process_frame
	var screen: Node = null
	for child in root.get_children():
		if child.has_method("setup_screen"):
			screen = child
	check(paused and screen != null, "The final completion screen opens")
	if screen:
		check(screen.current_level_index == 3 and screen.title_label.text.contains("Игра пройдена"), "Level 3 still completes the game")
		screen._on_next_level_button_pressed()
		for frame in range(4):
			await process_frame
		check(not paused and current_scene.scene_file_path.ends_with("MainMenu.tscn"), "Finishing the game returns to the main menu")
	paused = false
	current_scene.queue_free()
	await process_frame
	if not failed:
		print("ALL LEVEL 3 CHECKS PASSED")
	quit(1 if failed else 0)
