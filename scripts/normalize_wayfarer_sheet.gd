extends SceneTree

const SOURCE_PATH := "res://assets/generated/processed/wayfarer_sheet_v1.png"
const OUTPUT_PATH := "res://assets/generated/processed/wayfarer_sheet_v2.png"
const COLUMNS := 4
const ROWS := 4
const CELL_SIZE := Vector2i(192, 320)
const FOOT_MARGIN := 10
const ALPHA_THRESHOLD := 0.05
const MAX_EMPTY_GAP := 16

func _init() -> void:
	var source := Image.load_from_file(ProjectSettings.globalize_path(SOURCE_PATH))
	if source.is_empty():
		push_error("Unable to load %s" % SOURCE_PATH)
		quit(1)
		return
	var output := Image.create_empty(CELL_SIZE.x * COLUMNS, CELL_SIZE.y * ROWS, false, Image.FORMAT_RGBA8)
	output.fill(Color(0, 0, 0, 0))
	for row in ROWS:
		for column in COLUMNS:
			var source_cell := source_cell_rect(source.get_size(), column, row)
			var content := find_content_rect(source, source_cell)
			if content.size.x <= 0 or content.size.y <= 0:
				push_error("No content in frame %d,%d" % [column, row])
				quit(1)
				return
			var destination := Vector2i(
				column * CELL_SIZE.x + (CELL_SIZE.x - content.size.x) / 2,
				row * CELL_SIZE.y + CELL_SIZE.y - FOOT_MARGIN - content.size.y
			)
			output.blit_rect(source, content, destination)
	var error := output.save_png(ProjectSettings.globalize_path(OUTPUT_PATH))
	if error != OK:
		push_error("Unable to save %s: %s" % [OUTPUT_PATH, error_string(error)])
		quit(1)
		return
	print("Normalized Wayfarer sheet saved to %s" % OUTPUT_PATH)
	quit()

func source_cell_rect(image_size: Vector2i, column: int, row: int) -> Rect2i:
	var left := floori(float(image_size.x) * column / COLUMNS)
	var right := floori(float(image_size.x) * (column + 1) / COLUMNS)
	var top := floori(float(image_size.y) * row / ROWS)
	var bottom := floori(float(image_size.y) * (row + 1) / ROWS)
	return Rect2i(left, top, right - left, bottom - top)

func find_content_rect(image: Image, cell: Rect2i) -> Rect2i:
	var column_weights: Array[int] = []
	var row_weights: Array[int] = []
	column_weights.resize(cell.size.x)
	row_weights.resize(cell.size.y)
	column_weights.fill(0)
	row_weights.fill(0)
	for local_y in cell.size.y:
		for local_x in cell.size.x:
			if image.get_pixel(cell.position.x + local_x, cell.position.y + local_y).a <= ALPHA_THRESHOLD:
				continue
			column_weights[local_x] += 1
			row_weights[local_y] += 1
	var x_range := strongest_range(column_weights)
	var y_range := strongest_range(row_weights)
	return Rect2i(
		cell.position + Vector2i(x_range.x, y_range.x),
		Vector2i(x_range.y - x_range.x + 1, y_range.y - y_range.x + 1)
	)

func strongest_range(weights: Array[int]) -> Vector2i:
	var best := Vector2i(0, -1)
	var best_score := -1
	var start := -1
	var last_content := -1
	var score := 0
	for index in weights.size():
		if weights[index] > 0:
			if start < 0:
				start = index
			last_content = index
			score += weights[index]
		elif start >= 0 and index - last_content > MAX_EMPTY_GAP:
			if score > best_score:
				best = Vector2i(start, last_content)
				best_score = score
			start = -1
			last_content = -1
			score = 0
	if start >= 0 and score > best_score:
		best = Vector2i(start, last_content)
	return best
