extends GutTest

const SHEET_PATH := "res://assets/generated/processed/wayfarer_sheet_v2.png"
const COLUMNS := 4
const ROWS := 4
const ALPHA_THRESHOLD := 0.05

func test_sheet_has_a_regular_four_by_four_grid() -> void:
	var image := Image.load_from_file(ProjectSettings.globalize_path(SHEET_PATH))
	assert_false(image.is_empty())
	assert_eq(image.get_width() % COLUMNS, 0)
	assert_eq(image.get_height() % ROWS, 0)

func test_every_frame_keeps_the_same_foot_anchor() -> void:
	var image := Image.load_from_file(ProjectSettings.globalize_path(SHEET_PATH))
	var cell_size := Vector2i(image.get_width() / COLUMNS, image.get_height() / ROWS)
	for row in ROWS:
		var expected_bottom := row * cell_size.y + cell_size.y - 11
		for column in COLUMNS:
			var bounds := alpha_bounds(image, Rect2i(column * cell_size.x, row * cell_size.y, cell_size.x, cell_size.y))
			assert_eq(bounds.end.y - 1, expected_bottom, "Frame %d,%d must keep its feet on the shared baseline" % [column, row])
			assert_almost_eq(float(bounds.get_center().x), column * cell_size.x + cell_size.x * 0.5, 1.0, "Frame %d,%d must stay horizontally centered" % [column, row])

func test_movement_uses_the_expected_direction_rows_and_returns_to_idle() -> void:
	var wayfarer := Wayfarer.new()
	wayfarer.input_enabled = false
	add_child_autofree(wayfarer)
	await get_tree().process_frame
	var directions := {
		&"move_down": 0,
		&"move_left": 1,
		&"move_right": 2,
		&"move_up": 3
	}
	for action in directions:
		Input.action_press(action)
		wayfarer.input_enabled = true
		wayfarer._process(0.17)
		wayfarer.input_enabled = false
		Input.action_release(action)
		assert_eq(wayfarer.sprite.frame_coords, Vector2i(1, directions[action]), "%s must use its directional row" % action)
		wayfarer.input_enabled = true
		wayfarer._process(0.01)
		wayfarer.input_enabled = false
		assert_eq(wayfarer.sprite.frame_coords, Vector2i(0, directions[action]), "%s must return to its directional idle frame" % action)

func alpha_bounds(image: Image, cell: Rect2i) -> Rect2i:
	var minimum := cell.end
	var maximum := cell.position - Vector2i.ONE
	for y in range(cell.position.y, cell.end.y):
		for x in range(cell.position.x, cell.end.x):
			if image.get_pixel(x, y).a <= ALPHA_THRESHOLD:
				continue
			minimum.x = mini(minimum.x, x)
			minimum.y = mini(minimum.y, y)
			maximum.x = maxi(maximum.x, x)
			maximum.y = maxi(maximum.y, y)
	return Rect2i(minimum, maximum - minimum + Vector2i.ONE)
