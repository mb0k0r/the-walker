class_name LibraryPanel
extends Control

var scroll: ScrollContainer

func show_journal() -> void:
	_build(&"UI_JOURNAL", _journal_text())

func show_codex() -> void:
	_build(&"UI_CODEX", _codex_text())

func _build(title_key: StringName, body: String) -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	focus_mode = Control.FOCUS_ALL
	mouse_filter = Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new()
	shade.color = Color("#08070aee")
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)

	var panel := PanelContainer.new()
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -280.0
	panel.offset_top = -156.0
	panel.offset_right = 280.0
	panel.offset_bottom = 156.0
	panel.add_theme_stylebox_override("panel", UIFactory.panel_style(Color("#15131afb"), Color("#92794f"), 1))
	add_child(panel)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 6)
	panel.add_child(content)
	var title := UIFactory.label(title_key, 21)
	title.add_theme_color_override("font_color", Color("#f2dfb5"))
	content.add_child(title)

	var separator := HSeparator.new()
	separator.modulate = Color("#7b6949")
	content.add_child(separator)

	scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(scroll)
	var body_label := RichTextLabel.new()
	body_label.bbcode_enabled = true
	body_label.fit_content = true
	body_label.scroll_active = false
	body_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body_label.custom_minimum_size = Vector2(510, 220)
	body_label.add_theme_font_size_override("normal_font_size", 13)
	body_label.add_theme_font_size_override("italics_font_size", 13)
	body_label.add_theme_color_override("default_color", UIFactory.TEXT)
	body_label.text = body
	scroll.add_child(body_label)

	var hint := UIFactory.label(&"UI_LIBRARY_KEYBOARD_HINT", 9)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_color_override("font_color", UIFactory.TEXT_MUTED)
	content.add_child(hint)
	call_deferred("grab_focus")

func _journal_text() -> String:
	if GameSession.journal_entries.is_empty():
		return Locale.text(&"UI_EMPTY_JOURNAL")
	var result := ""
	for entry in GameSession.journal_entries:
		result += "[color=#d7ba7d]•[/color] %s\n\n" % Locale.text(entry)
	return result

func _codex_text() -> String:
	if &"codex.apate" not in GameSession.codex_entries:
		return Locale.text(&"UI_EMPTY_CODEX")
	return "[font_size=24][color=#d7ba7d]%s — %s[/color][/font_size]\n[i]%s[/i]\n\n%s\n\n[color=#b8a783]%s[/color]\n\n%s" % [
		Locale.text(&"CODEX_APATE_NAME"),
		Locale.text(&"CODEX_APATE_GREEK"),
		Locale.text(&"CODEX_APATE_GLOSS"),
		Locale.text(&"CODEX_APATE_DESCRIPTION"),
		Locale.text(&"UI_REFS"),
		Locale.text(&"CODEX_APATE_REFLECTION")
	]

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("open_journal") or event.is_action_pressed("open_codex"):
		queue_free()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_down") or event.is_action_pressed("move_down"):
		scroll.scroll_vertical += 24
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_up") or event.is_action_pressed("move_up"):
		scroll.scroll_vertical -= 24
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_PAGEDOWN:
		scroll.scroll_vertical += 120
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_PAGEUP:
		scroll.scroll_vertical -= 120
		get_viewport().set_input_as_handled()
