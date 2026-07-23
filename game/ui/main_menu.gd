class_name MainMenu
extends Control

signal new_game_requested
signal continue_requested
signal lab_requested

var continue_button: Button
var warning_label: Label

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	build()
	Locale.locale_changed.connect(func(_locale): rebuild())

func build() -> void:
	var backdrop := ColorRect.new()
	backdrop.color = Color("#191722")
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)

	var moon := ColorRect.new()
	moon.color = Color("#d4b978")
	moon.position = Vector2(455, 52)
	moon.size = Vector2(70, 70)
	backdrop.add_child(moon)

	var path := Polygon2D.new()
	path.polygon = PackedVector2Array([Vector2(270, 360), Vector2(370, 360), Vector2(342, 168), Vector2(303, 168)])
	path.color = Color("#5f513d")
	backdrop.add_child(path)

	var center := VBoxContainer.new()
	center.position = Vector2(190, 18)
	center.size = Vector2(260, 330)
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_theme_constant_override("separation", 5)
	add_child(center)

	var title := Label.new()
	title.text = Locale.text(&"UI_GAME_TITLE")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", Color("#f2dfb5"))
	center.add_child(title)

	var subtitle := Label.new()
	subtitle.text = Locale.text(&"UI_LOCATION_MARKET")
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_color_override("font_color", Color("#b8a783"))
	center.add_child(subtitle)

	var new_button := UIFactory.button(&"UI_NEW_GAME")
	new_button.pressed.connect(func(): new_game_requested.emit())
	center.add_child(new_button)

	continue_button = UIFactory.button(&"UI_CONTINUE")
	continue_button.disabled = not SaveManager.has_save()
	continue_button.pressed.connect(func(): continue_requested.emit())
	center.add_child(continue_button)

	var lab_button := UIFactory.button(&"UI_ENCOUNTER_LAB")
	lab_button.pressed.connect(func(): lab_requested.emit())
	center.add_child(lab_button)

	var language_row := HBoxContainer.new()
	language_row.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(language_row)
	var es_button := Button.new()
	es_button.text = "ES"
	es_button.pressed.connect(func(): Locale.set_locale("es"))
	language_row.add_child(es_button)
	var en_button := Button.new()
	en_button.text = "EN"
	en_button.pressed.connect(func(): Locale.set_locale("en"))
	language_row.add_child(en_button)

	center.add_child(volume_row(&"UI_MUSIC", "Music"))
	center.add_child(volume_row(&"UI_SFX", "SFX"))

	warning_label = Label.new()
	warning_label.visible = SaveManager.last_load_failed
	warning_label.text = Locale.text(&"UI_CORRUPT_SAVE")
	warning_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	warning_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	warning_label.add_theme_color_override("font_color", Color("#e8a08b"))
	center.add_child(warning_label)

func rebuild() -> void:
	for child in get_children():
		child.queue_free()
	await get_tree().process_frame
	build()

func volume_row(label_key: StringName, bus_name: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	var label := Label.new()
	label.text = Locale.text(label_key)
	label.custom_minimum_size.x = 72
	row.add_child(label)
	var slider := HSlider.new()
	slider.custom_minimum_size.x = 120
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	var bus_index := AudioServer.get_bus_index(bus_name)
	slider.value = db_to_linear(AudioServer.get_bus_volume_db(bus_index)) if bus_index >= 0 else 1.0
	slider.value_changed.connect(func(value: float):
		if bus_index >= 0:
			AudioServer.set_bus_volume_db(bus_index, linear_to_db(maxf(value, 0.001)))
	)
	row.add_child(slider)
	return row
