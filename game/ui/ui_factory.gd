class_name UIFactory
extends RefCounted

const INK := Color("#111016f2")
const INK_LIGHT := Color("#201d27f2")
const GOLD := Color("#d4b36f")
const GOLD_MUTED := Color("#78694d")
const TEXT := Color("#eee7da")
const TEXT_MUTED := Color("#aaa398")
const FOCUS := Color("#f2cb78")

static func panel_style(color := INK, border := GOLD_MUTED, border_width := 1) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(3)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 9
	style.content_margin_bottom = 9
	return style

static func button(text_key: StringName, minimum_width := 240.0) -> Button:
	var result := Button.new()
	result.text = Locale.text(text_key)
	result.custom_minimum_size = Vector2(minimum_width, 31)
	result.focus_mode = Control.FOCUS_ALL
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result.add_theme_font_size_override("font_size", 13)
	result.add_theme_color_override("font_color", TEXT)
	result.add_theme_color_override("font_focus_color", Color("#fff3d4"))
	result.add_theme_color_override("font_disabled_color", Color("#66616a"))
	result.add_theme_stylebox_override("normal", _button_box(Color("#25212aee"), Color("#4e4755"), 1))
	result.add_theme_stylebox_override("hover", _button_box(Color("#25212aee"), Color("#4e4755"), 1))
	result.add_theme_stylebox_override("pressed", _button_box(Color("#362f27"), GOLD, 1))
	result.add_theme_stylebox_override("focus", _button_box(Color("#2d282c"), FOCUS, 2))
	result.add_theme_stylebox_override("disabled", _button_box(Color("#18161caa"), Color("#353139"), 1))
	return result

static func label(text_key: StringName, size := 16) -> Label:
	var result := Label.new()
	result.text = Locale.text(text_key)
	result.add_theme_font_size_override("font_size", size)
	result.add_theme_color_override("font_color", TEXT)
	return result

static func keyboard_slider() -> HSlider:
	var slider := HSlider.new()
	slider.custom_minimum_size = Vector2(132, 20)
	slider.focus_mode = Control.FOCUS_ALL
	slider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slider.add_theme_icon_override("grabber", _slider_grabber(GOLD))
	slider.add_theme_icon_override("grabber_highlight", _slider_grabber(FOCUS))
	return slider

static func link_vertical(controls: Array[Control]) -> void:
	if controls.is_empty():
		return
	for index in controls.size():
		var control := controls[index]
		var previous := controls[maxi(index - 1, 0)]
		var following := controls[mini(index + 1, controls.size() - 1)]
		control.focus_neighbor_top = control.get_path_to(previous)
		control.focus_neighbor_bottom = control.get_path_to(following)
		control.focus_previous = control.get_path_to(previous)
		control.focus_next = control.get_path_to(following)
	controls[0].call_deferred("grab_focus")

static func _button_box(color: Color, border: Color, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(3)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style

static func _slider_grabber(color: Color) -> GradientTexture1D:
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([color, color])
	var texture := GradientTexture1D.new()
	texture.gradient = gradient
	texture.width = 7
	return texture
