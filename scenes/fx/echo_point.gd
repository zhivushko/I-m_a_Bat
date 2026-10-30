extends Node2D

@export var duration: float = 1.8
@export var max_radius: float = 14.0

var collision_normal: Vector2 = Vector2.UP
var current_radius: float = 2.0
var current_alpha: float = 1.0

func setup(normal: Vector2) -> void:
	collision_normal = normal
	rotation = normal.angle() + PI / 2.0

func _ready() -> void:
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
	draw_arc(Vector2.ZERO, current_radius, -PI * 0.4, PI * 0.4, 16, color, 2.0)
	draw_line(Vector2.ZERO, Vector2.UP * (current_radius * 0.6), color, 1.5)
