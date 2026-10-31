extends Node2D

@export var duration: float = 1.4
@export var max_radius: float = 18.0

var collision_normal: Vector2 = Vector2.UP
var current_radius: float = 2.0
var current_alpha: float = 1.0

func setup(normal: Vector2) -> void:
	collision_normal = normal
	# Угол нормали указывает от стены обратно к источнику звука
	rotation = normal.angle()

func _ready() -> void:
	var mat = CanvasItemMaterial.new()
	mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	material = mat

	queue_redraw()

	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "current_radius", max_radius, duration)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "current_alpha", 0.0, duration)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	tween.chain().tween_callback(queue_free)

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if current_alpha <= 0.0:
		return

	var color = Color(1.0, 1.0, 1.0, current_alpha)
	# Дуга отражения расходится обратно в сторону игрока / источника шума
	draw_arc(Vector2.ZERO, current_radius, -PI * 0.45, PI * 0.45, 16, color, 2.0)

	if current_radius > 4.0:
		var inner_color = Color(1.0, 1.0, 1.0, current_alpha * 0.5)
		draw_arc(Vector2.ZERO, current_radius * 0.5, -PI * 0.35, PI * 0.35, 12, inner_color, 1.5)
