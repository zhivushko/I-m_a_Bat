extends AnimatableBody2D

enum State { HANGING, WARNING, FALLING, RESTING }

const SONAR_SHADER: Shader = preload("res://assets/shaders/echo_wave.gdshader")
const SEGMENTS: int = 16
const WARNING_DURATION: float = 0.95

@export_range(70.0, 230.0) var body_length: float = 130.0
@export_range(4.0, 65.0) var sway_amplitude: float = 16.0
@export_range(2.0, 36.0) var bob_amplitude: float = 8.0
@export var motion_phase: float = 0.0
@export var min_drop_delay: float = 24.0
@export var max_drop_delay: float = 44.0
@export_range(0.0, 700.0) var activation_distance: float = 0.0
@export var activation_region: Rect2 = Rect2()

@onready var body_fill: Polygon2D = $BodyFill
@onready var outline: Line2D = $Outline
@onready var left_eye: Line2D = $LeftEye
@onready var right_eye: Line2D = $RightEye
@onready var tongue: Line2D = $Tongue
@onready var tongue_fork: Line2D = $TongueFork
@onready var damage_area: Area2D = $DamageArea

var state: State = State.HANGING
var drop_timer: float = 0.0
var phase: float = 0.0
var state_time: float = 0.0
var fall_velocity: Vector2 = Vector2.ZERO
var shader_material: ShaderMaterial
var reveal_tween: Tween
var spine: PackedVector2Array
var body_segments: Array[CollisionShape2D] = []
var damage_segments: Array[CollisionShape2D] = []
var head_collision: CollisionShape2D
var head_damage: CollisionShape2D

func _ready() -> void:
	phase = motion_phase
	var minimum_delay := maxf(0.1, min_drop_delay)
	drop_timer = randf_range(minimum_delay, maxf(minimum_delay, max_drop_delay))
	shader_material = ShaderMaterial.new()
	shader_material.shader = SONAR_SHADER
	for line: Line2D in [outline, left_eye, right_eye, tongue, tongue_fork]:
		line.material = shader_material
	var fill_material := CanvasItemMaterial.new()
	fill_material.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	body_fill.material = fill_material
	for index in range(SEGMENTS):
		body_segments.append(_add_capsule(self, 4.2))
		damage_segments.append(_add_capsule(damage_area, 6.2))
	head_collision = _add_circle(self, 7.0)
	head_damage = _add_circle(damage_area, 9.0)
	damage_area.body_entered.connect(_on_body_entered)
	_update_shape()

func _add_capsule(parent: Node, radius: float) -> CollisionShape2D:
	var collision := CollisionShape2D.new()
	var capsule := CapsuleShape2D.new()
	capsule.radius = radius
	capsule.height = radius * 2.0
	collision.shape = capsule
	parent.add_child(collision)
	return collision

func _add_circle(parent: Node, radius: float) -> CollisionShape2D:
	var collision := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = radius
	collision.shape = circle
	parent.add_child(collision)
	return collision

func _physics_process(delta: float) -> void:
	phase += delta
	state_time += delta
	match state:
		State.HANGING:
			if _player_in_drop_zone():
				drop_timer -= delta
			if drop_timer <= 0.0:
				state = State.WARNING
				state_time = 0.0
		State.WARNING:
			if state_time >= WARNING_DURATION:
				state = State.FALLING
				state_time = 0.0
				fall_velocity = Vector2(sin(motion_phase + phase) * 22.0, 25.0)
		State.FALLING:
			fall_velocity.y = minf(fall_velocity.y + 760.0 * delta, 600.0)
			var collision := move_and_collide(fall_velocity * delta)
			if collision:
				_on_body_entered(collision.get_collider())
				if collision.get_normal().y < -0.4:
					state = State.RESTING
					state_time = 0.0
					fall_velocity = Vector2.ZERO
				else:
					fall_velocity = fall_velocity.slide(collision.get_normal())
	_update_shape()

func _player_in_drop_zone() -> bool:
	if activation_distance <= 0.0:
		return true
	var scene := get_tree().current_scene
	if not scene:
		return false
	var player := scene.get_node_or_null("Player") as Node2D
	if not player or global_position.distance_to(player.global_position) > activation_distance:
		return false
	return not activation_region.has_area() or activation_region.has_point(player.global_position)

