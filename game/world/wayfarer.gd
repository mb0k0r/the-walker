class_name Wayfarer
extends Node2D

const SPEED := 96.0
const BOUNDS := Rect2(22, 76, 596, 252)
const COLLISION_HALF_SIZE := Vector2(7, 5)
const FRAME_STEP_DISTANCE := 12.0
const SPRITE_SHEET := preload("res://assets/generated/processed/wayfarer_sheet_v2.png")

var input_enabled := true
var sprite: Sprite2D
var walk_distance := 0.0
var last_direction := Vector2.DOWN
var collision_rects: Array[Rect2] = []

func _ready() -> void:
	sprite = Sprite2D.new()
	sprite.texture = SPRITE_SHEET
	sprite.hframes = 4
	sprite.vframes = 4
	sprite.scale = Vector2(0.21, 0.21)
	sprite.position = Vector2(0, -21)
	add_child(sprite)
	queue_redraw()

func _process(delta: float) -> void:
	if not input_enabled:
		return
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if direction.is_zero_approx():
		set_idle_frame()
		return

	last_direction = direction
	update_direction_row(direction)
	var movement := move_with_collisions(direction * SPEED * delta)
	if movement.is_zero_approx():
		set_idle_frame()
		return
	walk_distance += movement.length()
	sprite.frame_coords.x = int(walk_distance / FRAME_STEP_DISTANCE) % sprite.hframes

func set_collision_rects(value: Array[Rect2]) -> void:
	collision_rects = value.duplicate()

func move_with_collisions(motion: Vector2) -> Vector2:
	var origin := position
	var horizontal := Vector2(clampf(position.x + motion.x, BOUNDS.position.x, BOUNDS.end.x), position.y)
	if not collides_at(horizontal):
		position.x = horizontal.x
	var vertical := Vector2(position.x, clampf(position.y + motion.y, BOUNDS.position.y, BOUNDS.end.y))
	if not collides_at(vertical):
		position.y = vertical.y
	return position - origin

func collides_at(candidate: Vector2) -> bool:
	var feet := Rect2(candidate - COLLISION_HALF_SIZE, COLLISION_HALF_SIZE * 2.0)
	for obstacle in collision_rects:
		if feet.intersects(obstacle):
			return true
	return false

func update_direction_row(direction: Vector2) -> void:
	if absf(direction.x) > absf(direction.y):
		sprite.frame_coords.y = 1 if direction.x < 0.0 else 2
	else:
		sprite.frame_coords.y = 3 if direction.y < 0.0 else 0

func set_idle_frame() -> void:
	walk_distance = 0.0
	sprite.frame_coords.x = 0

func _draw() -> void:
	draw_ellipse_shadow(Vector2(0, 10), Vector2(12, 4.5), Color("#05040799"))
	draw_ellipse_shadow(Vector2(0, 9), Vector2(8, 2.5), Color("#a67a3c24"))

func draw_ellipse_shadow(center: Vector2, radius: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for index in range(16):
		var angle := TAU * float(index) / 16.0
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	draw_colored_polygon(points, color)
