@tool
class_name Wall
extends StaticBody2D

@export var polygon_points: PackedVector2Array = PackedVector2Array([
	Vector2(-50, -50), Vector2(50, -50), Vector2(50, 50), Vector2(-50, 50)
]):
	set(value):
		polygon_points = value
		if is_node_ready():
			setup_wall()

@onready var collision_poly: CollisionPolygon2D = $CollisionPolygon2D
@onready var polygon_2d: Polygon2D = $Polygon2D
@onready var line_2d: Line2D = $Line2D
@onready var light_occluder: LightOccluder2D = $LightOccluder2D

var reveal_tween: Tween
var shader_material: ShaderMaterial

func _ready() -> void:
	setup_wall()

func setup_wall() -> void:
	if polygon_points.size() < 3:
		return

	if collision_poly:
		collision_poly.polygon = polygon_points

	if polygon_2d:
		polygon_2d.polygon = polygon_points
		polygon_2d.color = Color.BLACK
		var mat = CanvasItemMaterial.new()
		mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
		polygon_2d.material = mat

	if light_occluder:
		var occ_poly = OccluderPolygon2D.new()
		occ_poly.polygon = polygon_points
		light_occluder.occluder = occ_poly

	if line_2d:
		var closed_points = polygon_points.duplicate()
		closed_points.append(polygon_points[0])
		line_2d.points = closed_points
		line_2d.width = 3.0
		line_2d.default_color = Color.WHITE

		var sonar_shader = load("res://assets/shaders/sonar.gdshader")
		if sonar_shader:
			shader_material = ShaderMaterial.new()
			shader_material.shader = sonar_shader
			line_2d.material = shader_material

func reveal(duration: float = 2.0) -> void:
	if reveal_tween and reveal_tween.is_running():
		reveal_tween.kill()

	if shader_material:
		shader_material.set_shader_parameter("reveal_alpha", 1.0)
		reveal_tween = create_tween()
		reveal_tween.tween_method(
			func(val: float): shader_material.set_shader_parameter("reveal_alpha", val),
			1.0, 0.0, duration
		).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	elif line_2d:
		line_2d.modulate.a = 1.0
		reveal_tween = create_tween()
		reveal_tween.tween_property(line_2d, "modulate:a", 0.0, duration)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func update_sonar_waves(centers: Array, radii: Array, thicknesses: Array, intensities: Array) -> void:
	if shader_material:
		shader_material.set_shader_parameter("wave_centers", centers)
		shader_material.set_shader_parameter("wave_radii", radii)
		shader_material.set_shader_parameter("wave_thicknesses", thicknesses)
		shader_material.set_shader_parameter("wave_intensities", intensities)
		shader_material.set_shader_parameter("active_waves_count", centers.size())