func _update_shape() -> void:
	spine = PackedVector2Array()
	var warning := state == State.WARNING
	var sway := sway_amplitude * (1.45 if warning else 1.0)
	var length_now := body_length + sin(phase * 0.85 + motion_phase) * bob_amplitude
	if warning:
		length_now -= sin(clampf(state_time / WARNING_DURATION, 0.0, 1.0) * PI) * 18.0
	for index in range(SEGMENTS + 1):
		var t := float(index) / SEGMENTS
		var x := (sin(phase * 1.05 - t * 4.4) * sway + sin(phase * 1.6 + t * 7.0) * 3.0) * t
		var point := Vector2(x, t * length_now)
		if state == State.RESTING:
			var coil := Vector2((t - 0.5) * 50.0,
				body_length - 16.0 - sin(t * TAU + phase * 0.12) * 5.0 - sin(t * PI) * 9.0)
			point = point.lerp(coil, smoothstep(0.0, 0.45, state_time))
		spine.append(point)
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	for index in range(spine.size()):
		var direction := (spine[mini(index + 1, SEGMENTS)] - spine[maxi(index - 1, 0)]).normalized()
		var normal := Vector2(-direction.y, direction.x)
		var t := float(index) / SEGMENTS
		var width := lerpf(1.2, 4.2, smoothstep(0.0, 0.3, t))
		width = lerpf(width, 7.0, smoothstep(0.87, 1.0, t))
		left.append(spine[index] + normal * width)
		right.append(spine[index] - normal * width)
	var head := spine[SEGMENTS]
	var head_direction := (head - spine[SEGMENTS - 1]).normalized()
	var head_normal := Vector2(-head_direction.y, head_direction.x)
	var polygon := left.duplicate()
	polygon.append(head + head_direction * 7.0)
	right.reverse()
	polygon.append_array(right)
	body_fill.polygon = polygon
	polygon.append(polygon[0])
	outline.points = polygon
	_set_eye(left_eye, head + head_normal * 3.4 + head_direction * 1.0, head_direction)
	_set_eye(right_eye, head - head_normal * 3.4 + head_direction * 1.0, head_direction)
	tongue.visible = warning or (state != State.FALLING and sin(phase * 1.7) > 0.94)
	tongue_fork.visible = tongue.visible
	var mouth := head + head_direction * 7.0
	var fork := mouth + head_direction * 7.0
	tongue.points = PackedVector2Array([mouth, fork, fork + head_direction * 3.0 + head_normal * 3.0])
	tongue_fork.points = PackedVector2Array([fork, fork + head_direction * 3.0 - head_normal * 3.0])
	for index in range(SEGMENTS):
		_update_capsule(body_segments[index], spine[index], spine[index + 1])
		_update_capsule(damage_segments[index], spine[index], spine[index + 1])
	head_collision.position = head
	head_damage.position = head

func _set_eye(eye: Line2D, point: Vector2, direction: Vector2) -> void:
	eye.points = PackedVector2Array([point, point + direction * 1.3])

func _update_capsule(collision: CollisionShape2D, start: Vector2, end: Vector2) -> void:
	var capsule: CapsuleShape2D = collision.shape
	capsule.height = start.distance_to(end) + capsule.radius * 2.0
	collision.position = (start + end) * 0.5
	collision.rotation = (end - start).angle() - PI * 0.5

func reveal(duration: float = 3.0) -> void:
	if reveal_tween and reveal_tween.is_running():
		reveal_tween.kill()
	_set_reveal_alpha(1.0)
	reveal_tween = create_tween()
	reveal_tween.tween_method(_set_reveal_alpha, 1.0, 0.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _set_reveal_alpha(value: float) -> void:
	shader_material.set_shader_parameter("reveal_alpha", value)

func update_sonar_waves(centers: Array, radii: Array, max_radii: Array, alphas: Array) -> void:
	shader_material.set_shader_parameter("wave_centers", centers)
	shader_material.set_shader_parameter("wave_radii", radii)
	shader_material.set_shader_parameter("max_radii", max_radii)
	shader_material.set_shader_parameter("global_alphas", alphas)
	shader_material.set_shader_parameter("active_waves_count", centers.size())

func _on_body_entered(body: Node) -> void:
	if body == get_tree().current_scene.get_node_or_null("Player"):
		body.die()
