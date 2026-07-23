class_name Wayfarer
extends Node2D

const SPEED := 105.0
const BOUNDS := Rect2(22, 76, 596, 252)

var input_enabled := true

func _ready() -> void:
	queue_redraw()

func _process(delta: float) -> void:
	if not input_enabled:
		return
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	position += direction * SPEED * delta
	position.x = clampf(position.x, BOUNDS.position.x, BOUNDS.end.x)
	position.y = clampf(position.y, BOUNDS.position.y, BOUNDS.end.y)

func _draw() -> void:
	draw_circle(Vector2(0, -10), 5, Color("#b98d68"))
	draw_polygon(PackedVector2Array([Vector2(-8, -5), Vector2(8, -5), Vector2(11, 13), Vector2(-11, 13)]), PackedColorArray([Color("#55717a")]))
	draw_line(Vector2(-7, 4), Vector2(-10, 14), Color("#2a2930"), 3)
	draw_line(Vector2(7, 4), Vector2(10, 14), Color("#2a2930"), 3)
	draw_circle(Vector2(0, 15), 8, Color("#00000055"))

