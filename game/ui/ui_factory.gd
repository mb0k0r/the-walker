class_name UIFactory
extends RefCounted

static func panel_style(color := Color("#17151be8"), border := Color("#c7a76a")) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style

static func button(text_key: StringName) -> Button:
	var result := Button.new()
	result.text = Locale.text(text_key)
	result.custom_minimum_size = Vector2(240, 34)
	result.focus_mode = Control.FOCUS_ALL
	return result

static func label(text_key: StringName, size := 16) -> Label:
	var result := Label.new()
	result.text = Locale.text(text_key)
	result.add_theme_font_size_override("font_size", size)
	return result

