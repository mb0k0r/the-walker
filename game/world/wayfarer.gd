class_name Wayfarer
extends Node2D

const SPEED := 105.0
const BOUNDS := Rect2(22, 76, 596, 252)
const SPRITE_SHEET := preload("res://assets/generated/processed/wayfarer_sheet_v1.png")

var input_enabled := true
var sprite: Sprite2D
var walk_time := 0.0

func _ready() -> void:
	sprite = Sprite2D.new()
	sprite.texture = SPRITE_SHEET
	sprite.hframes = 4
	sprite.vframes = 4
	sprite.scale = Vector2(0.16, 0.16)
	sprite.position = Vector2(0, -10)
	add_child(sprite)
	queue_redraw()

func _process(delta: float) -> void:
	if not input_enabled:
		return
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if direction.is_zero_approx():
		sprite.frame_coords.x = 0
	else:
		walk_time += delta
		sprite.frame_coords.x = int(walk_time * 7.0) % 4
		if absf(direction.x) > absf(direction.y):
			sprite.frame_coords.y = 1 if direction.x < 0.0 else 2
		else:
			sprite.frame_coords.y = 3 if direction.y < 0.0 else 0
	position += direction * SPEED * delta
	position.x = clampf(position.x, BOUNDS.position.x, BOUNDS.end.x)
	position.y = clampf(position.y, BOUNDS.position.y, BOUNDS.end.y)

func _draw() -> void:
	draw_ellipse_shadow(Vector2(0, 12), Vector2(9, 4), Color("#00000066"))

func draw_ellipse_shadow(center: Vector2, radius: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for index in range(16):
		var angle := TAU * float(index) / 16.0
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	draw_colored_polygon(points, color)
