class_name LibraryPanel
extends Control

func show_journal() -> void:
	_build(&"UI_JOURNAL", _journal_text())

func show_codex() -> void:
	_build(&"UI_CODEX", _codex_text())

func _build(title_key: StringName, body: String) -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shade := ColorRect.new()
	shade.color = Color("#08070add")
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)

	var panel := PanelContainer.new()
	panel.position = Vector2(36, 22)
	panel.size = Vector2(568, 316)
	panel.add_theme_stylebox_override("panel", UIFactory.panel_style())
	add_child(panel)

	var content := VBoxContainer.new()
	panel.add_child(content)
	var title := UIFactory.label(title_key, 24)
	title.add_theme_color_override("font_color", Color("#f2dfb5"))
	content.add_child(title)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(scroll)
	var body_label := RichTextLabel.new()
	body_label.bbcode_enabled = true
	body_label.fit_content = true
	body_label.custom_minimum_size = Vector2(515, 220)
	body_label.text = body
	scroll.add_child(body_label)
	var close := UIFactory.button(&"UI_CLOSE")
	close.pressed.connect(queue_free)
	content.add_child(close)
	close.grab_focus()

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
	if event.is_action_pressed("ui_cancel"):
		queue_free()
		get_viewport().set_input_as_handled()

