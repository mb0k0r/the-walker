class_name MainMenu
extends Control

signal new_game_requested
signal continue_requested
signal lab_requested

const MARKET_BACKGROUND := preload("res://assets/generated/processed/market_background_v2.png")

var continue_button: Button
var warning_label: Label
var focus_controls: Array[Control] = []

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	build()
	Locale.locale_changed.connect(func(_locale): rebuild())

func build() -> void:
	focus_controls.clear()
	var backdrop := TextureRect.new()
	backdrop.texture = MARKET_BACKGROUND
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backdrop.modulate = Color("#77727c")
	add_child(backdrop)

	var shade := ColorRect.new()
	shade.color = Color("#090a10a8")
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)

	var panel := PanelContainer.new()
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -172.0
	panel.offset_top = -166.0
	panel.offset_right = 172.0
	panel.offset_bottom = 166.0
	panel.add_theme_stylebox_override("panel", UIFactory.panel_style(Color("#15131af5"), Color("#82724f"), 1))
	add_child(panel)

	var center := VBoxContainer.new()
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_theme_constant_override("separation", 4)
	panel.add_child(center)

	var title := Label.new()
	title.text = Locale.text(&"UI_GAME_TITLE")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 29)
	title.add_theme_color_override("font_color", Color("#f2dfb5"))
	center.add_child(title)

	var subtitle := Label.new()
	subtitle.text = Locale.text(&"UI_LOCATION_MARKET")
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 11)
	subtitle.add_theme_color_override("font_color", Color("#b8a783"))
	center.add_child(subtitle)

	var separator := HSeparator.new()
	separator.add_theme_constant_override("separation", 4)
	separator.modulate = Color("#82724f")
	center.add_child(separator)

	var new_button := UIFactory.button(&"UI_NEW_GAME", 292)
	new_button.pressed.connect(func(): new_game_requested.emit())
	center.add_child(new_button)
	focus_controls.append(new_button)

	continue_button = UIFactory.button(&"UI_CONTINUE", 292)
	continue_button.disabled = not SaveManager.has_save()
	continue_button.pressed.connect(func(): continue_requested.emit())
	center.add_child(continue_button)
	focus_controls.append(continue_button)

	var lab_button := UIFactory.button(&"UI_ENCOUNTER_LAB", 292)
	lab_button.pressed.connect(func(): lab_requested.emit())
	center.add_child(lab_button)
	focus_controls.append(lab_button)

	var language_button := UIFactory.button(&"UI_LANGUAGE", 292)
	language_button.text = "%s: %s" % [
		Locale.text(&"UI_LANGUAGE"),
		"Español" if TranslationServer.get_locale().begins_with("es") else "English"
	]
	language_button.pressed.connect(func():
		Locale.set_locale("en" if TranslationServer.get_locale().begins_with("es") else "es")
	)
	center.add_child(language_button)
	focus_controls.append(language_button)

	center.add_child(volume_row(&"UI_MUSIC", "Music"))
	center.add_child(volume_row(&"UI_SFX", "SFX"))

	warning_label = Label.new()
	warning_label.visible = SaveManager.last_load_failed
	warning_label.text = Locale.text(&"UI_CORRUPT_SAVE")
	warning_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	warning_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	warning_label.add_theme_color_override("font_color", Color("#e8a08b"))
	center.add_child(warning_label)

	var hint := UIFactory.label(&"UI_MENU_KEYBOARD_HINT", 9)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_color_override("font_color", UIFactory.TEXT_MUTED)
	center.add_child(hint)

	UIFactory.link_vertical(focus_controls)

func rebuild() -> void:
	for child in get_children():
		child.queue_free()
	await get_tree().process_frame
	build()

func volume_row(label_key: StringName, bus_name: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 7)
	var label := Label.new()
	label.text = Locale.text(label_key)
	label.custom_minimum_size.x = 58
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", UIFactory.TEXT_MUTED)
	row.add_child(label)
	var slider := UIFactory.keyboard_slider()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	var bus_index := AudioServer.get_bus_index(bus_name)
	slider.value = db_to_linear(AudioServer.get_bus_volume_db(bus_index)) if bus_index >= 0 else 1.0
	var value_label := Label.new()
	value_label.custom_minimum_size.x = 34
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.add_theme_font_size_override("font_size", 10)
	value_label.add_theme_color_override("font_color", UIFactory.GOLD)
	value_label.text = "%d%%" % roundi(slider.value * 100.0)
	slider.value_changed.connect(func(value: float):
		if bus_index >= 0:
			AudioServer.set_bus_volume_db(bus_index, linear_to_db(maxf(value, 0.001)))
		value_label.text = "%d%%" % roundi(value * 100.0)
	)
	row.add_child(slider)
	row.add_child(value_label)
	focus_controls.append(slider)
	return row

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("move_up"):
		_move_focus(-1)
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("move_down"):
		_move_focus(1)
		get_viewport().set_input_as_handled()
		return

	var focused := get_viewport().gui_get_focus_owner()
	if focused is HSlider:
		if event.is_action_pressed("move_left"):
			focused.value -= focused.step
			get_viewport().set_input_as_handled()
			return
		if event.is_action_pressed("move_right"):
			focused.value += focused.step
			get_viewport().set_input_as_handled()
			return

	if not event.is_action_pressed("interact"):
		return
	if focused is Button and not focused.disabled:
		focused.pressed.emit()
		get_viewport().set_input_as_handled()


func _move_focus(direction: int) -> void:
	if focus_controls.is_empty():
		return
	var focused := get_viewport().gui_get_focus_owner()
	var index := focus_controls.find(focused)
	if index < 0:
		index = -1 if direction > 0 else 0
	for attempt in focus_controls.size():
		index = posmod(index + direction, focus_controls.size())
		var target := focus_controls[index]
		if not target.visible or target.focus_mode == Control.FOCUS_NONE:
			continue
		if target is BaseButton and target.disabled:
			continue
		target.grab_focus()
		return
