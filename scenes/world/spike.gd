@tool
extends "res://scenes/world/wall.gd"

const REVEAL_DURATION_SCALE: float = 1.04

@onready var damage_area: Area2D = $DamageArea
@onready var damage_polygon: CollisionPolygon2D = $DamageArea/CollisionPolygon2D

var restarting: bool = false

func _ready() -> void:
	super._ready()
	if not Engine.is_editor_hint():
		damage_area.body_entered.connect(_on_body_entered)

func setup_wall() -> void:
	super.setup_wall()
	# Use the walls' lighting and shader so both contours fade together.
	# Small teeth should not cast a shadow over their own outline.
	if light_occluder:
		light_occluder.visible = false
	if line_2d:
		line_2d.width = 1.4
		line_2d.joint_mode = Line2D.LINE_JOINT_SHARP
	if damage_polygon and polygon_points.size() >= 3:
		# Detect contact just before the solid surface stops the player.
		var expanded := Geometry2D.offset_polygon(polygon_points, 4.0)
		if not expanded.is_empty():
			damage_polygon.polygon = expanded[0]

func reveal(duration: float = 3.0) -> void:
	super.reveal(duration * REVEAL_DURATION_SCALE)

func _on_body_entered(body: Node2D) -> void:
	if restarting or body != get_tree().current_scene.get_node_or_null("Player"):
		return
	restarting = true
	body.die()
